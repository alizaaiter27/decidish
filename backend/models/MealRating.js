const mongoose = require('mongoose');

const mealRatingSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    meal: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Meal',
      required: true,
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
  },
  { timestamps: true }
);

mealRatingSchema.index({ user: 1, meal: 1 }, { unique: true });

module.exports = mongoose.model('MealRating', mealRatingSchema);
