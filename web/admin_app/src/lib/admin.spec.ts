import { describe, expect, it } from 'vitest';
import { isAdminSection, recordsFrom, unwrapData } from './admin';

describe('admin data helpers', () => {
  it('unwraps gateway data and recognizes the isolated Admin sections', () => {
    expect(unwrapData({ data: { ok: true } })).toEqual({ ok: true });
    expect(recordsFrom({ data: { items: [{ id: 'case-1' }] } })).toEqual([
      { id: 'case-1' },
    ]);
    expect(isAdminSection('cases')).toBe(true);
    expect(isAdminSection('dispatch')).toBe(false);
    expect(isAdminSection('unknown')).toBe(false);
  });
});
