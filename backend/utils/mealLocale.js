/**
 * Optional Turkish copy for the same meal document (`localeTr` on Meal).
 * API merges into `name` / `description` / `ingredients` / `ingredientLines`
 * when `?lang=tr` or Accept-Language prefers Turkish.
 */

const SUPPORTED = new Set(['en', 'tr']);

/**
 * @param {import('express').Request} req
 * @returns {'en'|'tr'}
 */
function getMealContentLang(req) {
  const rawQ = req.query && req.query.lang != null ? String(req.query.lang).trim().toLowerCase() : '';
  if (SUPPORTED.has(rawQ)) return /** @type {'en'|'tr'} */ (rawQ);

  const al = req.headers['accept-language'];
  if (typeof al === 'string' && al.length > 0) {
    const first = al.split(',')[0].trim().toLowerCase();
    if (first.startsWith('tr')) return 'tr';
    if (first.startsWith('en')) return 'en';
  }

  return 'en';
}

/**
 * @param {string|undefined|null} search
 * @param {'en'|'tr'} lang
 * @returns {object|null} Mongo `$or` fragment for text search, or null if no search.
 */
function buildMealSearchFilter(search, lang) {
  if (search == null) return null;
  const pattern = String(search).trim();
  if (!pattern) return null;

  const regexField = { $regex: pattern, $options: 'i' };
  const tagRe = new RegExp(pattern, 'i');

  const or = [
    { name: regexField },
    { description: regexField },
    { tags: { $in: [tagRe] } },
  ];

  if (lang === 'tr') {
    or.push({ 'localeTr.name': regexField });
    or.push({ 'localeTr.description': regexField });
  }

  return { $or: or };
}

/**
 * Merge `localeTr` into display fields and omit `localeTr` from the payload.
 * @param {Record<string, any>} mealPlain — plain object (e.g. from `toObject()`)
 * @param {'en'|'tr'} lang
 */
function resolveMealPlain(mealPlain, lang) {
  if (!mealPlain || typeof mealPlain !== 'object') return mealPlain;
  const out = { ...mealPlain };
  const tr = out.localeTr;
  delete out.localeTr;

  if (lang !== 'tr') {
    delete out.displayLocale;
    return out;
  }

  if (!tr || typeof tr !== 'object') {
    out.displayLocale = 'en';
    return out;
  }

  let usedTr = false;
  if (typeof tr.name === 'string' && tr.name.trim()) {
    out.name = tr.name.trim();
    usedTr = true;
  }
  if (typeof tr.description === 'string' && tr.description.trim()) {
    out.description = tr.description.trim();
    usedTr = true;
  }
  if (Array.isArray(tr.ingredients) && tr.ingredients.length > 0) {
    out.ingredients = [...tr.ingredients];
    usedTr = true;
  }
  if (Array.isArray(tr.ingredientLines) && tr.ingredientLines.length > 0) {
    out.ingredientLines = [...tr.ingredientLines];
    usedTr = true;
  }

  out.displayLocale = usedTr ? 'tr' : 'en';
  return out;
}

/**
 * @param {import('mongoose').Document|Record<string, any>|null|undefined} meal
 * @param {'en'|'tr'} lang
 */
function resolveDocOrPlain(meal, lang) {
  if (meal == null) return null;
  const plain = typeof meal.toObject === 'function' ? meal.toObject() : { ...meal };
  return resolveMealPlain(plain, lang);
}

module.exports = {
  getMealContentLang,
  buildMealSearchFilter,
  resolveMealPlain,
  resolveDocOrPlain,
};
