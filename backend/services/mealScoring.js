const Favorite = require('../models/Favorite');
const History = require('../models/History');
const { mealMatchesPreferredCuisines } = require('./preferenceUtils');

const TASTES = ['sweet', 'salty', 'spicy', 'sour', 'bitter', 'umami'];

/**
 * How well the meal's taste profile matches the user's stated preferences (0–1).
 */
function calculateTasteCompatibility(userTaste, mealTaste) {
  if (!userTaste || !mealTaste) return 0.5;
  let totalDifference = 0;
  TASTES.forEach((taste) => {
    const userPref = userTaste[taste] ?? 2;
    const mealValue = mealTaste[taste] ?? 0;
    totalDifference += Math.abs(userPref - mealValue);
  });
  const maxPossibleDifference = 5 * TASTES.length;
  return Math.max(0, (maxPossibleDifference - totalDifference) / maxPossibleDifference);
}

function normalizeToken(s) {
  return String(s || '')
    .toLowerCase()
    .trim();
}

function jaccardIngredients(a, b) {
  const setA = new Set((a || []).map(normalizeToken).filter(Boolean));
  const setB = new Set((b || []).map(normalizeToken).filter(Boolean));
  if (setA.size === 0 && setB.size === 0) return 0;
  let inter = 0;
  for (const x of setA) if (setB.has(x)) inter += 1;
  const union = setA.size + setB.size - inter;
  return union === 0 ? 0 : inter / union;
}

function aggregateFromMeals(meals) {
  const cuisines = new Set();
  const tags = new Set();
  const dietTypes = new Set();
  const allIngredients = [];
  const tasteSums = {};
  TASTES.forEach((t) => {
    tasteSums[t] = 0;
  });
  let tasteCount = 0;

  for (const m of meals) {
    if (!m) continue;
    if (m.cuisine) cuisines.add(m.cuisine);
    (m.tags || []).forEach((t) => tags.add(t));
    (m.dietTypes || []).forEach((d) => dietTypes.add(d));
    (m.ingredients || []).forEach((i) => allIngredients.push(i));
    if (m.tasteProfile) {
      tasteCount += 1;
      TASTES.forEach((t) => {
        tasteSums[t] += m.tasteProfile[t] ?? 0;
      });
    }
  }

  const avgTaste =
    tasteCount > 0
      ? Object.fromEntries(TASTES.map((t) => [t, tasteSums[t] / tasteCount]))
      : null;

  return {
    cuisines,
    tags,
    dietTypes,
    allIngredients,
    avgTasteFromLikes: avgTaste,
  };
}

/**
 * Extra points when this meal is similar to food the user favorited or ate before.
 */
function scoreSimilarity(meal, profile) {
  let points = 0;
  const breakdown = { cuisineMatch: 0, tags: 0, dietOverlap: 0, ingredients: 0, tasteFromLikes: 0 };

  if (!meal) return { points: 0, breakdown };

  if (meal.cuisine && profile.cuisines.has(meal.cuisine)) {
    breakdown.cuisineMatch = 20;
    points += breakdown.cuisineMatch;
  }

  const mealTags = meal.tags || [];
  for (const t of mealTags) {
    if (profile.tags.has(t)) {
      breakdown.tags += 5;
    }
  }
  points += breakdown.tags;

  const md = meal.dietTypes || [];
  for (const d of md) {
    if (profile.dietTypes.has(d)) {
      breakdown.dietOverlap += 6;
    }
  }
  points += breakdown.dietOverlap;

  const jac = jaccardIngredients(meal.ingredients, profile.allIngredients);
  breakdown.ingredients = Math.round(jac * 22);
  points += breakdown.ingredients;

  if (profile.avgTasteFromLikes && meal.tasteProfile) {
    const sim = calculateTasteCompatibility(profile.avgTasteFromLikes, meal.tasteProfile);
    breakdown.tasteFromLikes = Math.round(sim * 18);
    points += breakdown.tasteFromLikes;
  }

  return { points: Math.min(55, points), breakdown };
}

/**
 * Community popularity: more favorites → more points (log-scaled, capped).
 */
function scorePopularity(favoriteCount) {
  const n = Math.max(0, Number(favoriteCount) || 0);
  const raw = 9 * Math.log2(n + 1);
  return Math.min(24, Math.round(raw * 10) / 10);
}

/**
 * Core preference & context scoring (matches filters + taste prefs from profile).
 */
function scorePreferences(meal, user, currentMealType) {
  let points = 0;
  const breakdown = {
    mealType: 0,
    diet: 0,
    calories: 0,
    cuisine: 0,
    tasteProfile: 0,
    prepTime: 0,
    difficulty: 0,
    cookingMethod: 0,
    seasonal: 0,
  };

  const preferredMealTypes = user.preferences?.preferredMealTypes || [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  if (meal.mealType === currentMealType) {
    breakdown.mealType = 26;
  } else if (preferredMealTypes.includes(meal.mealType)) {
    breakdown.mealType = 12;
  }
  points += breakdown.mealType;

  if (user.dietType && user.dietType !== 'None') {
    if ((meal.dietTypes || []).includes(user.dietType)) {
      breakdown.diet = 28;
      points += breakdown.diet;
    }
  }

  const cal = meal.nutrition?.calories;
  const range = user.preferences?.calorieRange;
  if (cal != null && range) {
    const min = range.min ?? 0;
    const max = range.max ?? 2000;
    if (cal >= min && cal <= max) {
      breakdown.calories = 16;
      points += breakdown.calories;
    }
  }

  const preferredCuisines = user.preferences?.preferredCuisines || [];
  const pc = preferredCuisines.map((c) => String(c).trim()).filter(Boolean);
  if (pc.length > 0) {
    if (mealMatchesPreferredCuisines(meal, pc)) {
      breakdown.cuisine = 40;
      points += breakdown.cuisine;
    } else {
      breakdown.cuisineMismatchPenalty = -48;
      points += breakdown.cuisineMismatchPenalty;
    }
  }

  if (user.preferences?.tasteProfile && meal.tasteProfile) {
    const tc = calculateTasteCompatibility(user.preferences.tasteProfile, meal.tasteProfile);
    breakdown.tasteProfile = Math.round(tc * 38);
    points += breakdown.tasteProfile;
  }

  const maxPrep = user.preferences?.maxPreparationTime ?? 60;
  if (meal.preparationTime != null && meal.preparationTime <= maxPrep) {
    breakdown.prepTime = 12;
    points += breakdown.prepTime;
  }

  if (user.preferences?.preferredDifficulty && meal.difficulty === user.preferences.preferredDifficulty) {
    breakdown.difficulty = 10;
    points += breakdown.difficulty;
  }

  if (
    user.preferences?.cookingMethods?.length &&
    (meal.cookingMethod || []).some((m) => user.preferences.cookingMethods.includes(m))
  ) {
    breakdown.cookingMethod = 12;
    points += breakdown.cookingMethod;
  }

  if (
    user.preferences?.seasonalPreference &&
    (meal.seasonality || []).some(
      (s) =>
        s === user.preferences.seasonalPreference || s === 'Year-round'
    )
  ) {
    breakdown.seasonal = 8;
    points += breakdown.seasonal;
  }

  return { points, breakdown };
}

/**
 * Single meal score with full breakdown (for ranking & transparency).
 */
function computeMealScore(meal, user, ctx, currentMealType) {
  const pref = scorePreferences(meal, user, currentMealType);
  const favCount = ctx.favoriteCountMap.get(meal._id.toString()) || 0;
  const pop = scorePopularity(favCount);
  const sim = ctx.likedProfile ? scoreSimilarity(meal, ctx.likedProfile) : { points: 0, breakdown: {} };

  let recentPenalty = 0;
  if (ctx.recentMealIdSet?.has(meal._id.toString())) {
    recentPenalty = 14;
  }

  const tieBreak = Math.random() * 1.8;

  const total =
    pref.points + pop + sim.points - recentPenalty + tieBreak;

  return {
    total: Math.round(total * 100) / 100,
    breakdown: {
      preferences: pref.breakdown,
      preferencePoints: Math.round(pref.points * 10) / 10,
      popularity: pop,
      favoriteCount: favCount,
      similarity: sim.breakdown,
      similarityPoints: Math.round(sim.points * 10) / 10,
      recentPenalty,
      tieBreak: Math.round(tieBreak * 100) / 100,
    },
  };
}

/**
 * Load favorite counts for a set of meals + user's liked/history meals for similarity.
 */
async function loadScoringContext(userId, candidateMealIds) {
  const ids = candidateMealIds.map((id) => id);

  const countAgg =
    ids.length > 0
      ? await Favorite.aggregate([
          { $match: { meal: { $in: ids } } },
          { $group: { _id: '$meal', count: { $sum: 1 } } },
        ])
      : [];

  const favoriteCountMap = new Map(countAgg.map((c) => [c._id.toString(), c.count]));

  const favDocs = await Favorite.find({ user: userId }).populate('meal').sort({ createdAt: -1 }).limit(80);

  const histDocs = await History.find({ user: userId })
    .sort({ date: -1 })
    .limit(40)
    .populate('meal');

  const likedMeals = favDocs.map((f) => f.meal).filter(Boolean);
  const historyMeals = histDocs.map((h) => h.meal).filter(Boolean);

  const forProfile = [...likedMeals, ...historyMeals];
  const likedProfile = forProfile.length ? aggregateFromMeals(forProfile) : null;

  const recentMealIdSet = new Set(
    histDocs
      .slice(0, 20)
      .map((h) => h.meal?._id)
      .filter(Boolean)
      .map((id) => id.toString())
  );

  return {
    favoriteCountMap,
    likedProfile,
    recentMealIdSet,
    likedMeals,
    historyMeals,
  };
}

function getTimeBasedMealType() {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 11) return 'Breakfast';
  if (hour >= 11 && hour < 15) return 'Lunch';
  if (hour >= 15 && hour < 21) return 'Dinner';
  return 'Snack';
}

module.exports = {
  TASTES,
  calculateTasteCompatibility,
  computeMealScore,
  loadScoringContext,
  getTimeBasedMealType,
  scorePopularity,
};
