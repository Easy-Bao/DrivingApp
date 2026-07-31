/**
 * Calculates a commission using integer centavos and basis points, rounding a
 * half-cent up to the next centavo.
 */
export function calculateCommissionCentavos(
  fareCentavos: number,
  rateBasisPoints: number,
): number {
  if (
    !Number.isInteger(fareCentavos)
    || fareCentavos < 0
    || fareCentavos > 2_147_483_647
  ) {
    throw new Error('fareCentavos must be a non-negative PostgreSQL integer.');
  }
  if (!Number.isInteger(rateBasisPoints) || rateBasisPoints < 0 || rateBasisPoints > 10_000) {
    throw new Error('rateBasisPoints must be between 0 and 10000.');
  }
  return Math.round(fareCentavos * rateBasisPoints / 10_000);
}
