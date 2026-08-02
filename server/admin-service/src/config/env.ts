import { z } from 'zod';

const AdminConfigurationSchema = z.object({
  DATABASE_URL: z.string().trim().url(),
  ADMIN_JWT_SECRET: z.string().trim().min(32),
  PORT: z.coerce.number().int().min(1).max(65_535).default(8090),
});

export type AdminConfiguration = z.infer<typeof AdminConfigurationSchema>;

/**
 * Admin configuration boundary: accepts only the database URL, dedicated JWT
 * secret, and listening port required by this service so unrelated Passenger or
 * Driver credentials cannot become accidental Admin dependencies.
 *
 * Each caller supplies an environment-shaped record, Zod parses the complete
 * contract, and startup fails before opening a database or issuing a token when
 * any required value is missing or malformed. Failure messages contain only
 * variable names; secret and credential values are never copied into logs.
 *
 * The returned object contains `DATABASE_URL`, `ADMIN_JWT_SECRET`, and `PORT` in
 * their validated runtime forms. Tests may pass an isolated record directly,
 * while production callers use the process environment.
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
