const express = require('express');
const Meal = require('../models/Meal');
const User = require('../models/User');
const History = require('../models/History');
const { protect } = require('../middleware/auth');
const {
  computeMealScore,
  loadScoringContext,
} = require('../services/mealScoring');
const {
  buildCuisineQueryFilter,
  mergeWithCuisineFilter,
  hasPreferredCuisines,
  pickRandomizedTopFromSorted,
} = require('../services/preferenceUtils');

const router = express.Router();

router.use(protect);

// @route   GET /api/recommendations
// @desc    Best meal for this user using compatibility score (prefs + taste + similarity + popularity)
// @access  Private
router.get('/', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const now = new Date();
    const hour = now.getHours();
    let currentMealType = 'Lunch';

    if (hour >= 5 && hour < 11) currentMealType = 'Breakfast';
    else if (hour >= 11 && hour < 15) currentMealType = 'Lunch';
    else if (hour >= 15 && hour < 21) currentMealType = 'Dinner';
    else currentMealType = 'Snack';

    if (req.query.mealType) {
      currentMealType = req.query.mealType;
    }

    const preferredMealTypes = user.preferences?.preferredMealTypes || [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snack',
      'Dessert',
    ];

    const query = {};

    if (user.dietType && user.dietType !== 'None') {
      query.dietTypes = user.dietType;
    }

    if (user.preferences?.calorieRange) {
      query['nutrition.calories'] = {
        $gte: user.preferences.calorieRange.min || 0,
        $lte: user.preferences.calorieRange.max || 2000,
      };
    }

    query.mealType = { $in: [currentMealType, ...preferredMealTypes] };

    if (user.preferences?.maxPreparationTime) {
      query.preparationTime = { $lte: user.preferences.maxPreparationTime };
    }

    if (user.preferences?.preferredDifficulty) {
      query.difficulty = user.preferences.preferredDifficulty;
    }

    if (user.preferences?.cookingMethods?.length > 0) {
      query.cookingMethod = { $in: user.preferences.cookingMethods };
    }

    if (user.preferences?.dislikedIngredients?.length > 0) {
      query.ingredients = {
        $nin: user.preferences.dislikedIngredients.map((ing) => new RegExp(ing, 'i')),
      };
    }

    const recentHistory = await History.find({ user: user._id })
      .sort({ date: -1 })
      .limit(20)
      .select('meal date');

    const recentMealIds = recentHistory.map((h) => h.meal);

    if (recentMealIds.length > 0) {
      query._id = { $nin: recentMealIds };
    }

    const cuisineFilter = buildCuisineQueryFilter(user.preferences?.preferredCuisines);
    const withCuisine = (q) => mergeWithCuisineFilter(q, cuisineFilter);

    let meals = await Meal.find(withCuisine(query));

    if (meals.length === 0) {
      const relaxedQuery1 = { ...query };
      delete relaxedQuery1._id;
      delete relaxedQuery1.mealType;
      meals = await Meal.find(withCuisine(relaxedQuery1));
    }

    if (meals.length === 0) {
      const relaxedQuery2 = { ...query };
      delete relaxedQuery2._id;
      delete relaxedQuery2.cookingMethod;
      meals = await Meal.find(withCuisine(relaxedQuery2));
    }

    if (meals.length === 0) {
      const relaxedQuery3 = { ...query };
      delete relaxedQuery3._id;
      delete relaxedQuery3.difficulty;
      meals = await Meal.find(withCuisine(relaxedQuery3));
    }

    if (meals.length === 0) {
      const relaxedQuery4 = {};
      if (user.dietType && user.dietType !== 'None') {
        relaxedQuery4.dietTypes = user.dietType;
      }
      if (user.preferences?.dislikedIngredients?.length > 0) {
        relaxedQuery4.ingredients = {
          $nin: user.preferences.dislikedIngredients.map((ing) => new RegExp(ing, 'i')),
        };
      }
      if (recentMealIds.length > 0) {
        relaxedQuery4._id = { $nin: recentMealIds };
      }
      meals = await Meal.find(withCuisine(relaxedQuery4));
    }

    if (meals.length === 0) {
      const finalQuery = {};
      if (recentMealIds.length > 0) {
        finalQuery._id = { $nin: recentMealIds };
      }
      meals = await Meal.find(withCuisine(finalQuery));
    }

    if (meals.length === 0) {
      meals = await Meal.find(withCuisine({}));
    }

    const ctx = await loadScoringContext(
      user._id,
      meals.map((m) => m._id)
    );

    const scoredMeals = meals.map((meal) => {
      const { total, breakdown } = computeMealScore(meal, user, ctx, currentMealType);
      return { meal, score: total, breakdown };
    });

    scoredMeals.sort((a, b) => b.score - a.score);

    const hasCuisinePrefs = hasPreferredCuisines(user.preferences?.preferredCuisines);

    const top = hasCuisinePrefs
      ? scoredMeals[0]
      : pickRandomizedTopFromSorted(scoredMeals, 1, 20)[0];

    const recommendedMeal =
      top?.meal ||
      scoredMeals[Math.floor(Math.random() * scoredMeals.length)]?.meal;

    if (!recommendedMeal) {
      return res.status(404).json({
        success: false,
        message: 'No meals available',
      });
    }

    // Only persist when the client explicitly asks (e.g. "Decide for me").
    // Prevents history spam from passive loads / previews.
    const saveHistory =
      req.query.saveHistory === 'true' || req.query.saveHistory === '1';

    if (saveHistory) {
      await History.create({
        user: user._id,
        meal: recommendedMeal._id,
        recommendationScore: top.score,
        mealType: currentMealType,
      });
    }

    res.json({
      success: true,
      meal: recommendedMeal,
      recommendationContext: {
        currentMealType,
        score: top.score,
        scoreBreakdown: top.breakdown,
        savedToHistory: saveHistory,
        totalMealsConsidered: meals.length,
        matchingCriteria: {
          dietType: user.dietType,
          preferences: user.preferences,
          timeOfDay: currentMealType,
        },
      },
    });
  } catch (error) {
    console.error('Get recommendation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
