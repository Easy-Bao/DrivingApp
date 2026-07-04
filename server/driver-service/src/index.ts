/**
 * Driver Service entrypoint using Hono and Prisma to manage driver registration, authentication, status, and telemetry updates.
 */
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { prisma } from './db.ts';

const app = new Hono();

app.use('*', cors());

app.post('/drivers/signup', async (c) => {
  try {
    const { name, email, phone, vehicleType, plateNumber, password } = await c.req.json();
    if (!name || !email || !phone || !vehicleType || !plateNumber || !password) {
      return c.json({ error: 'All fields are required' }, 400);
    }
    const existing = await prisma.driver.findUnique({
      where: { email },
    });
    if (existing) {
      return c.json({ error: 'A driver with this email already exists' }, 409);
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
    return c.json(safe, 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/drivers/login', async (c) => {
  try {
    const { email, password } = await c.req.json();
    if (!email || !password) {
      return c.json({ error: 'Email and password are required' }, 400);
    }
    const found = await prisma.driver.findUnique({
      where: { email },
    });
    if (!found) {
      return c.json({ error: 'Invalid email or password' }, 401);
    }
    const valid = await Bun.password.verify(password, found.passwordHash);
    if (!valid) {
      return c.json({ error: 'Invalid email or password' }, 401);
    }
    const { passwordHash: _, ...safe } = found;
    return c.json({ driver: safe }, 200);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/drivers/online', async (c) => {
  try {
    const list = await prisma.driver.findMany({
      where: { isOnline: true },
    });
    const safeList = list.map(({ passwordHash: _, ...safe }) => safe);
    return c.json(safeList);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

app.post('/drivers/:id/online', async (c) => {
  const id = c.req.param('id');
  try {
    const { isOnline, lat, lng } = await c.req.json();
    const updateData: any = { isOnline };
    if (lat != null) updateData.lat = lat;
    if (lng != null) updateData.lng = lng;
    const updated = await prisma.driver.update({
      where: { id },
      data: updateData,
    });
    const { passwordHash: _, ...safe } = updated;
    return c.json(safe);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/drivers/:id', async (c) => {
  const id = c.req.param('id');
  try {
    const found = await prisma.driver.findUnique({
      where: { id },
    });
    if (!found) {
      return c.json({ error: 'Driver not found' }, 404);
    }
    const { passwordHash: _, ...safe } = found;
    return c.json(safe);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/drivers/:id/stats', async (c) => {
  const id = c.req.param('id');
  try {
    const found = await prisma.driver.findUnique({
      where: { id },
    });
    if (!found) {
      return c.json({ error: 'Driver not found' }, 404);
    }
    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';
    let rides: any[] = [];
    try {
      const res = await fetch(`${tripServiceUrl}/rides/driver/${id}`);
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

    return c.json({
      todayEarnings,
      todayTrips,
      hoursOnline,
      lifetimeEarnings,
      totalTrips,
      acceptanceRate,
    });
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/drivers/:id/trips', async (c) => {
  const id = c.req.param('id');
  try {
    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';
    const res = await fetch(`${tripServiceUrl}/rides/driver/${id}`);
    if (!res.ok) {
      return c.json({ error: 'Trip service failed' }, res.status as any);
    }
    const data = await res.json();
    return c.json(data);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/rides/active', async (c) => {
  try {
    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';
    const res = await fetch(`${tripServiceUrl}/rides/active`);
    const data = await res.json();
    return c.json(data, res.status as any);
  } catch (e: any) {
    return c.json({ error: 'Trip service unavailable', details: e.message }, 502);
  }
});

app.get('/', (c) => c.json({ status: 'Driver Service OK' }));

const port = parseInt(process.env.PORT || '8082');

export default {
  port,
  fetch: app.fetch,
};
