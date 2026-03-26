const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a name'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Please provide an email'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
  },
  password: {
    type: String,
    required: [true, 'Please provide a password'],
    minlength: 6,
    select: false, // Don't return password by default
  },
  dietType: {
    type: String,
    enum: ['Vegetarian', 'Vegan', 'Omnivore', 'Keto', 'Paleo', 'Gluten-Free', 'None'],
    default: 'None',
  },
  preferences: {
    allergies: [String],
    dislikedIngredients: [String],
    preferredCuisines: [String],
    calorieRange: {
      min: { type: Number, default: 0 },
      max: { type: Number, default: 2000 },
    },
    // Enhanced taste preferences
    tasteProfile: {
      sweet: {
        type: Number,
        min: 0,
        max: 5,
        default: 2,
      },
      salty: {
        type: Number,
        min: 0,
        max: 5,
        default: 2,
      },
      spicy: {
        type: Number,
        min: 0,
        max: 5,
        default: 2,
      },
      sour: {
        type: Number,
        min: 0,
        max: 5,
        default: 1,
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
        default: 2,
      },
    },
    // Meal type preferences
    preferredMealTypes: [{
      type: String,
      enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
    }],
    // Cooking preferences
    cookingMethods: [{
      type: String,
      enum: ['Grilled', 'Baked', 'Fried', 'Boiled', 'Steamed', 'Roasted', 'Raw', 'Stir-fried', 'Slow-cooked'],
    }],
    // Dietary restrictions
    dietaryRestrictions: [{
      type: String,
      enum: ['Low-carb', 'Low-fat', 'High-protein', 'Low-sodium', 'Sugar-free', 'Dairy-free', 'Nut-free'],
    }],
    // Time constraints
    maxPreparationTime: {
      type: Number, // in minutes
      default: 60,
    },
    preferredDifficulty: {
      type: String,
      enum: ['Easy', 'Medium', 'Hard'],
      default: 'Medium',
    },
    // Seasonal preferences
    seasonalPreference: {
      type: String,
      enum: ['Spring', 'Summer', 'Fall', 'Winter', 'Year-round'],
      default: 'Year-round',
    },
    // Approximate max cost per meal (e.g. USD) for feed filtering; optional
    maxMealBudget: {
      type: Number,
      min: 0,
    },
  },
  onboardingCompleted: {
    type: Boolean,
    default: false,
  },
  // Daily streak tracking
  streak: {
    current: {
      type: Number,
      default: 0,
    },
    longest: {
      type: Number,
      default: 0,
    },
    lastCheckIn: {
      type: Date,
      default: null,
    },
    checkInDates: [{
      type: Date,
    }],
  },
  // Social: friends list (mutual)
  friends: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  // Quick survey "Help me decide" — stores recent picks to improve future matches
  surveyInsights: {
    picks: [{
      mood: { type: String, trim: true },
      mealType: { type: String, trim: true },
      budgetTier: { type: String, trim: true },
      portion: { type: String, trim: true },
      timeFeeling: { type: String, trim: true },
      meal: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Meal',
      },
      createdAt: { type: Date, default: Date.now },
    }],
  },
}, {
  timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
