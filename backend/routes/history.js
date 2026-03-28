const express = require('express');
const History = require('../models/History');
const Meal = require('../models/Meal');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(protect);

// @route   GET /api/history
// @desc    Get meal history for current user
// @access  Private
router.get('/', async (req, res) => {
  try {
    const { limit = 50, page = 1 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const histories = await History.find({ user: req.user.id })
      .populate('meal')
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    const total = await History.countDocuments({ user: req.user.id });

    res.json({
      success: true,
      count: histories.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
      history: histories.map(h => ({
        id: h._id,
        meal: h.meal,
        date: h.date,
        rating: h.rating,
        notes: h.notes,
        createdAt: h.createdAt,
      })),
    });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/history
// @desc    Record that the user tried a meal (adds to meal history)
// @access  Private
router.post('/', async (req, res) => {
  try {
    const { mealId } = req.body;

    if (!mealId) {
      return res.status(400).json({
        success: false,
        message: 'mealId is required',
      });
    }

    const meal = await Meal.findById(mealId);
    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    const history = await History.create({
      user: req.user.id,
      meal: meal._id,
      mealType: meal.mealType || undefined,
    });

    await history.populate('meal');

    res.status(201).json({
      success: true,
      history: {
        id: history._id,
        meal: history.meal,
        date: history.date,
        rating: history.rating,
        notes: history.notes,
        createdAt: history.createdAt,
      },
    });
  } catch (error) {
    console.error('Add history error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/history/stats
// @desc    Get meal history statistics
// @access  Private
router.get('/stats', async (req, res) => {
  try {
    const totalMeals = await History.countDocuments({ user: req.user.id });

    // Get meals this week
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    const mealsThisWeek = await History.countDocuments({
      user: req.user.id,
      date: { $gte: oneWeekAgo },
    });

    // Get most common diet types from history
    const histories = await History.find({ user: req.user.id })
      .populate('meal')
      .limit(100);

    const dietTypeCounts = {};
    histories.forEach(h => {
      if (h.meal && h.meal.dietTypes) {
        h.meal.dietTypes.forEach(dt => {
          dietTypeCounts[dt] = (dietTypeCounts[dt] || 0) + 1;
        });
      }
    });

    res.json({
      success: true,
      stats: {
        totalMeals,
        mealsThisWeek,
        dietTypeCounts,
      },
    });
  } catch (error) {
    console.error('Get history stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/history/:id
// @desc    Update history entry (rating, notes)
// @access  Private
router.put('/:id', async (req, res) => {
  try {
    const { rating, notes } = req.body;

    const history = await History.findOne({
      _id: req.params.id,
      user: req.user.id,
    });

    if (!history) {
      return res.status(404).json({
        success: false,
        message: 'History entry not found',
      });
    }

    if (rating !== undefined) {
      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5',
        });
      }
      history.rating = rating;
    }

    if (notes !== undefined) {
      history.notes = notes;
    }

    await history.save();
    await history.populate('meal');

    res.json({
      success: true,
      history: {
        id: history._id,
        meal: history.meal,
        date: history.date,
        rating: history.rating,
        notes: history.notes,
        createdAt: history.createdAt,
      },
    });
  } catch (error) {
    console.error('Update history error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/history
// @desc    Clear all history for current user
// @access  Private
router.delete('/', async (req, res) => {
  try {
    const result = await History.deleteMany({ user: req.user.id });

    res.json({
      success: true,
      message: 'History cleared successfully',
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error('Clear history error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
