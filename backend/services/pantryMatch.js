/**
 * Match user pantry items to meal ingredient strings (flexible substring / token overlap).
 */

function normalizePantryItems(items) {
  const out = [];
  const seen = new Set();
  for (const raw of items || []) {
    const s = String(raw).toLowerCase().trim();
    if (!s || s.length > 120) continue;
    if (seen.has(s)) continue;
    seen.add(s);
    out.push(s);
    if (out.length >= 80) break;
  }
  return out;
}

function ingredientCoveredByPantry(mealIngredient, pantryNormalized) {
  const m = String(mealIngredient || '')
    .toLowerCase()
    .trim();
  if (!m) return false;
  for (const p of pantryNormalized) {
    if (p === m) return true;
    if (m.includes(p) || p.includes(m)) return true;
    const mWords = m.split(/\s+/).filter((w) => w.length >= 2);
    const pWords = p.split(/\s+/).filter((w) => w.length >= 2);
    for (const pw of pWords) {
      for (const mw of mWords) {
        if (mw.includes(pw) || pw.includes(mw)) return true;
      }
    }
  }
  return false;
}

/**
 * @returns {{ matchedCount: number, totalIngredients: number, coverage: number, missingIngredients: string[], matchedIngredients: string[], sortKey: number } | null}
 */
function scoreMealForPantry(meal, pantryNormalized) {
  const list = meal.ingredients || [];
  if (list.length === 0) return null;
  const matchedIngredients = [];
  const missingIngredients = [];
  for (const ing of list) {
    if (ingredientCoveredByPantry(ing, pantryNormalized)) {
      matchedIngredients.push(ing);
    } else {
      missingIngredients.push(ing);
    }
  }
  const matchedCount = matchedIngredients.length;
  const totalIngredients = list.length;
  const coverage = matchedCount / totalIngredients;
  // Prefer higher coverage, then more ingredients matched, then fewer missing items to buy
  const sortKey = coverage * 1000 + matchedCount * 10 - missingIngredients.length * 0.01;
  return {
    matchedCount,
    totalIngredients,
    coverage,
    missingIngredients,
    matchedIngredients,
    sortKey,
  };
}

/**
 * @param {import('mongoose').Document[]} meals
 * @param {string[]} rawPantryItems
 */
function rankMealsByPantry(meals, rawPantryItems) {
  const pantry = normalizePantryItems(rawPantryItems);
  if (pantry.length === 0) {
    return { pantry, results: [] };
  }

  const scored = [];
  for (const meal of meals) {
    const m = meal.toObject ? meal.toObject() : meal;
    const pm = scoreMealForPantry(m, pantry);
    if (!pm || pm.matchedCount === 0) continue;
    scored.push({
      meal: m,
      pantryMatch: {
        matchedCount: pm.matchedCount,
        totalIngredients: pm.totalIngredients,
        coverage: Math.round(pm.coverage * 1000) / 1000,
        missingIngredients: pm.missingIngredients,
        matchedIngredients: pm.matchedIngredients,
      },
      sortKey: pm.sortKey,
    });
  }

  scored.sort((a, b) => b.sortKey - a.sortKey);

  const results = scored.map(({ meal, pantryMatch }) => {
    const mealObj = { ...meal };
    return {
      ...mealObj,
      pantryMatch,
    };
  });

  return { pantry, results };
}

module.exports = {
  normalizePantryItems,
  ingredientCoveredByPantry,
  scoreMealForPantry,
  rankMealsByPantry,
};
