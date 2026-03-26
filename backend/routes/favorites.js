const express = require('express');
const Favorite = require('../models/Favorite');
const Meal = require('../models/Meal');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(protect);

// @route   GET /api/favorites
// @desc    Get all favorites for current user
// @access  Private
router.get('/', async (req, res) => {
  try {
    const favorites = await Favorite.find({ user: req.user.id })
      .populate('meal')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: favorites.length,
      favorites: favorites.map(fav => ({
        id: fav._id,
        meal: fav.meal,
        createdAt: fav.createdAt,
      })),
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/favorites
// @desc    Add meal to favorites
// @access  Private
router.post('/', async (req, res) => {
  try {
    const { mealId } = req.body;

    if (!mealId) {
      return res.status(400).json({
        success: false,
        message: 'Meal ID is required',
      });
    }

    // Check if meal exists
    const meal = await Meal.findById(mealId);
    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({
      user: req.user.id,
      meal: mealId,
    });

    if (existingFavorite) {
      return res.status(400).json({
        success: false,
        message: 'Meal already in favorites',
      });
    }

    const favorite = await Favorite.create({
      user: req.user.id,
      meal: mealId,
    });

    await favorite.populate('meal');

    res.status(201).json({
      success: true,
      favorite: {
        id: favorite._id,
        meal: favorite.meal,
        createdAt: favorite.createdAt,
      },
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Meal already in favorites',
      });
    }
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/favorites/:id
// @desc    Remove meal from favorites
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const favorite = await Favorite.findOne({
      _id: req.params.id,
      user: req.user.id,
    });

    if (!favorite) {
      return res.status(404).json({
        success: false,
        message: 'Favorite not found',
      });
    }

    await Favorite.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Favorite removed successfully',
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   DELETE /api/favorites/meal/:mealId
// @desc    Remove meal from favorites by meal ID
// @access  Private
router.delete('/meal/:mealId', async (req, res) => {
  try {
    const favorite = await Favorite.findOne({
      meal: req.params.mealId,
      user: req.user.id,
    });

    if (!favorite) {
      return res.status(404).json({
        success: false,
        message: 'Favorite not found',
      });
    }

    await Favorite.findByIdAndDelete(favorite._id);

    res.json({
      success: true,
      message: 'Favorite removed successfully',
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

module.exports = router;
