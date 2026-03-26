/**
 * Removes legacy meals that are not from TheMealDB (no `themealdbId`).
 * Meals created by `npm run import:themealdb` are kept.
 *
 * Does NOT insert sample data anymore — populate with:
 *   npm run import:themealdb
 *
 * Usage: npm run seed
 */

const mongoose = require('mongoose');
const Meal = require('../models/Meal');
require('dotenv').config();

const LEGACY_FILTER = {
  $or: [
    { themealdbId: { $exists: false } },
    { themealdbId: null },
    { themealdbId: '' },
  ],
};

async function main() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
    console.log('Connected to MongoDB');

    const res = await Meal.deleteMany(LEGACY_FILTER);

    console.log(`Removed ${res.deletedCount} legacy meal(s) (no TheMealDB id).`);

    const remaining = await Meal.countDocuments();
    console.log(`Meals remaining (TheMealDB imports): ${remaining}`);
    console.log('To add or refresh recipes: npm run import:themealdb');

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
