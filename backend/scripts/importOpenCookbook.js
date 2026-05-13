/**
 * Import ~100 schema.org Recipe objects from the json-cookbook dataset (no API key).
 * Source: https://github.com/micahcochran/json-cookbook (recipes under CC / PD per project notes).
 * Respect original licenses when displaying or redistributing content.
 *
 * Fetches cookbook-100.json at runtime, maps into Meal, upserts by `openCookbookUrl` (recipe `url`).
 *
 * Env:
 *   OPEN_COOKBOOK_URL  (optional) — default raw GitHub cookbook-100.json
 *   MAX_MEALS            (optional) — cap rows processed
 *   MONGODB_URI          (optional)
 *
 * Usage (from backend/): npm run import:open-cookbook
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
const { estimateSteps } = require('./estimateSteps');
require('./loadEnv');

const DEFAULT_URL =
  'https://raw.githubusercontent.com/micahcochran/json-cookbook/master/cookbook-100.json';

function stripHtml(html) {
  if (!html) return '';
  return String(html)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function isoDurationToMinutes(iso) {
  if (!iso || typeof iso !== 'string') return 30;
  let minutes = 0;
  const h = iso.match(/(\d+)H/);
  const m = iso.match(/(\d+)M/);
  if (h) minutes += parseInt(h[1], 10) * 60;
  if (m) minutes += parseInt(m[1], 10);
  return minutes > 0 ? Math.min(240, minutes) : 30;
}

function inferCookingMethod(instructions) {
  const t = (instructions || '').toLowerCase();
  const methods = [];
  const pairs = [
    ['bake', 'Baked'],
    ['oven', 'Baked'],
    ['grill', 'Grilled'],
    ['fried', 'Fried'],
    ['fry', 'Fried'],
    ['steam', 'Steamed'],
    ['boil', 'Boiled'],
    ['roast', 'Roasted'],
    ['slow', 'Slow-cooked'],
    ['stir', 'Stir-fried'],
    ['raw', 'Raw'],
  ];
  for (const [kw, label] of pairs) {
    if (t.includes(kw) && !methods.includes(label)) methods.push(label);
  }
  return methods.length ? methods : ['Baked'];
}

function mapMealType(category, cuisine) {
  const c = String(category || '').toLowerCase();
  const cu = String(cuisine || '').toLowerCase();
  if (c.includes('dessert') || c.includes('sweet')) return 'Dessert';
  if (c.includes('breakfast') || c.includes('brunch')) return 'Breakfast';
  if (c.includes('snack')) return 'Snack';
  if (c.includes('lunch')) return 'Lunch';
  if (c.includes('drink') || c.includes('beverage') || c.includes('cocktail') || cu.includes('cocktail')) {
    return 'Snack';
  }
  if (c.includes('side') || c.includes('salad') || c.includes('soup') || c.includes('starter')) {
    return 'Lunch';
  }
  return 'Dinner';
}

function inferDietTypes(ingredientLines, category) {
  const cat = String(category || '').toLowerCase();
  const ing = ingredientLines.join(' ').toLowerCase();
  if (cat.includes('vegan')) return ['Vegan'];
  if (cat.includes('vegetarian')) return ['Vegetarian'];
  const meatRe =
    /\b(chicken|beef|pork|lamb|salmon|tuna|fish|meat|shrimp|prawns?|bacon|ham|turkey|duck|seafood|anchovy|steak|mince|ground beef|chorizo|prosciutto|squid|calamari|egg)\b/i;
  if (meatRe.test(ing)) return ['Omnivore'];
  return ['Vegetarian'];
}

function firstNumberFromNutrient(val) {
  if (val == null) return null;
  const m = String(val).match(/([\d.]+)/);
  if (!m) return null;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) ? n : null;
}

function nutritionFromSchema(n, ingredientCount) {
  if (!n || typeof n !== 'object') {
    const k = ingredientCount;
    return {
      calories: Math.round(280 + k * 18),
      protein: Math.round(12 + k * 1.2),
      carbs: Math.round(25 + k * 2),
      fat: Math.round(10 + k * 0.8),
    };
  }
  let calories = firstNumberFromNutrient(n.calories);
  if (calories != null && String(n.calories).toLowerCase().includes('kj')) {
    calories = Math.round(calories / 4.184);
  }
  const protein = firstNumberFromNutrient(n.proteinContent);
  const carbs = firstNumberFromNutrient(n.carbohydrateContent);
  const fat = firstNumberFromNutrient(n.fatContent);
  if (calories != null && protein != null && carbs != null && fat != null) {
    return {
      calories: Math.round(calories),
      protein: Math.round(protein),
      carbs: Math.round(carbs),
      fat: Math.round(fat),
    };
  }
  if (protein != null && carbs != null && fat != null) {
    const cal = Math.round(4 * protein + 4 * carbs + 9 * fat);
    return {
      calories: cal || 300,
      protein: Math.round(protein),
      carbs: Math.round(carbs),
      fat: Math.round(fat),
    };
  }
  const k = ingredientCount;
  return {
    calories: Math.round(280 + k * 18),
    protein: Math.round(12 + k * 1.2),
    carbs: Math.round(25 + k * 2),
    fat: Math.round(10 + k * 0.8),
  };
}

function instructionsText(r) {
  const ri = r.recipeInstructions;
  if (!Array.isArray(ri)) return '';
  const parts = [];
  for (const step of ri) {
    if (step && typeof step === 'object' && step.text) parts.push(stripHtml(String(step.text)));
    else if (typeof step === 'string') parts.push(stripHtml(step));
  }
  return parts.join('\n\n').trim();
}

function recipeToDoc(r) {
  const url = (r.url && String(r.url).trim()) || '';
  if (!url) throw new Error('missing url');

  const ingredientLines = (Array.isArray(r.recipeIngredient) ? r.recipeIngredient : [])
    .map((x) => String(x).trim())
    .filter(Boolean);
  const ingredients = [...new Set(ingredientLines.map((l) => l.toLowerCase()))];
  const n = ingredients.length;

  const instr = instructionsText(r);
  const desc = stripHtml(r.description || r.name || '');
  const description = [desc, instr].filter(Boolean).join('\n\n').slice(0, 8000);

  const img = r.image;
  const imageUrl = Array.isArray(img) && img[0] ? String(img[0]) : typeof img === 'string' ? img : '';

  const totalTime = r.totalTime || r.prepTime;
  const preparationTime = isoDurationToMinutes(totalTime);

  const kw = r.keywords
    ? String(r.keywords)
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean)
    : [];
  const tags = [...new Set([...kw, 'open-cookbook'])];

  const nutrition = nutritionFromSchema(r.nutrition, n);
  const fix = (x) => (x > 0 ? x : 1);
  nutrition.calories = fix(nutrition.calories);
  nutrition.protein = fix(nutrition.protein);
  nutrition.carbs = fix(nutrition.carbs);
  nutrition.fat = fix(nutrition.fat);

  return {
    openCookbookUrl: url,
    name: (r.name || 'Untitled').trim(),
    description: description || r.name,
    imageUrl,
    recipeSourceUrl: url,
    recipeVideoUrl: '',
    nutrition,
    dietTypes: inferDietTypes(ingredientLines, r.recipeCategory),
    cuisine: (r.recipeCuisine && String(r.recipeCuisine).trim()) || 'International',
    ingredients,
    ingredientLines,
    tags,
    preparationTime,
    difficulty: n > 12 ? 'Hard' : n > 7 ? 'Medium' : 'Easy',
    estimatedCost: Math.min(25, Math.round(5 + n * 0.6)),
    mealType: mapMealType(r.recipeCategory, r.recipeCuisine),
    tasteProfile: {
      sweet: 2,
      salty: 2,
      spicy: 1,
      sour: 1,
      bitter: 0,
      umami: 2,
    },
    cookingMethod: inferCookingMethod(instr),
    seasonality: ['Year-round'],
    complexity: {
      ingredientsCount: n,
      stepsCount: estimateSteps(instr),
      specialEquipment: [],
    },
  };
}

async function main() {
  const src = process.env.OPEN_COOKBOOK_URL || DEFAULT_URL;
  const maxMeals = process.env.MAX_MEALS ? parseInt(process.env.MAX_MEALS, 10) : Infinity;

  const res = await fetch(src);
  if (!res.ok) throw new Error(`Fetch cookbook JSON failed: HTTP ${res.status}`);
  const data = await res.json();
  const list = Array.isArray(data) ? data : [];

  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
  console.log('Connected to MongoDB');
  console.log(`Fetched ${list.length} recipes from ${src}`);

  let upserted = 0;
  let failed = 0;

  for (let i = 0; i < list.length && upserted < maxMeals; i += 1) {
    const r = list[i];
    try {
      if (r['@type'] && r['@type'] !== 'Recipe') continue;
      const doc = recipeToDoc(r);
      await Meal.updateOne(
        { openCookbookUrl: doc.openCookbookUrl },
        { $set: doc },
        { upsert: true }
      );
      upserted += 1;
    } catch (e) {
      failed += 1;
      if (failed <= 5) console.warn('  skip:', e.message);
    }
  }

  console.log(`Done. Upserted: ${upserted}, skipped/errors: ${failed}`);
  await mongoose.disconnect();
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
