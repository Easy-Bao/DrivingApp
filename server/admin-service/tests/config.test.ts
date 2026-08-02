import { describe, expect, test } from 'bun:test';
import { loadAdminConfiguration } from '../src/config/env.ts';

const validEnvironment = {
  DATABASE_URL: 'postgresql://test:test@database.invalid:5432/test',
  ADMIN_JWT_SECRET: 'a'.repeat(32),
};

describe('Admin service configuration', () => {
  test('accepts only the isolated Admin database and signing secret', () => {
    expect(loadAdminConfiguration(validEnvironment)).toMatchObject({
      PORT: 8090,
      ADMIN_JWT_SECRET: 'a'.repeat(32),
    });
  });

  test('reports invalid names without exposing their values', () => {
    expect(() => loadAdminConfiguration({
      DATABASE_URL: 'not-a-url',
      ADMIN_JWT_SECRET: 'short',
    })).toThrow(
      'Admin Service Configuration Error: invalid or missing DATABASE_URL, ADMIN_JWT_SECRET',
    );
  });
});
