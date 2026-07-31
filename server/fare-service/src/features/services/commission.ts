/**
 * Calculates a commission using integer centavos and basis points.
 */
export function calculateCommissionCentavos(
  fareCentavos: number,
  rateBasisPoints: number,
): number {
  if (!Number.isInteger(fareCentavos) || fareCentavos < 0) {
    throw new Error('fareCentavos must be a non-negative integer.');
  }
  if (!Number.isInteger(rateBasisPoints) || rateBasisPoints < 0 || rateBasisPoints > 10_000) {
    throw new Error('rateBasisPoints must be between 0 and 10000.');
  }
  return Math.round(fareCentavos * rateBasisPoints / 10_000);
}
