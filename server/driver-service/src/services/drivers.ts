import { prisma } from '../db.ts';

const TRIP_SERVICE_URL = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

export async function registerDriver(driverDetails: any) {
  const { name, email, phone, vehicleType, plateNumber, password } = driverDetails;
  if (!name || !email || !phone || !vehicleType || !plateNumber || !password) {
    throw new Error('All fields are required');
  }
  const existingDriver = await prisma.driver.findUnique({
    where: { email },
  });
  if (existingDriver) {
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
  const { passwordHash: _, ...safeDriverData } = newDriver;
  return safeDriverData;
}

export async function authenticateDriver(credentials: any) {
  const { email, password } = credentials;
  if (!email || !password) {
    throw new Error('Email and password are required');
  }
  const foundDriver = await prisma.driver.findUnique({
    where: { email },
  });
  if (!foundDriver) {
    throw new Error('Invalid email or password');
  }
  const isPasswordValid = await Bun.password.verify(password, foundDriver.passwordHash);
  if (!isPasswordValid) {
    throw new Error('Invalid email or password');
  }
  const { passwordHash: _, ...safeDriverData } = foundDriver;
  return safeDriverData;
}

export async function retrieveOnlineDrivers() {
  const onlineDriversList = await prisma.driver.findMany({
    where: { isOnline: true },
  });
  return onlineDriversList.map(({ passwordHash: _, ...safeDriverData }) => safeDriverData);
}

export async function updateDriverOnlineStatus(driverId: string, onlineStatusDetails: any) {
  const { isOnline, lat, lng } = onlineStatusDetails;
  const updateData: any = { isOnline };
  if (lat != null) updateData.lat = lat;
  if (lng != null) updateData.lng = lng;
  const updatedDriver = await prisma.driver.update({
    where: { id: driverId },
    data: updateData,
  });
  const { passwordHash: _, ...safeDriverData } = updatedDriver;
  return safeDriverData;
}

export async function retrieveDriverProfile(driverId: string) {
  const foundDriver = await prisma.driver.findUnique({
    where: { id: driverId },
  });
  if (!foundDriver) {
    throw new Error('Driver not found');
  }
  const { passwordHash: _, ...safeDriverData } = foundDriver;
  return safeDriverData;
}

export async function retrieveDriverStats(driverId: string) {
  const foundDriver = await prisma.driver.findUnique({
    where: { id: driverId },
  });
  if (!foundDriver) {
    throw new Error('Driver not found');
  }
  let driverRides: any[] = [];
  try {
    const tripServiceResponse = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${driverId}`);
    if (tripServiceResponse.ok) {
      driverRides = await tripServiceResponse.json() as any[];
    }
  } catch (error) {
    console.error('Failed to fetch rides from trip-service:', error);
  }

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const todayRides = driverRides.filter((rideRecord: any) => {
    const createdAt = new Date(rideRecord.created_at);
    return createdAt >= startOfToday && rideRecord.status === 'completed';
  });

  const todayEarnings = todayRides.reduce((accumulatedFare: number, rideRecord: any) => accumulatedFare + (rideRecord.fare ?? 0), 0);
  const todayTrips = todayRides.length;
  const baseHours = todayTrips * 0.75;
  const hoursOnline = parseFloat((foundDriver.isOnline ? baseHours + 0.5 : baseHours).toFixed(1));

  const completedRides = driverRides.filter((rideRecord: any) => rideRecord.status === 'completed');
  const cancelledRides = driverRides.filter((rideRecord: any) => rideRecord.status === 'cancelled');

  const totalTrips = completedRides.length;
  const lifetimeEarnings = completedRides.reduce((accumulatedFare: number, rideRecord: any) => accumulatedFare + (rideRecord.fare ?? 0), 0);

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

export async function retrieveDriverTripHistory(driverId: string) {
  const tripServiceResponse = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${driverId}`);
  if (!tripServiceResponse.ok) {
    throw new Error('Trip service failed with status ' + tripServiceResponse.status);
  }
  return await tripServiceResponse.json();
}

export async function retrieveActiveRideRequests() {
  const tripServiceResponse = await fetch(`${TRIP_SERVICE_URL}/rides/active`);
  if (!tripServiceResponse.ok) {
    throw new Error('Trip service unavailable with status ' + tripServiceResponse.status);
  }
  return await tripServiceResponse.json();
}
