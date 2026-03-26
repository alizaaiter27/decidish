const express = require('express');
const { body, validationResult } = require('express-validator');
const Meal = require('../models/Meal');
const User = require('../models/User');
const MealRating = require('../models/MealRating');
const { protect } = require('../middleware/auth');
const {
  computeMealScore,
  loadScoringContext,
  getTimeBasedMealType,
} = require('../services/mealScoring');
const { getSurveySuggestions } = require('../services/surveyMeals');
const { rankMealsByPantry } = require('../services/pantryMatch');
const {
  buildCuisineQueryFilter,
  mergeWithCuisineFilter,
  hasPreferredCuisines,
  randomizeTopPortion,
} = require('../services/preferenceUtils');

const router = express.Router();

const THEMEALDB_AREA_LIST = 'https://www.themealdb.com/api/json/v1/1/list.php?a=list';
let cachedCuisineAreas = null;
let cachedCuisineAreasAt = 0;
const CUISINE_AREAS_CACHE_MS = 60 * 60 * 1000;

// @route   GET /api/meals/cuisine-areas
// @desc    All cuisine/area labels from TheMealDB + distinct values from your DB (for custom imports e.g. Lebanese)
// @access  Public
router.get('/cuisine-areas', async (req, res) => {
  try {
    const now = Date.now();
    let fromApi = cachedCuisineAreas;
    if (!fromApi || now - cachedCuisineAreasAt > CUISINE_AREAS_CACHE_MS) {
      const r = await fetch(THEMEALDB_AREA_LIST, {
        headers: { 'User-Agent': 'Decidish/1.0' },
      });
      if (!r.ok) {
        throw new Error(`TheMealDB HTTP ${r.status}`);
      }
      const data = await r.json();
      fromApi = (data.meals || [])
        .map((m) => m.strArea)
        .filter(Boolean);
      cachedCuisineAreas = fromApi;
      cachedCuisineAreasAt = now;
    }

    const fromDb = await Meal.distinct('cuisine', {
      cuisine: { $nin: [null, ''] },
    });

    const merged = [...new Set([...fromApi, ...fromDb])].sort((a, b) =>
      String(a).localeCompare(String(b), undefined, { sensitivity: 'base' })
    );

    res.json({
      success: true,
      areas: merged,
      fromTheMealDB: fromApi.length,
      fromDatabase: fromDb.length,
    });
  } catch (error) {
    console.error('cuisine-areas error:', error);
    res.status(502).json({
      success: false,
      message: 'Could not load cuisine list. Try again later.',
    });
  }
});

// @route   GET /api/meals/personalized
// @desc    All meals ranked by compatibility score (game-style points) for the logged-in user
// @access  Private
router.get('/personalized', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const currentMealType = req.query.mealType
      ? String(req.query.mealType)
      : getTimeBasedMealType();

    const { dietType, cuisine, search } = req.query;
    const parts = [];

    if (dietType) {
      parts.push({ dietTypes: dietType });
    }

    if (cuisine) {
      parts.push({ cuisine });
    } else {
      const cuisineFilter = buildCuisineQueryFilter(
        user.preferences?.preferredCuisines
      );
      if (cuisineFilter) parts.push(cuisineFilter);
    }

    if (search) {
      parts.push({
        $or: [
          { name: { $regex: search, $options: 'i' } },
          { description: { $regex: search, $options: 'i' } },
          { tags: { $in: [new RegExp(search, 'i')] } },
        ],
      });
    }

    const query =
      parts.length === 0
        ? {}
        : parts.length === 1
          ? parts[0]
          : { $and: parts };

    const meals = await Meal.find(query).sort({ createdAt: -1 });

    if (meals.length === 0) {
      return res.json({
        success: true,
        count: 0,
        meals: [],
        mealType: currentMealType,
      });
    }

    const ctx = await loadScoringContext(
      user._id,
      meals.map((m) => m._id)
    );

    const scored = meals.map((meal) => {
      const { total, breakdown } = computeMealScore(meal, user, ctx, currentMealType);
      const mealObj = meal.toObject();
      return {
        ...mealObj,
        compatibilityScore: total,
        scoreBreakdown: breakdown,
      };
    });

    scored.sort((a, b) => (b.compatibilityScore || 0) - (a.compatibilityScore || 0));

    const restrictByCuisinePrefs =
      hasPreferredCuisines(user.preferences?.preferredCuisines) || Boolean(cuisine);

    const mealsOut = restrictByCuisinePrefs
      ? scored
      : randomizeTopPortion(scored, 50);

    res.json({
      success: true,
      count: mealsOut.length,
      meals: mealsOut,
      mealType: currentMealType,
    });
  } catch (error) {
    console.error('Get personalized meals error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/meals/survey
// @desc    Quick "Help me decide" — 5 answers → up to 5 home-cooked meal suggestions (not restaurants)
// @access  Private
router.post(
  '/survey',
  protect,
  [
    body('mood').isIn(['comfort', 'energetic', 'light', 'treat']),
    body('mealType').isIn(['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']),
    body('budgetTier').isIn(['low', 'medium', 'high']),
    body('portion').isIn(['light', 'regular', 'hearty']),
    body('timeFeeling').isIn(['quick', 'medium', 'flexible']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }
      const meals = await getSurveySuggestions(req.user.id, req.body);
      res.json({
        success: true,
        count: meals.length,
        meals,
      });
    } catch (error) {
      console.error('Survey meals error:', error);
      res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

// @route   POST /api/meals/pantry
// @desc    List meals you can make (or mostly make) from ingredients you have
// @access  Private
router.post(
  '/pantry',
  protect,
  [
    body('ingredients')
      .isArray({ min: 1, max: 80 })
      .withMessage('Provide an array of ingredient names (1–80 items)'),
    body('ingredients.*').isString().trim().notEmpty(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }
      const raw = req.body.ingredients.map((s) => String(s).trim()).filter(Boolean);
      if (raw.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Add at least one ingredient',
        });
      }

      const user = await User.findById(req.user.id);
      const cuisineFilter = buildCuisineQueryFilter(user?.preferences?.preferredCuisines);
      const mealQuery = mergeWithCuisineFilter({}, cuisineFilter);

      const meals = await Meal.find(mealQuery).sort({ createdAt: -1 });
      const { pantry, results } = rankMealsByPantry(meals, raw);

      res.json({
        success: true,
        count: results.length,
        pantryNormalized: pantry,
        meals: results,
      });
    } catch (error) {
      console.error('Pantry meals error:', error);
      res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

// @route   GET /api/meals
// @desc    Get all meals (with optional filters)
// @access  Public (can be made private if needed)
router.get('/', async (req, res) => {
  try {
    const { dietType, cuisine, search } = req.query;
    const query = {};

    if (dietType) {
      query.dietTypes = dietType;
    }

    if (cuisine) {
      query.cuisine = cuisine;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } },
      ];
    }

    const meals = await Meal.find(query).sort({ createdAt: -1 });
    res.json({
      success: true,
      count: meals.length,
      meals,
    });
  } catch (error) {
    console.error('Get meals error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/meals/:id/rate
// @desc    Rate a meal (1–5 stars), upserts per user
// @access  Private
router.post('/:id/rate', protect, async (req, res) => {
  try {
    const { rating } = req.body;
    const r = Number(rating);
    if (!Number.isFinite(r) || r < 1 || r > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5',
      });
    }

    const meal = await Meal.findById(req.params.id);
    if (!meal) {
      return res.status(404).json({ success: false, message: 'Meal not found' });
    }

    await MealRating.findOneAndUpdate(
      { user: req.user.id, meal: meal._id },
      { user: req.user.id, meal: meal._id, rating: r },
      { upsert: true, new: true, runValidators: true }
    );

    res.json({
      success: true,
      mealId: meal._id,
      rating: r,
    });
  } catch (error) {
    console.error('Rate meal error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/meals/:id
// @desc    Get single meal by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const meal = await Meal.findById(req.params.id);
    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }
    res.json({
      success: true,
      meal,
    });
  } catch (error) {
    console.error('Get meal error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
