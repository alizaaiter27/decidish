const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const Meal = require('../models/Meal');
const Favorite = require('../models/Favorite');
const Post = require('../models/Post');
const MealRating = require('../models/MealRating');
const { protect } = require('../middleware/auth');
const {
  computeMealScore,
  loadScoringContext,
  getTimeBasedMealType,
} = require('../services/mealScoring');
const {
  buildCuisineQueryFilter,
  mergeWithCuisineFilter,
  hasPreferredCuisines,
  pickRandomizedTopFromSorted,
} = require('../services/preferenceUtils');

const router = express.Router();

router.use(protect);

function toMealPayload(doc, extra = {}) {
  const o = doc.toObject ? doc.toObject() : { ...doc };
  return { ...o, ...extra };
}

function feedPostJson(p, uid) {
  const likes = p.likes || [];
  const liked = likes.some((id) => id.equals(uid));
  const meal =
    p.meal && p.meal._id
      ? { id: p.meal._id, name: p.meal.name, imageUrl: p.meal.imageUrl || '' }
      : null;
  return {
    id: p._id,
    content: p.content,
    createdAt: p.createdAt,
    likesCount: likes.length,
    likedByMe: liked,
    user: p.user
      ? { id: p.user._id, name: p.user.name, email: p.user.email }
      : null,
    meal,
  };
}

function pickQuickOptions(scoredList, n = 2) {
  if (scoredList.length === 0) return [];
  const pool = scoredList.slice(0, Math.min(8, scoredList.length));
  const shuffled = [...pool].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, n).map((x) => toMealPayload(x.meal, {
    compatibilityScore: x.total,
    scoreBreakdown: x.breakdown,
  }));
}

// @route GET /api/feed
// @desc  Unified feed: personalized meals, trending, similarity, friends & community posts
router.get('/', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentMealType = req.query.mealType || getTimeBasedMealType();
    const maxBudget = user.preferences?.maxMealBudget;

    const cuisineFilter = buildCuisineQueryFilter(user.preferences?.preferredCuisines);

    let mealQuery = {};
    if (maxBudget != null && maxBudget > 0) {
      mealQuery.estimatedCost = { $lte: maxBudget };
    }
    mealQuery = mergeWithCuisineFilter(mealQuery, cuisineFilter);

    const allMeals = await Meal.find(mealQuery);
    const mealIds = allMeals.map((m) => m._id);

    const ctx = await loadScoringContext(user._id, mealIds);

    const scored = allMeals.map((meal) => {
      const { total, breakdown } = computeMealScore(meal, user, ctx, currentMealType);
      const sim = breakdown.similarityPoints ?? 0;
      return { meal, total, breakdown, similarityPoints: sim };
    });

    scored.sort((a, b) => b.total - a.total);

    const hasCuisinePrefs = hasPreferredCuisines(user.preferences?.preferredCuisines);

    const forYouRows = hasCuisinePrefs
      ? scored.slice(0, 10)
      : pickRandomizedTopFromSorted(scored, 10, 40);

    const forYou = forYouRows.map((s) =>
      toMealPayload(s.meal, {
        compatibilityScore: s.total,
        scoreBreakdown: s.breakdown,
      })
    );

    const bySimilarity = [...scored].sort((a, b) => b.similarityPoints - a.similarityPoints);
    const becauseRows = hasCuisinePrefs
      ? bySimilarity.slice(0, 8)
      : pickRandomizedTopFromSorted(bySimilarity, 8, 24);

    const becauseYouLiked = becauseRows.map((s) =>
      toMealPayload(s.meal, {
        compatibilityScore: s.total,
        scoreBreakdown: s.breakdown,
        similarityPoints: s.similarityPoints,
      })
    );

    const trendingAgg = await Favorite.aggregate([
      { $group: { _id: '$meal', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 12 },
    ]);

    const trendingIds = trendingAgg.map((t) => t._id);
    const favCountMap = new Map(trendingAgg.map((t) => [t._id.toString(), t.count]));

    const trendingDocs = trendingIds.length
      ? await Meal.find(
          mergeWithCuisineFilter({ _id: { $in: trendingIds } }, cuisineFilter)
        )
      : [];
    const trendingOrder = new Map(trendingIds.map((id, i) => [id.toString(), i]));
    trendingDocs.sort(
      (a, b) =>
        (trendingOrder.get(a._id.toString()) ?? 0) -
        (trendingOrder.get(b._id.toString()) ?? 0)
    );

    const trendingNearYou = trendingDocs.map((m) =>
      toMealPayload(m, {
        favoriteCount: favCountMap.get(m._id.toString()) || 0,
      })
    );

    const uid = new mongoose.Types.ObjectId(req.user.id);
    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .limit(20)
      .populate('user', 'name email')
      .populate('meal', 'name imageUrl');

    const communityPosts = posts.map((p) => feedPostJson(p, uid));

    const friendIds = (user.friends || []).filter(Boolean);
    let friendsActivity = [];
    if (friendIds.length) {
      const fp = await Post.find({ user: { $in: friendIds } })
        .sort({ createdAt: -1 })
        .limit(12)
        .populate('user', 'name email')
        .populate('meal', 'name imageUrl');

      friendsActivity = fp.map((p) => feedPostJson(p, uid));
    }

    const ratings = await MealRating.find({ user: req.user.id }).select(
      'meal rating review updatedAt'
    );
    const byMeal = new Map();
    for (const r of ratings) {
      const mid = r.meal.toString();
      if (!byMeal.has(mid)) byMeal.set(mid, []);
      byMeal.get(mid).push(r);
    }

    const hasText = (x) => x.review && String(x.review).trim().length > 0;
    const myRatings = {};
    const myReviewTexts = {};

    for (const [mid, list] of byMeal) {
      const starOnly = list.filter((x) => !hasText(x));
      starOnly.sort(
        (a, b) => new Date(b.updatedAt) - new Date(a.updatedAt),
      );
      const withText = list.filter(hasText);
      withText.sort(
        (a, b) => new Date(b.updatedAt) - new Date(a.updatedAt),
      );

      if (starOnly.length) {
        myRatings[mid] = starOnly[0].rating;
      } else if (withText.length) {
        myRatings[mid] = withText[0].rating;
      }

      if (withText.length) {
        myReviewTexts[mid] = String(withText[0].review).trim();
      }
    }

    const quickDecide = pickQuickOptions(scored, 2);

    res.json({
      success: true,
      mealType: currentMealType,
      streakHint: user.streak?.current ?? 0,
      myRatings,
      myReviewTexts,
      sections: [
        {
          id: 'for_you',
          title: 'For You',
          subtitle: 'Based on your tastes, diet, and time of day',
          meals: forYou,
        },
        {
          id: 'trending',
          title: 'Trending Near You',
          subtitle: 'Popular picks across DeciDish',
          meals: trendingNearYou,
        },
        {
          id: 'because_you_liked',
          title: 'Because You Liked',
          subtitle: 'Similar to meals you saved or tried',
          meals: becauseYouLiked,
        },
        {
          id: 'friends',
          title: 'Friends',
          subtitle: friendIds.length ? 'Recent from people you follow' : 'Add friends to see activity',
          posts: friendsActivity,
        },
        {
          id: 'community',
          title: 'Community',
          subtitle: 'Reviews & posts from everyone',
          posts: communityPosts,
        },
      ],
      quickDecide,
    });
  } catch (error) {
    console.error('Feed error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
