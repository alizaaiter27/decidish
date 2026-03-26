const mongoose = require('mongoose');

const mealSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Meal name is required'],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
  },
  /** Original recipe page URL (e.g. TheMealDB strSource) */
  recipeSourceUrl: {
    type: String,
    default: '',
    trim: true,
  },
  /** Optional cooking video URL (e.g. YouTube) */
  recipeVideoUrl: {
    type: String,
    default: '',
    trim: true,
  },
  imageUrl: {
    type: String,
    default: '',
  },
  nutrition: {
    calories: {
      type: Number,
      required: true,
    },
    protein: {
      type: Number,
      required: true,
    },
    carbs: {
      type: Number,
      required: true,
    },
    fat: {
      type: Number,
      required: true,
    },
  },
  dietTypes: [{
    type: String,
    enum: ['Vegetarian', 'Vegan', 'Omnivore', 'Keto', 'Paleo', 'Gluten-Free'],
  }],
  cuisine: {
    type: String,
    trim: true,
  },
  ingredients: [String],
  /** Display lines with amounts, e.g. "1 cup rice" (TheMealDB import) */
  ingredientLines: {
    type: [String],
    default: [],
  },
  tags: [String], // e.g., ['healthy', 'quick', 'comfort-food']
  preparationTime: {
    type: Number, // in minutes
    default: 30,
  },
  difficulty: {
    type: String,
    enum: ['Easy', 'Medium', 'Hard'],
    default: 'Medium',
  },

  estimatedCost: {
    type: Number,
    required: true,
  },
  // Enhanced meal categorization
  mealType: {
    type: String,
    enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
    required: [true, 'Meal type is required'],
  },
  tasteProfile: {
    sweet: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
    salty: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
    spicy: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
    sour: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
    bitter: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
    umami: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
  },
  cookingMethod: [{
    type: String,
    enum: ['Grilled', 'Baked', 'Fried', 'Boiled', 'Steamed', 'Roasted', 'Raw', 'Stir-fried', 'Slow-cooked'],
  }],
  seasonality: [{
    type: String,
    enum: ['Spring', 'Summer', 'Fall', 'Winter', 'Year-round'],
  }],
  complexity: {
    ingredientsCount: {
      type: Number,
      default: 0,
    },
    stepsCount: {
      type: Number,
      default: 0,
    },
    specialEquipment: [String],
  },
  /** Set by `scripts/importTheMealDB.js` for deduplication / upserts */
  themealdbId: {
    type: String,
    trim: true,
    sparse: true,
    unique: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Meal', mealSchema);
