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
    review: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
  },
  { timestamps: true }
);

// Non-unique: users may submit multiple reviews per meal (append). Feed "latest"
// star rating updates the most recent row for that user+meal.
mealRatingSchema.index({ user: 1, meal: 1, updatedAt: -1 });

module.exports = mongoose.model('MealRating', mealRatingSchema);
