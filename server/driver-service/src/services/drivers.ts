import { prisma } from '../db.ts';

const TRIP_SERVICE_URL = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

export async function signupDriver(data: any) {
  const { name, email, phone, vehicleType, plateNumber, password } = data;
  if (!name || !email || !phone || !vehicleType || !plateNumber || !password) {
    throw new Error('All fields are required');
  }
  const existing = await prisma.driver.findUnique({
    where: { email },
  });
  if (existing) {
    throw new Error('A driver with this email already exists');
  }
  const passwordHash = await Bun.password.hash(password, { algorithm: 'bcrypt', cost: 10 });
  const newDriver = await prisma.driver.create({
    data: {
      name,
      email,
      phone,
      vehicleType,
      plateNumber,
      passwordHash,
    },
  });
  const { passwordHash: _, ...safe } = newDriver;
  return safe;
}

export async function loginDriver(credentials: any) {
  const { email, password } = credentials;
  if (!email || !password) {
    throw new Error('Email and password are required');
  }
  const found = await prisma.driver.findUnique({
    where: { email },
  });
  if (!found) {
    throw new Error('Invalid email or password');
  }
  const valid = await Bun.password.verify(password, found.passwordHash);
  if (!valid) {
    throw new Error('Invalid email or password');
  }
  const { passwordHash: _, ...safe } = found;
  return safe;
}

export async function getOnlineDrivers() {
  const list = await prisma.driver.findMany({
    where: { isOnline: true },
  });
  return list.map(({ passwordHash: _, ...safe }) => safe);
}

export async function updateDriverOnlineStatus(id: string, onlineData: any) {
  const { isOnline, lat, lng } = onlineData;
  const updateData: any = { isOnline };
  if (lat != null) updateData.lat = lat;
  if (lng != null) updateData.lng = lng;
  const updated = await prisma.driver.update({
    where: { id },
    data: updateData,
  });
  const { passwordHash: _, ...safe } = updated;
  return safe;
}

export async function getDriverById(id: string) {
  const found = await prisma.driver.findUnique({
    where: { id },
  });
  if (!found) {
    throw new Error('Driver not found');
  }
  const { passwordHash: _, ...safe } = found;
  return safe;
}

export async function getDriverStats(id: string) {
  const found = await prisma.driver.findUnique({
    where: { id },
  });
  if (!found) {
    throw new Error('Driver not found');
  }
  let rides: any[] = [];
  try {
    const res = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${id}`);
    if (res.ok) {
      rides = await res.json() as any[];
    }
  } catch (err) {
    console.error('Failed to fetch rides from trip-service:', err);
  }

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const todayRides = rides.filter((r: any) => {
    const createdAt = new Date(r.created_at);
    return createdAt >= startOfToday && r.status === 'completed';
  });

  const todayEarnings = todayRides.reduce((sum: number, r: any) => sum + (r.fare ?? 0), 0);
  const todayTrips = todayRides.length;
  const baseHours = todayTrips * 0.75;
  const hoursOnline = parseFloat((found.isOnline ? baseHours + 0.5 : baseHours).toFixed(1));

  const completedRides = rides.filter((r: any) => r.status === 'completed');
  const cancelledRides = rides.filter((r: any) => r.status === 'cancelled');

  const totalTrips = completedRides.length;
  const lifetimeEarnings = completedRides.reduce((sum: number, r: any) => sum + (r.fare ?? 0), 0);

  const totalAssigned = completedRides.length + cancelledRides.length;
  const acceptanceRate = totalAssigned > 0
    ? Math.round((completedRides.length / totalAssigned) * 100)
    : 98;

  return {
    todayEarnings,
    todayTrips,
    hoursOnline,
    lifetimeEarnings,
    totalTrips,
    acceptanceRate,
  };
}

export async function getDriverTrips(id: string) {
  const res = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${id}`);
  if (!res.ok) {
    throw new Error('Trip service failed with status ' + res.status);
  }
  return await res.json();
}

export async function getActiveRides() {
  const res = await fetch(`${TRIP_SERVICE_URL}/rides/active`);
  if (!res.ok) {
    throw new Error('Trip service unavailable with status ' + res.status);
  }
  return await res.json();
}
