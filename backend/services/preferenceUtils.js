/**
 * Shared helpers for user cuisine preferences (matches TheMealDB `strArea` / meal.cuisine).
 */

function escapeRegex(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeCuisine(s) {
  return String(s || '')
    .trim()
    .toLowerCase();
}

/**
 * True if meal.cuisine matches any preferred label (case-insensitive).
 */
function mealMatchesPreferredCuisines(meal, preferredCuisines) {
  const list = (preferredCuisines || []).map(normalizeCuisine).filter(Boolean);
  if (list.length === 0) return true;
  const mc = normalizeCuisine(meal?.cuisine);
  if (!mc) return false;
  return list.some((p) => p === mc);
}

/**
 * Mongo filter: meal.cuisine equals one of the strings (case-insensitive).
 * Returns null if the list is empty (no restriction).
 */
function buildCuisineQueryFilter(preferredCuisines) {
  const list = (preferredCuisines || [])
    .map((c) => String(c).trim())
    .filter(Boolean);
  if (list.length === 0) return null;
  return {
    $or: list.map((c) => ({
      cuisine: new RegExp(`^${escapeRegex(c)}$`, 'i'),
    })),
  };
}

/**
 * Combine an existing query object with an optional cuisine filter using $and when needed.
 */
function mergeWithCuisineFilter(baseQuery, cuisineFilter) {
  if (!cuisineFilter) return baseQuery || {};
  const base = baseQuery && Object.keys(baseQuery).length > 0 ? baseQuery : null;
  if (!base) return cuisineFilter;
  return { $and: [base, cuisineFilter] };
}

/**
 * True when the user has at least one preferred cuisine string.
 */
function hasPreferredCuisines(preferredCuisines) {
  const list = (preferredCuisines || [])
    .map((c) => String(c).trim())
    .filter(Boolean);
  return list.length > 0;
}

/**
 * When user has no cuisine preferences, shuffle the top-scored pool so results
 * surface a mix of cuisines instead of one dominant cuisine at the top.
 */
function pickRandomizedTopFromSorted(sortedRows, count, poolSize = 40) {
  if (!sortedRows || sortedRows.length === 0) return [];
  const maxPool = Math.min(poolSize, sortedRows.length);
  const pool = sortedRows.slice(0, maxPool);
  for (let i = pool.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool.slice(0, Math.min(count, pool.length));
}

/**
 * Randomize order of the first `topPortionSize` rows; keep the rest score-sorted.
 */
function randomizeTopPortion(sortedRows, topPortionSize = 50) {
  if (!sortedRows || sortedRows.length === 0) return [];
  if (sortedRows.length <= topPortionSize) {
    return pickRandomizedTopFromSorted(
      sortedRows,
      sortedRows.length,
      sortedRows.length
    );
  }
  const head = pickRandomizedTopFromSorted(
    sortedRows.slice(0, topPortionSize),
    topPortionSize,
    topPortionSize
  );
  return [...head, ...sortedRows.slice(topPortionSize)];
}

module.exports = {
  escapeRegex,
  normalizeCuisine,
  mealMatchesPreferredCuisines,
  buildCuisineQueryFilter,
  mergeWithCuisineFilter,
  hasPreferredCuisines,
  pickRandomizedTopFromSorted,
  randomizeTopPortion,
};
