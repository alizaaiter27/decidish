const Meal = require('../models/Meal');
const User = require('../models/User');
const {
  computeMealScore,
  loadScoringContext,
} = require('./mealScoring');
const {
  buildCuisineQueryFilter,
  mergeWithCuisineFilter,
  hasPreferredCuisines,
  pickRandomizedTopFromSorted,
} = require('./preferenceUtils');

const MAX_SUGGESTIONS = 5;
const MAX_PICKS_STORED = 40;

/**
 * Build Mongo query from survey answers (home cooking, not restaurants).
 */
function buildSurveyQuery(answers) {
  const q = {};

  if (answers.mealType) {
    q.mealType = answers.mealType;
  }

  const budgetMap = {
    low: 10,
    medium: 18,
    high: 35,
  };
  if (answers.budgetTier && budgetMap[answers.budgetTier]) {
    q.estimatedCost = { $lte: budgetMap[answers.budgetTier] };
  }

  const prepMap = {
    quick: 25,
    medium: 45,
    flexible: 120,
  };
  if (answers.timeFeeling && prepMap[answers.timeFeeling]) {
    q.preparationTime = { $lte: prepMap[answers.timeFeeling] };
  }

  const calMap = {
    light: { $lte: 520 },
    regular: { $lte: 850 },
    hearty: { $lte: 1200 },
  };
  if (answers.portion && calMap[answers.portion]) {
    q['nutrition.calories'] = calMap[answers.portion];
  }

  return q;
}

function moodBonus(meal, mood) {
  const tags = (meal.tags || []).map((t) => String(t).toLowerCase());
  const cal = meal.nutrition?.calories ?? 500;
  let b = 0;

  switch (mood) {
    case 'comfort':
      if (tags.some((t) => t.includes('comfort'))) b += 18;
      if (cal > 420) b += 6;
      break;
    case 'energetic':
      if (tags.some((t) => t.includes('protein') || t.includes('fresh'))) b += 14;
      if ((meal.nutrition?.protein ?? 0) > 25) b += 10;
      break;
    case 'light':
      if (cal < 450) b += 18;
      if (tags.some((t) => t.includes('light') || t.includes('salad'))) b += 10;
      break;
    case 'treat':
      if (tags.some((t) => t.includes('comfort') || t.includes('satisfying'))) b += 12;
      if (meal.mealType === 'Dessert' || tags.some((t) => t.includes('sweet'))) b += 8;
      break;
    default:
      break;
  }
  return b;
}

/**
 * Boost meals aligned with past survey picks for the same mood (simple learning).
 */
function learningBoost(meal, mood, picks) {
  if (!picks || !picks.length || !mood) return 0;
  const relevant = picks.filter((p) => p.mood === mood && p.meal);
  let b = 0;
  for (const p of relevant.slice(-8)) {
    const m = p.meal;
    if (m.cuisine && meal.cuisine === m.cuisine) b += 12;
    const mt = m.tags || [];
    const tt = meal.tags || [];
    for (const t of mt) {
      if (tt.includes(t)) b += 3;
    }
  }
  return Math.min(35, b);
}

/**
 * Relax budget/prep/calorie constraints only — never drop `mealType`, so breakfast
 * stays breakfast, dessert stays dessert, etc.
 */
async function relaxQueryStep(q, step) {
  const next = { ...q };
  if (step === 0) delete next.preparationTime;
  else if (step === 1) delete next.estimatedCost;
  else if (step === 2) delete next['nutrition.calories'];
  return next;
}

/**
 * Returns scored meal documents (plain objects + compatibilityScore + surveyBoost).
 */
async function getSurveySuggestions(userId, answers) {
  const user = await User.findById(userId).populate({
    path: 'surveyInsights.picks.meal',
    select: 'cuisine tags name',
  });

  if (!user) {
    throw new Error('User not found');
  }

  let query = buildSurveyQuery(answers);
  const cuisineFilter = buildCuisineQueryFilter(user.preferences?.preferredCuisines);
  const findWithPrefs = (q) => mergeWithCuisineFilter(q, cuisineFilter);

  let meals = await Meal.find(findWithPrefs(query));

  let relax = 0;
  while (meals.length < 5 && relax < 3) {
    query = await relaxQueryStep(query, relax);
    meals = await Meal.find(findWithPrefs(query));
    relax += 1;
  }

  if (meals.length === 0 && answers.mealType) {
    meals = await Meal.find(
      findWithPrefs({ mealType: answers.mealType })
    ).limit(40);
  }

  if (meals.length === 0) {
    meals = await Meal.find(findWithPrefs({})).limit(30);
  }

  if (answers.mealType) {
    meals = meals.filter((m) => m.mealType === answers.mealType);
  }

  const ctx = await loadScoringContext(
    user._id,
    meals.map((m) => m._id)
  );

  const picks = user.surveyInsights?.picks || [];

  const scored = meals.map((meal) => {
    const { total, breakdown } = computeMealScore(
      meal,
      user,
      ctx,
      answers.mealType || 'Lunch'
    );
    const mBonus = moodBonus(meal, answers.mood);
    const lBonus = learningBoost(meal, answers.mood, picks);
    const surveyBoost = mBonus + lBonus;
    const combined = total + surveyBoost;
    const mealObj = meal.toObject();
    return {
      ...mealObj,
      compatibilityScore: Math.round(combined * 100) / 100,
      scoreBreakdown: {
        ...breakdown,
        surveyMoodBonus: mBonus,
        surveyLearningBonus: lBonus,
        surveyBoost,
      },
    };
  });

  scored.sort((a, b) => (b.compatibilityScore || 0) - (a.compatibilityScore || 0));

  const hasCuisinePrefs = hasPreferredCuisines(user.preferences?.preferredCuisines);

  if (hasCuisinePrefs) {
    return scored.slice(0, MAX_SUGGESTIONS);
  }

  return pickRandomizedTopFromSorted(scored, MAX_SUGGESTIONS, 25);
}

async function recordSurveyPick(userId, payload) {
  const { mood, mealType, budgetTier, portion, timeFeeling, mealId } = payload;

  const user = await User.findById(userId);
  if (!user) return null;

  if (!user.surveyInsights) {
    user.surveyInsights = { picks: [] };
  }
  if (!user.surveyInsights.picks) {
    user.surveyInsights.picks = [];
  }

  user.surveyInsights.picks.push({
    mood,
    mealType,
    budgetTier,
    portion,
    timeFeeling,
    meal: mealId,
    createdAt: new Date(),
  });

  while (user.surveyInsights.picks.length > MAX_PICKS_STORED) {
    user.surveyInsights.picks.shift();
  }

  await user.save();
  return user;
}

module.exports = {
  getSurveySuggestions,
  recordSurveyPick,
  buildSurveyQuery,
};
