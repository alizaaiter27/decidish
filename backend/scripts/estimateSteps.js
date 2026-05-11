/**
 * Count instruction "steps" for `Meal.complexity.stepsCount` across importers.
 * Normalizes line endings so CRLF / LF / CR produce the same chunking.
 */
function estimateSteps(text) {
  const chunks = String(text || '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .split(/\n+/)
    .map((s) => s.trim())
    .filter(Boolean);
  const meaningful = chunks.filter((l) => l.length > 8);
  return Math.min(24, Math.max(1, meaningful.length || 1));
}

module.exports = { estimateSteps };
