import { db } from './src/shared/drizzle.ts';
import { drivers } from './src/db/schema.ts';
import { eq } from 'drizzle-orm';

async function registerTestDriverAccount() {
  await db.delete(drivers).where(eq(drivers.email, 'driver@test.com'));
  console.log('Cleared existing test driver account from database');

  const email = 'driver@test.com';
  const password = '@Democrito111';
  const passwordHash = await Bun.password.hash(password, { algorithm: 'bcrypt', cost: 10 });

  const [createdDriver] = await db.insert(drivers)
    .values({
      id: crypto.randomUUID(),
      name: 'Ramil Sombilon',
      email,
      phone: '09111111111',
      vehicleType: 'Bao Bao',
      plateNumber: 'XYZ 9999',
      passwordHash,
      rating: 4.5,
      isOnline: true,
      lat: 7.828282,
      lng: 123.434343,
    })
    .returning();

  console.log('Successfully registered test driver account:', createdDriver);
}

registerTestDriverAccount().catch(console.error).finally(() => process.exit(0));
