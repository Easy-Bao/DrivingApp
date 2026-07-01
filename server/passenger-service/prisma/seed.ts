/// SQL-based seed script: inserts a stable test passenger with known UUID and two completed ride requests.
import { createHash } from 'crypto';

const DB_URL = process.env.DATABASE_URL || 'postgresql://driveapp:securepassword123@localhost:5432/passenger_db';

const SEED_PASSENGER_ID = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
const SEED_EMAIL = 'seed@easyride.com';
const SEED_PASSWORD = 'password123';

async function seed() {
  const { default: postgres } = await import('postgres');
  const sql = postgres(DB_URL);

  const passwordHash = await Bun.password.hash(SEED_PASSWORD, {
    algorithm: 'bcrypt',
    cost: 10,
  });

  await sql`
    INSERT INTO passengers (id, name, email, phone, preferred_ride_type, password_hash, created_at)
    VALUES (
      ${SEED_PASSENGER_ID}::uuid,
      'Seed Passenger',
      ${SEED_EMAIL},
      '09000000001',
      'solo-ride',
      ${passwordHash},
      now()
    )
    ON CONFLICT (email) DO UPDATE
      SET name = EXCLUDED.name,
          phone = EXCLUDED.phone
  `;

  console.log(`Seeded passenger: ${SEED_PASSENGER_ID} (${SEED_EMAIL})`);

  await sql`
    INSERT INTO ride_requests (id, passenger_id, ride_type, pickup_latitude, pickup_longitude, pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name, fare, status, created_at)
    VALUES (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
      ${SEED_PASSENGER_ID}::uuid,
      'solo-ride',
      7.828282, 123.434343,
      'City Hall, Pagadian City',
      7.830000, 123.436000,
      'Robinson Supermarket, Pagadian City',
      52.00, 'completed', now() - interval '2 hours'
    )
    ON CONFLICT (id) DO NOTHING
  `;

  await sql`
    INSERT INTO ride_requests (id, passenger_id, ride_type, pickup_latitude, pickup_longitude, pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name, fare, status, created_at)
    VALUES (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
      ${SEED_PASSENGER_ID}::uuid,
      'solo-ride',
      7.830000, 123.436000,
      'Robinson Supermarket, Pagadian City',
      7.825500, 123.432000,
      'Plaza Luz, Pagadian City',
      38.00, 'completed', now() - interval '1 hour'
    )
    ON CONFLICT (id) DO NOTHING
  `;

  console.log('Seeded 2 completed ride requests.');
  console.log(`\nTest credentials:\n  email: ${SEED_EMAIL}\n  password: ${SEED_PASSWORD}\n  passenger_id: ${SEED_PASSENGER_ID}`);

  await sql.end();
}

seed().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
