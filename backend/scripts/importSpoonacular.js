/**
 * Import meals from Spoonacular (https://spoonacular.com/food-api) into MongoDB.
 *
 * Uses GET /recipes/random in batches (different recipes each call). Requires an API key.
 * See https://spoonacular.com/food-api/pricing for quotas; `includeNutrition` costs extra points.
 *
 * Env:
 *   SPOONACULAR_API_KEY   (required) — from Spoonacular dashboard
 *   SPOONACULAR_BATCHES   (default 5) — how many random API calls to make
 *   SPOONACULAR_NUMBER    (default 50) — recipes per call (1–100)
 *   MAX_MEALS             (optional) — stop after this many upserts total
 *   SPOONACULAR_INCLUDE_NUTRITION — set to "true" for API nutrition (higher point cost)
 *   MONGODB_URI           (optional, default local decidish)
 *
 * Usage (from backend/):
 *   npm run import:spoonacular
 *   MAX_MEALS=100 SPOONACULAR_BATCHES=2 npm run import:spoonacular
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
const { estimateSteps } = require('./estimateSteps');
require('./loadEnv');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) {
    const t = await res.text().catch(() => '');
    throw new Error(`HTTP ${res.status} ${url} ${t.slice(0, 200)}`);
  }
  return res.json();
}

function stripHtml(html) {
  if (!html) return '';
  return String(html)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function collectIngredientLines(extendedIngredients) {
  if (!Array.isArray(extendedIngredients)) return { names: [], lines: [] };
  const names = [];
  const lines = [];
  for (const ing of extendedIngredients) {
    const orig = ing.original != null ? String(ing.original).trim() : '';
    const nm = ing.name != null ? String(ing.name).trim().toLowerCase() : '';
    if (nm) names.push(nm);
    if (orig) lines.push(orig);
    else if (nm) lines.push(nm);
  }
  return { names: [...new Set(names)], lines };
}

function instructionsText(r) {
  const plain = r.instructions != null ? stripHtml(String(r.instructions)).trim() : '';
  if (plain) return plain;
  const ai = r.analyzedInstructions;
  if (!Array.isArray(ai)) return '';
  const parts = [];
  for (const blk of ai) {
    for (const st of blk.steps || []) {
      if (st.step) parts.push(stripHtml(String(st.step)));
    }
  }
  return parts.join('\n\n').trim();
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

function mapMealType(dishTypes) {
  const types = Array.isArray(dishTypes)
    ? dishTypes.map((d) => String(d).toLowerCase())
    : [];
  if (types.some((d) => d.includes('dessert'))) return 'Dessert';
  if (types.some((d) => d.includes('breakfast') || d.includes('brunch'))) return 'Breakfast';
  if (types.some((d) => d.includes('snack'))) return 'Snack';
  if (types.some((d) => d.includes('lunch') || d.includes('salad') || d.includes('soup'))) {
    return 'Lunch';
  }
  if (types.some((d) => d.includes('dinner') || d.includes('main'))) return 'Dinner';
  return 'Dinner';
}

function mapDietTypes(r) {
  const out = [];
  const diets = (Array.isArray(r.diets) ? r.diets : []).map((d) => String(d).toLowerCase());
  const has = (s) => diets.some((d) => d.includes(s)) || false;

  if (r.vegan === true || has('vegan')) out.push('Vegan');
  else if (r.vegetarian === true || has('vegetarian')) out.push('Vegetarian');

  if (has('ketogenic') || r.ketogenic === true) out.push('Keto');
  if (has('paleo') || r.paleo === true) out.push('Paleo');
  if (has('gluten free') || r.glutenFree === true) out.push('Gluten-Free');

  if (out.length === 0) return ['Omnivore'];
  return [...new Set(out)];
}

function pickNutrient(nutrients, name) {
  if (!Array.isArray(nutrients)) return null;
  const n = nutrients.find((x) => x && String(x.name).toLowerCase() === name.toLowerCase());
  if (!n || n.amount == null) return null;
  const v = Number(n.amount);
  return Number.isFinite(v) ? v : null;
}

function heuristicNutrition(n) {
  return {
    calories: Math.round(280 + n * 18),
    protein: Math.round(12 + n * 1.2),
    carbs: Math.round(25 + n * 2),
    fat: Math.round(10 + n * 0.8),
  };
}

function nutritionFromSpoonacular(r, ingredientCount) {
  const nutrients = r.nutrition && Array.isArray(r.nutrition.nutrients) ? r.nutrition.nutrients : null;
  if (nutrients) {
    const cal = pickNutrient(nutrients, 'Calories');
    const protein = pickNutrient(nutrients, 'Protein');
    const carbs = pickNutrient(nutrients, 'Carbohydrates');
    const fat = pickNutrient(nutrients, 'Fat');
    if (cal != null && protein != null && carbs != null && fat != null) {
      return {
        calories: Math.round(cal),
        protein: Math.round(protein),
        carbs: Math.round(carbs),
        fat: Math.round(fat),
      };
    }
  }
  return heuristicNutrition(ingredientCount);
}

function spoonacularToDoc(r) {
  const { names: ingredients, lines: ingredientLines } = collectIngredientLines(r.extendedIngredients);
  const n = ingredients.length;
  const instr = instructionsText(r);
  const summary = stripHtml(r.summary || '');
  const description = [summary, instr].filter(Boolean).join('\n\n').slice(0, 8000) || r.title;

  const cuisines = Array.isArray(r.cuisines) ? r.cuisines.filter(Boolean) : [];
  const cuisine = (cuisines[0] && String(cuisines[0]).trim()) || 'International';

  const priceCents = typeof r.pricePerServing === 'number' ? r.pricePerServing : null;
  const estimatedCost =
    priceCents != null ? Math.min(25, Math.max(1, Math.round(priceCents / 100))) : Math.min(25, Math.round(5 + n * 0.6));

  const tags = Array.isArray(r.dishTypes)
    ? [...new Set([...r.dishTypes.map(String), 'spoonacular'])]
    : ['spoonacular'];

  return {
    spoonacularId: String(r.id),
    name: (r.title || 'Untitled').trim(),
    description,
    imageUrl: r.image ? String(r.image) : '',
    recipeSourceUrl: (r.sourceUrl && String(r.sourceUrl).trim()) || (r.spoonacularSourceUrl && String(r.spoonacularSourceUrl).trim()) || '',
    recipeVideoUrl: '',
    nutrition: nutritionFromSpoonacular(r, n),
    dietTypes: mapDietTypes(r),
    cuisine,
    ingredients,
    ingredientLines,
    tags,
    preparationTime: typeof r.readyInMinutes === 'number' && r.readyInMinutes > 0 ? Math.min(240, r.readyInMinutes) : Math.min(120, 15 + n * 3),
    difficulty: n > 12 ? 'Hard' : n > 7 ? 'Medium' : 'Easy',
    estimatedCost,
    mealType: mapMealType(r.dishTypes),
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

async function importSpoonacular() {
  const apiKey = (process.env.SPOONACULAR_API_KEY || '').trim();
  if (!apiKey) {
    console.error(
      'SPOONACULAR_API_KEY is missing or empty.\n' +
        '1. Open backend/.env\n' +
        '2. Set SPOONACULAR_API_KEY=your_key (no quotes; paste from https://spoonacular.com/food-api )\n' +
        '3. Run this command again from the backend folder.'
    );
    process.exit(1);
  }

  const batches = Math.max(1, parseInt(process.env.SPOONACULAR_BATCHES || '5', 10));
  const perBatch = Math.min(100, Math.max(1, parseInt(process.env.SPOONACULAR_NUMBER || '50', 10)));
  const maxMeals = process.env.MAX_MEALS ? parseInt(process.env.MAX_MEALS, 10) : Infinity;
  const includeNutrition = process.env.SPOONACULAR_INCLUDE_NUTRITION === 'true';
  const msBetween = Math.max(200, parseInt(process.env.SPOONACULAR_MS_BETWEEN || '1200', 10));

  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
  console.log('Connected to MongoDB');

  let upserted = 0;
  let skipped = 0;
  let failed = 0;

  for (let b = 0; b < batches; b += 1) {
    if (upserted >= maxMeals) break;

    const url = new URL('https://api.spoonacular.com/recipes/random');
    url.searchParams.set('apiKey', apiKey);
    url.searchParams.set('number', String(perBatch));
    if (includeNutrition) url.searchParams.set('includeNutrition', 'true');

    let data;
    try {
      data = await fetchJson(url.toString());
    } catch (e) {
      console.error(`Batch ${b + 1}/${batches} failed:`, e.message);
      failed += 1;
      await sleep(msBetween);
      continue;
    }

    const recipes = data.recipes || [];
    for (const row of recipes) {
      if (upserted >= maxMeals) break;
      try {
        if (row.id == null || !row.title) {
          skipped += 1;
          continue;
        }
        const doc = spoonacularToDoc(row);
        await Meal.updateOne(
          { spoonacularId: doc.spoonacularId },
          { $set: doc },
          { upsert: true }
        );
        upserted += 1;
      } catch (e) {
        console.error(`  skip ${row.id}:`, e.message);
        failed += 1;
      }
    }

    console.log(`  batch ${b + 1}/${batches}: +${recipes.length} recipes processed (total upserts ${upserted})`);
    await sleep(msBetween);
  }

  console.log(`Done. Upserted: ${upserted}, skipped: ${skipped}, batch errors: ${failed}`);
  await mongoose.disconnect();
  process.exit(0);
}

importSpoonacular().catch((err) => {
  console.error(err);
  process.exit(1);
});
