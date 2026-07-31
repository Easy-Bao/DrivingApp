import { describe, expect, test } from 'bun:test';
import { calculateCommissionCentavos } from '../src/features/services/commission.ts';

describe('calculateCommissionCentavos', () => {
  test('calculates a rounded ten-percent commission using integers', () => {
    expect(calculateCommissionCentavos(12_345, 1000)).toBe(1_235);
    expect(calculateCommissionCentavos(1, 5000)).toBe(1);
  });

  test('rejects invalid monetary values', () => {
    expect(() => calculateCommissionCentavos(-1, 1000)).toThrow();
    expect(() => calculateCommissionCentavos(2_147_483_648, 1000)).toThrow();
    expect(() => calculateCommissionCentavos(100, 10_001)).toThrow();
  });
});
