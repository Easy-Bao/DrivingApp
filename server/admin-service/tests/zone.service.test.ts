import { describe, expect, test } from 'bun:test';
import { isPointInZone } from '../src/features/services/zone.service.ts';

const square = {
  type: 'Polygon' as const,
  coordinates: [[
    [123, 7],
    [124, 7],
    [124, 8],
    [123, 8],
    [123, 7],
  ]] as [number, number][][],
};

describe('isPointInZone', () => {
  test('accepts inside and boundary points and rejects outside points', () => {
    expect(isPointInZone([123.5, 7.5], square)).toBe(true);
    expect(isPointInZone([123, 7.5], square)).toBe(true);
    expect(isPointInZone([124.5, 7.5], square)).toBe(false);
  });
});
