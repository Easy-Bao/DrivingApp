import { expect, test, describe, spyOn, afterEach } from 'bun:test';
import { fetchPassengerName } from '../src/services/passenger.ts';

describe('Passenger Service Client', () => {
  afterEach(() => {
    global.fetch = typeof global.fetch === 'function' ? global.fetch : fetch;
  });

  test('returns fallback passenger name when external fetch fails via network connection refusal', async () => {
    spyOn(global, 'fetch').mockRejectedValue(new Error('ConnectionRefused'));
    const name = await fetchPassengerName('test-passenger-uuid');
    expect(name).toBe('Passenger');
  });

  test('extracts custom payload fields properly when external remote endpoint answers cleanly', async () => {
    spyOn(global, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ name: 'Alex' }), { status: 200 })
    );
    const name = await fetchPassengerName('test-passenger-uuid');
    expect(name).toBe('Alex');
  });
});
