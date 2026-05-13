/**
 * Print how many meals exist in MongoDB by import source (TheMealDB / Spoonacular / open cookbook).
 * Use this to confirm imports hit the same database your API uses (MONGODB_URI).
 *
 * Usage (from backend/): npm run meals:counts
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
require('./loadEnv');

function hasId(field) {
  return { [field]: { $exists: true, $nin: [null, ''] } };
}

async function main() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish';
  await mongoose.connect(uri);
  const [total, themealdb, spoonacular, openCookbook] = await Promise.all([
    Meal.countDocuments(),
    Meal.countDocuments(hasId('themealdbId')),
    Meal.countDocuments(hasId('spoonacularId')),
    Meal.countDocuments(hasId('openCookbookUrl')),
  ]);
  console.log('MongoDB:', uri.replace(/\/\/([^:]+):[^@]+@/, '//***:***@'));
  console.log({
    total,
    themealdb,
    spoonacular,
    openCookbook,
    otherOrLegacy: total - themealdb - spoonacular - openCookbook,
  });
  console.log('\nIf spoonacular is 0, run (same MONGODB_URI as the API):');
  console.log('  npm run import:spoonacular   # needs SPOONACULAR_API_KEY');
  console.log('  npm run import:open-cookbook # no key — adds open-cookbook recipes');
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
