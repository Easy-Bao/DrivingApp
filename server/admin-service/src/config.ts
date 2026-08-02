import { z } from 'zod';

const AdminConfigurationSchema = z.object({
  DATABASE_URL: z.string().trim().url(),
  ADMIN_JWT_SECRET: z.string().trim().min(32),
  PORT: z.coerce.number().int().min(1).max(65_535).default(8090),
});

export type AdminConfiguration = z.infer<typeof AdminConfigurationSchema>;

/**
 * Validates the isolated Admin service boundary before the server starts. The
 * service owns its database and signing secret, so no Passenger, Driver, or
 * shared authentication configuration is accepted here.
 */
export function loadAdminConfiguration(
  environment: Record<string, string | undefined> = process.env,
): AdminConfiguration {
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
