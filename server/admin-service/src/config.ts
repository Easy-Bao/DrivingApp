import { z } from 'zod';

const AdminConfigurationSchema = z.object({
  DATABASE_URL: z.string().trim().url(),
  JWT_SECRET: z.string().trim().min(1),
  INTERNAL_SERVICE_TOKEN: z.string().trim().min(1),
  DRIVER_SERVICE_URL: z.string().trim().url(),
  PASSENGER_SERVICE_URL: z.string().trim().url(),
  TRIP_SERVICE_URL: z.string().trim().url(),
  BIDDING_SERVICE_URL: z.string().trim().url(),
  FARE_SERVICE_URL: z.string().trim().url(),
  PORT: z.coerce.number().int().min(1).max(65_535).default(8089),
});

/**
 * Validates every value required to start the Admin API without exposing values
 * in the resulting configuration error.
 */
export function loadAdminConfiguration(
  environment: Record<string, string | undefined> = process.env,
) {
  const result = AdminConfigurationSchema.safeParse(environment);
  if (!result.success) {
    const names = [...new Set(
      result.error.issues.map((issue) => issue.path.join('.') || 'environment'),
    )];
    throw new Error(
      `Admin Service Configuration Error: invalid or missing ${names.join(', ')}`,
    );
  }

  return result.data;
}
