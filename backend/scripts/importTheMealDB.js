/**
 * Import meals from TheMealDB (https://www.themealdb.com/api.php) into MongoDB.
 *
 * The public API only exposes a few hundred recipes (on the order of ~595–600 total).
 * A full import will converge near that count—there are not thousands of meals here.
 *
 * The API is free for educational use; see https://www.themealdb.com/
 *
 * Usage (from backend/):
 *   node scripts/importTheMealDB.js
 *   MAX_MEALS=200 node scripts/importTheMealDB.js   # cap for testing
 *
 * Requires MONGODB_URI (or defaults to mongodb://localhost:27017/decidish).
 * Re-runs upsert by themealdbId (updates existing, inserts new).
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
require('dotenv').config();

const BASE = 'https://www.themealdb.com/api/json/v1/1';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
  return res.json();
}

function collectIngredients(m) {
  const out = [];
  for (let i = 1; i <= 20; i += 1) {
    const v = m[`strIngredient${i}`];
    if (v == null) continue;
    const s = String(v).trim();
    if (s) out.push(s.toLowerCase());
  }
  return [...new Set(out)];
}

/** Human-readable lines with measures for the app UI */
function collectIngredientLines(m) {
  const lines = [];
  for (let i = 1; i <= 20; i += 1) {
    const ing = m[`strIngredient${i}`];
    if (ing == null || !String(ing).trim()) continue;
    const ingT = String(ing).trim();
    const measRaw = m[`strMeasure${i}`];
    const mT = measRaw != null && String(measRaw).trim() ? String(measRaw).trim() : '';
    lines.push(mT ? `${mT} ${ingT}` : ingT);
  }
  return lines;
}

function mapMealType(strCategory) {
  const cat = (strCategory || '').toLowerCase();
  if (cat.includes('dessert')) return 'Dessert';
  if (cat.includes('breakfast')) return 'Breakfast';
  if (/(^| )side|starter|appetizer|soup|salad|miscellaneous/.test(cat)) {
    return 'Lunch';
  }
  if (cat.includes('snack')) return 'Snack';
  return 'Dinner';
}

function inferDietTypes(ingredients, strCategory) {
  const cat = (strCategory || '').toLowerCase();
  const ing = ingredients.join(' ');
  if (cat.includes('vegan')) return ['Vegan'];
  if (cat.includes('vegetarian')) return ['Vegetarian'];
  const meatRe =
    /\b(chicken|beef|pork|lamb|salmon|tuna|fish|meat|shrimp|prawns?|bacon|ham|turkey|duck|seafood|anchovy|steak|mince|ground beef|chorizo|prosciutto|squid|calamari|beef|lamb|egg)\b/i;
  if (meatRe.test(ing)) return ['Omnivore'];
  return ['Vegetarian'];
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

function estimateSteps(strInstructions) {
  const raw = strInstructions || '';
  const chunks = raw.split(/\r\n+/).map((s) => s.trim()).filter(Boolean);
  const meaningful = chunks.filter((l) => l.length > 8);
  return Math.min(24, Math.max(1, meaningful.length || 1));
}

function themealToDoc(m) {
  const ingredients = collectIngredients(m);
  const instructions = m.strInstructions || '';
  const desc = instructions.trim();

  const mealType = mapMealType(m.strCategory);
  const dietTypes = inferDietTypes(ingredients, m.strCategory);
  const tags = m.strTags
    ? m.strTags.split(',').map((t) => t.trim()).filter(Boolean)
    : [];

  const n = ingredients.length;
  const calories = Math.round(280 + n * 18);
  const protein = Math.round(12 + n * 1.2);
  const carbs = Math.round(25 + n * 2);
  const fat = Math.round(10 + n * 0.8);

  const source = (m.strSource && String(m.strSource).trim()) || '';
  const video = (m.strYoutube && String(m.strYoutube).trim()) || '';

  return {
    themealdbId: String(m.idMeal),
    name: (m.strMeal || 'Untitled').trim(),
    description: desc || m.strMeal,
    imageUrl: m.strMealThumb || '',
    recipeSourceUrl: source,
    recipeVideoUrl: video,
    nutrition: {
      calories,
      protein,
      carbs,
      fat,
    },
    dietTypes,
    cuisine: (m.strArea || 'International').trim(),
    ingredients,
    ingredientLines: collectIngredientLines(m),
    tags: tags.length ? tags : ['imported'],
    preparationTime: Math.min(120, 15 + n * 3),
    difficulty: n > 12 ? 'Hard' : n > 7 ? 'Medium' : 'Easy',
    estimatedCost: Math.min(25, Math.round(5 + n * 0.6)),
    mealType,
    tasteProfile: {
      sweet: 2,
      salty: 2,
      spicy: 1,
      sour: 1,
      bitter: 0,
      umami: 2,
    },
    cookingMethod: inferCookingMethod(instructions),
    seasonality: ['Year-round'],
    complexity: {
      ingredientsCount: n,
      stepsCount: estimateSteps(instructions),
      specialEquipment: [],
    },
  };
}

async function collectAllMealSummaries() {
  const letters = 'abcdefghijklmnopqrstuvwxyz'.split('');
  const byId = new Map();

  for (const letter of letters) {
    const data = await fetchJson(`${BASE}/search.php?f=${letter}`);
    await sleep(80);
    if (!data.meals || !Array.isArray(data.meals)) continue;
    for (const row of data.meals) {
      if (row.idMeal) byId.set(row.idMeal, row);
    }
  }

  return [...byId.values()];
}

async function importTheMealDB() {
  const maxMeals = process.env.MAX_MEALS
    ? parseInt(process.env.MAX_MEALS, 10)
    : Infinity;

  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
  console.log('Connected to MongoDB');

  console.log('Fetching meal list from TheMealDB (a–z)…');
  const summaries = await collectAllMealSummaries();
  let list = summaries;
  if (Number.isFinite(maxMeals)) {
    list = summaries.slice(0, maxMeals);
  }
  console.log(`Found ${summaries.length} unique meals; processing ${list.length}`);

  let upserted = 0;
  let failed = 0;

  // `search.php?f=` responses already include strIngredient1–20 and instructions (no per-meal lookup).
  for (let i = 0; i < list.length; i += 1) {
    const row = list[i];
    try {
      if (!row.idMeal || !row.strMeal) {
        failed += 1;
        continue;
      }
      const doc = themealToDoc(row);
      await Meal.updateOne(
        { themealdbId: doc.themealdbId },
        { $set: doc },
        { upsert: true }
      );
      upserted += 1;
      if ((i + 1) % 100 === 0) {
        console.log(`  … ${i + 1}/${list.length}`);
      }
    } catch (e) {
      console.error(`  skip ${row.idMeal}:`, e.message);
      failed += 1;
    }
  }

  console.log(`Done. Upserted: ${upserted}, skipped/errors: ${failed}`);
  await mongoose.disconnect();
  process.exit(0);
}

importTheMealDB().catch((err) => {
  console.error(err);
  process.exit(1);
});
