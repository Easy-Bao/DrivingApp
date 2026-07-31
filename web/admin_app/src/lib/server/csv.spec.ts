import { describe, expect, it } from 'vitest';
import { parseCsv } from './csv';

describe('parseCsv', () => {
  it('preserves commas and quotes in printable report values', () => {
    expect(parseCsv('\uFEFF"id","reason"\r\n"1","Driver said ""hello, owner"""\r\n')).toEqual([
      { id: '1', reason: 'Driver said "hello, owner"' },
    ]);
  });
});
