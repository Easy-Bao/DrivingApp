import { prisma } from './src/db.ts';

async function main() {
  const email = 'driver@test.com';
  const password = 'password123';
  const passwordHash = await Bun.password.hash(password, { algorithm: 'bcrypt', cost: 10 });

  const existing = await prisma.driver.findUnique({
    where: { email },
  });

  if (existing) {
    console.log('Driver driver@test.com already exists in database');
    return;
  }

  const driver = await prisma.driver.create({
    data: {
      name: 'Ramil Sombilon',
      email,
      phone: '09171234567',
      vehicleType: 'Standard Trike',
      plateNumber: '555-ABC',
      passwordHash,
      rating: 4.5,
      isOnline: true,
      lat: 7.828282,
      lng: 123.434343,
    },
  });

  console.log('Created test driver:', driver);
}

main().catch(console.error).finally(() => prisma.$disconnect());
