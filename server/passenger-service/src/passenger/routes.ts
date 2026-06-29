/**
 * Passenger routing: registers Hono endpoints for creating passengers, logging in, retrieving profiles, and requesting rides.
 */
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { PassengerRepository } from './repository.ts';
import { CreatePassengerSchema, LoginSchema, CreateRideSchema } from './schema.ts';

export function getPassengerRouter(repo: PassengerRepository) {
  const router = new Hono();

  router.post('/passengers', async (c) => {
    try {
      const body = await c.req.json();
      const payload = CreatePassengerSchema.parse(body);
      const passenger = await repo.createPassenger(payload);
      const { password_hash, ...passengerWithoutPassword } = passenger as any;
      return c.json(passengerWithoutPassword, 201);
    } catch (e: any) {
      return c.json({ error: e.message || 'Validation failed' }, 400);
    }
  });

  router.post('/passengers/login', async (c) => {
    try {
      const body = await c.req.json();
      const payload = LoginSchema.parse(body);

      const passenger = await repo.getPassengerByEmail(payload.email);
      if (!passenger) {
        return c.json({ error: 'Invalid email or password' }, 401);
      }

      const isValid = await Bun.password.verify(payload.password, passenger.password_hash);
      if (!isValid) {
        return c.json({ error: 'Invalid email or password' }, 401);
      }

      const secret = process.env.JWT_SECRET || 'secret';
      const expiration = Math.floor(Date.now() / 1000) + 24 * 60 * 60; // 24 hours

      const token = await sign(
        {
          sub: passenger.id,
          exp: expiration,
        },
        secret
      );

      const { password_hash, ...passengerWithoutPassword } = passenger as any;
      return c.json({ token, passenger: passengerWithoutPassword }, 200);
    } catch (e: any) {
      return c.json({ error: e.message || 'Validation failed' }, 400);
    }
  });

  router.get('/passengers/:id', async (c) => {
    const id = c.req.param('id');
    try {
      const passenger = await repo.getPassenger(id);
      if (!passenger) {
        return c.json({ error: `Passenger not found: ${id}` }, 404);
      }
      const { password_hash, ...passengerWithoutPassword } = passenger as any;
      return c.json(passengerWithoutPassword, 200);
    } catch (e: any) {
      return c.json({ error: e.message }, 500);
    }
  });

  router.post('/rides', async (c) => {
    try {
      const body = await c.req.json();
      const payload = CreateRideSchema.parse(body);
      const ride = await repo.createRideRequest(payload);
      return c.json(ride, 201);
    } catch (e: any) {
      return c.json({ error: e.message || 'Validation failed' }, 400);
    }
  });

  router.get('/passengers/:id/rides', async (c) => {
    const id = c.req.param('id');
    try {
      const rides = await repo.getPassengerRides(id);
      return c.json(rides, 200);
    } catch (e: any) {
      return c.json({ error: e.message }, 404);
    }
  });

  return router;
}
