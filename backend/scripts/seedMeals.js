/**
 * Removes legacy meals that are not tied to a known import source
 * (no `themealdbId`, `spoonacularId`, `recipeApiId`, or `openCookbookUrl`).
 * (`recipeApiId` is legacy — importer removed; kept here so old rows are not treated as legacy junk.)
 *
 * Does NOT insert sample data anymore — populate with:
 *   npm run import:themealdb
 *   npm run import:spoonacular
 *   npm run import:open-cookbook
 *
 * Usage: npm run seed
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
require('./loadEnv');

function missingExternalId(field) {
  return {
    $or: [
      { [field]: { $exists: false } },
      { [field]: null },
      { [field]: '' },
    ],
  };
}

const LEGACY_FILTER = {
  $and: [
    missingExternalId('themealdbId'),
    missingExternalId('spoonacularId'),
    missingExternalId('recipeApiId'),
    missingExternalId('openCookbookUrl'),
  ],
};

async function main() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
    console.log('Connected to MongoDB');

    const res = await Meal.deleteMany(LEGACY_FILTER);

    console.log(`Removed ${res.deletedCount} legacy meal(s) (no import source id).`);

    const remaining = await Meal.countDocuments();
    console.log(`Meals remaining (imports): ${remaining}`);
    console.log(
      'Imports: npm run import:themealdb | import:spoonacular | import:open-cookbook'
    );

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
