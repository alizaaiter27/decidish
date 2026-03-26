const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { recordSurveyPick } = require('../services/surveyMeals');

const router = express.Router();

/** Shallow-merge incoming preferences so partial updates do not wipe taste/calorie fields. */
function mergePreferencesDoc(existing, incoming) {
  if (!incoming) return existing;
  const base =
    existing && typeof existing.toObject === 'function'
      ? existing.toObject()
      : { ...(existing || {}) };
  const merged = { ...base, ...incoming };
  if (incoming.tasteProfile && base.tasteProfile) {
    merged.tasteProfile = { ...base.tasteProfile, ...incoming.tasteProfile };
  }
  if (incoming.calorieRange && base.calorieRange) {
    merged.calorieRange = { ...base.calorieRange, ...incoming.calorieRange };
  }
  return merged;
}

// All routes require authentication
router.use(protect);

// @route   GET /api/users/search
// @desc    Search users by name or email (returns id, name, email)
// @access  Private
router.get('/search', async (req, res) => {
  try {
    const q = (req.query.q || '').toString().trim();
    if (!q) {
      return res.status(400).json({ success: false, message: 'Query param q is required' });
    }

    // Simple text search on name or email
    const regex = new RegExp(q, 'i');
    const users = await User.find({
      $and: [
        { _id: { $ne: req.user.id } },
        { $or: [ { name: regex }, { email: regex } ] },
      ],
    }).limit(20).select('name email');

    res.json({ success: true, users });
  } catch (error) {
    console.error('User search error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// @route   GET /api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    res.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        dietType: user.dietType,
        preferences: user.preferences,
        onboardingCompleted: user.onboardingCompleted,
        streak: user.streak || {
          current: 0,
          longest: 0,
          lastCheckIn: null,
          checkInDates: []
        },
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put(
  '/profile',
  [
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('dietType').optional().isIn(['Vegetarian', 'Vegan', 'Omnivore', 'Keto', 'Paleo', 'Gluten-Free', 'None']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array(),
        });
      }

      const { name, dietType, preferences } = req.body;

      const updateData = {};
      if (name) updateData.name = name;
      if (dietType) updateData.dietType = dietType;
      if (preferences) {
        const current = await User.findById(req.user.id).select('preferences');
        updateData.preferences = mergePreferencesDoc(current.preferences, preferences);
      }

      const user = await User.findByIdAndUpdate(
        req.user.id,
        updateData,
        { new: true, runValidators: true }
      );

      res.json({
        success: true,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          dietType: user.dietType,
          preferences: user.preferences,
          onboardingCompleted: user.onboardingCompleted,
        },
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error',
      });
    }
  }
);

// @route   POST /api/users/onboarding
// @desc    Complete user onboarding
// @access  Private
router.post(
  '/onboarding',
  [
    body('dietType').optional().isIn(['Vegetarian', 'Vegan', 'Omnivore', 'Keto', 'Paleo', 'Gluten-Free', 'None']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array(),
        });
      }

      const { dietType, preferences } = req.body;

      const updateData = {
        onboardingCompleted: true,
      };
      if (dietType) updateData.dietType = dietType;
      if (preferences) {
        const current = await User.findById(req.user.id).select('preferences');
        updateData.preferences = mergePreferencesDoc(current.preferences, preferences);
      }

      const user = await User.findByIdAndUpdate(
        req.user.id,
        updateData,
        { new: true, runValidators: true }
      );

      res.json({
        success: true,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          dietType: user.dietType,
          preferences: user.preferences,
          onboardingCompleted: user.onboardingCompleted,
        },
      });
    } catch (error) {
      console.error('Onboarding error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error',
      });
    }
  }
);

// @route   POST /api/users/checkin
// @desc    Daily check-in to maintain streak
// @access  Private
router.post('/checkin', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    // Initialize streak if it doesn't exist
    if (!user.streak) {
      user.streak = {
        current: 0,
        longest: 0,
        lastCheckIn: null,
        checkInDates: []
      };
    }

    // Check if already checked in today
    if (user.streak.lastCheckIn) {
      const lastCheckInDate = new Date(user.streak.lastCheckIn.getFullYear(), user.streak.lastCheckIn.getMonth(), user.streak.lastCheckIn.getDate());
      
      if (lastCheckInDate.getTime() === today.getTime()) {
        return res.json({
          success: true,
          message: 'Already checked in today',
          streak: user.streak,
        });
      }
    }

    // Calculate streak logic
    let newStreak = user.streak.current;
    
    if (user.streak.lastCheckIn) {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      const lastCheckInDate = new Date(user.streak.lastCheckIn.getFullYear(), user.streak.lastCheckIn.getMonth(), user.streak.lastCheckIn.getDate());
      
      if (lastCheckInDate.getTime() === yesterday.getTime()) {
        // Consecutive day
        newStreak += 1;
      } else {
        // Streak broken, start new
        newStreak = 1;
      }
    } else {
      // First check-in
      newStreak = 1;
    }

    // Update streak data
    user.streak.current = newStreak;
    user.streak.longest = Math.max(user.streak.longest, newStreak);
    user.streak.lastCheckIn = now;
    user.streak.checkInDates.push(now);

    // Keep only last 365 days of check-ins
    const cutoffDate = new Date(now);
    cutoffDate.setDate(cutoffDate.getDate() - 365);
    user.streak.checkInDates = user.streak.checkInDates.filter(date => date > cutoffDate);

    await user.save();

    res.json({
      success: true,
      message: 'Check-in successful!',
      streak: user.streak,
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   GET /api/users/streak
// @desc    Get user streak information
// @access  Private
router.get('/streak', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const streak = user.streak || {
      current: 0,
      longest: 0,
      lastCheckIn: null,
      checkInDates: []
    };

    res.json({
      success: true,
      streak,
    });
  } catch (error) {
    console.error('Get streak error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
});

// @route   POST /api/users/survey-pick
// @desc    Record which meal the user chose after a survey (improves future survey suggestions)
// @access  Private
router.post(
  '/survey-pick',
  protect,
  [
    body('mealId').notEmpty().withMessage('mealId is required'),
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
      await recordSurveyPick(req.user.id, {
        mood: req.body.mood,
        mealType: req.body.mealType,
        budgetTier: req.body.budgetTier,
        portion: req.body.portion,
        timeFeeling: req.body.timeFeeling,
        mealId: req.body.mealId,
      });
      res.json({ success: true });
    } catch (error) {
      console.error('Survey pick error:', error);
      res.status(500).json({ success: false, message: 'Server error' });
    }
  }
);

module.exports = router;
