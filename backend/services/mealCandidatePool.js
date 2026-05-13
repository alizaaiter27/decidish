const Meal = require('../models/Meal');

/** Max meals to load + score at once (keeps Favorite $match $in small and CPU bounded). */
const DEFAULT_MAX_CANDIDATES = 320;

/**
 * Loads meals matching [query] for scoring. If the match set is larger than
 * [maxCandidates], returns a uniform random sample instead of the whole catalog.
 */
async function findMealsForScoring(query, maxCandidates = DEFAULT_MAX_CANDIDATES) {
  const count = await Meal.countDocuments(query);
  if (count === 0) return [];
  if (count <= maxCandidates) {
    return Meal.find(query).sort({ createdAt: -1 }).exec();
  }
  const plain = await Meal.aggregate([
    { $match: query },
    { $sample: { size: maxCandidates } },
  ]);
  return plain.map((doc) => Meal.hydrate(doc));
}

/** In-memory shuffle + take first [maxN] (for routes that already used Meal.find). */
function subsampleArray(arr, maxN) {
  if (!arr || arr.length <= maxN) return arr;
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, maxN);
}

module.exports = {
  findMealsForScoring,
  subsampleArray,
  DEFAULT_MAX_CANDIDATES,
};
