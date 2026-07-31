import { describe, expect, it } from 'vitest';
import { formatCentavos, isAdminSection, recordsFrom, unwrapData } from './admin';

describe('admin data helpers', () => {
  it('unwraps gateway data without weakening amount handling', () => {
    expect(unwrapData({ data: { ok: true } })).toEqual({ ok: true });
    expect(recordsFrom({ data: { drivers: [{ id: 'driver-1' }] } }, 'drivers')).toEqual([
      { id: 'driver-1' },
    ]);
    expect(formatCentavos(1000)).toBe('₱10.00');
    expect(isAdminSection('dispatch')).toBe(true);
    expect(isAdminSection('unknown')).toBe(false);
  });
});
