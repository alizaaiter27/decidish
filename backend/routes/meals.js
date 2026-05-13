const express = require('express');
const mongoose = require('mongoose');
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
  pickRandomizedTopFromSorted,
} = require('../services/preferenceUtils');
const { findMealsForScoring } = require('../services/mealCandidatePool');
const {
  getMealContentLang,
  buildMealSearchFilter,
  resolveMealPlain,
  resolveDocOrPlain,
} = require('../utils/mealLocale');

const router = express.Router();

// @route   GET /api/meals/cuisine-areas
// @desc    Distinct cuisine labels that appear on at least one meal in this database
// @access  Public
router.get('/cuisine-areas', async (req, res) => {
  try {
    const raw = await Meal.distinct('cuisine', {
      cuisine: { $nin: [null, ''] },
    });
    const areas = [...new Set(raw.map((a) => String(a).trim()).filter(Boolean))].sort(
      (a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' })
    );

    res.json({
      success: true,
      areas,
      count: areas.length,
    });
  } catch (error) {
    console.error('cuisine-areas error:', error);
    res.status(500).json({
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

    const lang = getMealContentLang(req);
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

    const searchFilter = buildMealSearchFilter(search, lang);
    if (searchFilter) {
      parts.push(searchFilter);
    }

    const query =
      parts.length === 0
        ? {}
        : parts.length === 1
          ? parts[0]
          : { $and: parts };

    const meals = await findMealsForScoring(query, 320);

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
      const src = meal.toObject ? meal.toObject() : meal;
      const mealObj = resolveMealPlain(src, lang);
      return {
        ...mealObj,
        compatibilityScore: total,
        scoreBreakdown: breakdown,
      };
    });

    scored.sort((a, b) => (b.compatibilityScore || 0) - (a.compatibilityScore || 0));

    const restrictByCuisinePrefs =
      hasPreferredCuisines(user.preferences?.preferredCuisines) || Boolean(cuisine);

    /** Home only shows ~10; cap payload so we never ship the whole scored catalog. */
    const RESPONSE_LIMIT = 60;
    const mealsOut = restrictByCuisinePrefs
      ? scored.slice(0, RESPONSE_LIMIT)
      : pickRandomizedTopFromSorted(
          scored,
          Math.min(RESPONSE_LIMIT, scored.length),
          Math.min(45, scored.length),
        );

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
      const lang = getMealContentLang(req);
      const meals = await getSurveySuggestions(req.user.id, req.body, lang);
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

      const lang = getMealContentLang(req);
      const meals = await Meal.find(mealQuery).sort({ createdAt: -1 });
      const { pantry, results } = rankMealsByPantry(meals, raw, lang);

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
    const lang = getMealContentLang(req);
    const { dietType, cuisine, search } = req.query;
    const query = {};

    if (dietType) {
      query.dietTypes = dietType;
    }

    if (cuisine) {
      query.cuisine = cuisine;
    }

    const searchFilter = buildMealSearchFilter(search, lang);
    if (searchFilter) {
      Object.assign(query, searchFilter);
    }

    const meals = await Meal.find(query).sort({ createdAt: -1 });
    const mealsOut = meals.map((m) => resolveMealPlain(m.toObject(), lang));
    res.json({
      success: true,
      count: mealsOut.length,
      meals: mealsOut,
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
// @desc    Rate a meal (1–5). Non-append feed taps only update a star-only row
//         (empty review) so written reviews are never overwritten. append=true
//         creates a new row (written review flow).
// @access  Private
router.post('/:id/rate', protect, async (req, res) => {
  try {
    const { rating } = req.body;
    const append = req.body.append === true || req.body.append === 'true';
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

    const uid = req.user.id;
    const mid = meal._id;

    const trimReview = (raw) => {
      if (raw == null || raw === '') return '';
      return String(raw).trim().slice(0, 2000);
    };

    if (append) {
      const reviewText = Object.prototype.hasOwnProperty.call(req.body, 'review')
        ? trimReview(req.body.review)
        : '';
      const saved = await MealRating.create({
        user: uid,
        meal: mid,
        rating: r,
        review: reviewText,
      });
      return res.json({
        success: true,
        mealId: meal._id,
        rating: r,
        review: saved.review || '',
        append: true,
        id: saved._id,
      });
    }

    // Feed star taps: only update a "star-only" row (empty review). Never update
    // rows that contain written text, so changing stars does not affect reviews.
    const emptyReviewQuery = {
      user: uid,
      meal: mid,
      $or: [{ review: '' }, { review: { $exists: false } }],
    };

    let starOnlyDoc = await MealRating.findOne(emptyReviewQuery).sort({
      updatedAt: -1,
    });

    if (starOnlyDoc) {
      starOnlyDoc.rating = r;
      if (Object.prototype.hasOwnProperty.call(req.body, 'review')) {
        starOnlyDoc.review = trimReview(req.body.review);
      }
      await starOnlyDoc.save();
      return res.json({
        success: true,
        mealId: meal._id,
        rating: r,
        review: starOnlyDoc.review || '',
        append: false,
        id: starOnlyDoc._id,
      });
    }

    const created = await MealRating.create({
      user: uid,
      meal: mid,
      rating: r,
      review: Object.prototype.hasOwnProperty.call(req.body, 'review')
        ? trimReview(req.body.review)
        : '',
    });
    res.json({
      success: true,
      mealId: meal._id,
      rating: r,
      review: created.review || '',
      append: false,
      id: created._id,
    });
  } catch (error) {
    console.error('Rate meal error:', error);
    const dupKey =
      error.code === 11000 ||
      (typeof error.message === 'string' && error.message.includes('E11000'));
    if (dupKey) {
      return res.status(409).json({
        success: false,
        message:
          'Duplicate rating constraint. Restart the API server once so the database can drop the old unique index.',
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/meals/:id/rate
// @desc    Remove the current user's star-only row (feed quick rating), not written reviews
// @access  Private
router.delete('/:id/rate', protect, async (req, res) => {
  try {
    const mealId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(mealId)) {
      return res.status(400).json({ success: false, message: 'Invalid meal id' });
    }

    const meal = await Meal.findById(mealId);
    if (!meal) {
      return res.status(404).json({ success: false, message: 'Meal not found' });
    }

    const doc = await MealRating.findOne({
      user: req.user.id,
      meal: meal._id,
      $or: [{ review: '' }, { review: { $exists: false } }],
    }).sort({ updatedAt: -1 });

    if (!doc) {
      return res.status(404).json({
        success: false,
        message: 'No star rating to remove',
      });
    }

    await MealRating.deleteOne({ _id: doc._id });
    res.json({ success: true });
  } catch (error) {
    console.error('Remove meal rating error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   DELETE /api/meals/:id/ratings/:ratingId
// @desc    Delete one rating row owned by the current user
// @access  Private — register before GET /:id
router.delete('/:id/ratings/:ratingId', protect, async (req, res) => {
  try {
    const { id: mealId, ratingId } = req.params;
    if (
      !mongoose.Types.ObjectId.isValid(mealId) ||
      !mongoose.Types.ObjectId.isValid(ratingId)
    ) {
      return res.status(400).json({ success: false, message: 'Invalid id' });
    }

    const meal = await Meal.findById(mealId);
    if (!meal) {
      return res.status(404).json({ success: false, message: 'Meal not found' });
    }

    const deleted = await MealRating.findOneAndDelete({
      _id: ratingId,
      meal: mealId,
      user: req.user.id,
    });

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: 'Review not found or not allowed',
      });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete meal rating error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/meals/:id/reviews
// @desc    Written reviews (non-empty text) by default; ?includeStarOnly=true for all rows
// @access  Public — must be registered before GET /:id
router.get('/:id/reviews', async (req, res) => {
  try {
    const meal = await Meal.findById(req.params.id);
    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    const rows = await MealRating.find({ meal: req.params.id })
      .populate('user', 'name email')
      .sort({ updatedAt: -1 })
      .limit(80)
      .lean();

    const includeStarOnly = req.query.includeStarOnly === 'true';

    let reviews = rows.map((r) => ({
      id: r._id,
      rating: r.rating,
      review: r.review && String(r.review).trim() ? String(r.review).trim() : '',
      updatedAt: r.updatedAt,
      user: r.user
        ? {
            id: r.user._id,
            name: r.user.name,
            email: r.user.email,
          }
        : null,
    }));

    if (!includeStarOnly) {
      reviews = reviews.filter(
        (x) => x.review && String(x.review).trim().length > 0,
      );
    }

    res.json({ success: true, reviews });
  } catch (error) {
    console.error('List meal reviews error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/meals/:id
// @desc    Get single meal by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const lang = getMealContentLang(req);
    const meal = await Meal.findById(req.params.id);
    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }
    res.json({
      success: true,
      meal: resolveDocOrPlain(meal, lang),
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
