/**
 * One-time: drop the old unique index on (user, meal) so multiple MealRating
 * documents per user+meal are allowed. Safe to run if the index does not exist.
 *
 * Usage: node backend/scripts/dropMealRatingUniqueIndex.js
 * Requires MONGODB_URI (or edit default below).
 */
const mongoose = require('mongoose');

async function main() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/decidish';
  await mongoose.connect(uri);
  const coll = mongoose.connection.db.collection('mealratings');
  try {
    await coll.dropIndex('user_1_meal_1');
    console.log('Dropped index user_1_meal_1');
  } catch (e) {
    console.log('dropIndex:', e.message);
  }
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
