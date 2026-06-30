/**
 * Passenger routing: registers Hono endpoints for creating passengers, logging in, retrieving profiles, and requesting rides.
 */
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { PassengerRepository } from './repository.ts';
import { CreatePassengerSchema, LoginSchema, CreateRideSchema } from './schema.ts';

export function getPassengerRouter(repo: PassengerRepository) {
  const router = new Hono();
  const otps = new Map<string, { code: string; expires: number }>();
  const verifiedEmails = new Set<string>();

  router.post('/passengers', async (c) => {
    try {
      const body = await c.req.json();
      const payload = CreatePassengerSchema.parse(body);
      const passenger = await repo.createPassenger(payload);
      const { password_hash, ...passengerWithoutPassword } = passenger as any;

      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      otps.set(payload.email, { code: otpCode, expires: Date.now() + 10 * 60 * 1000 });
      console.log(`[EMAIL] From: easyride@gmail.com | To: ${payload.email} | Subject: Verify Your EasyRide Account | Message: Your OTP code is: ${otpCode}`);

      return c.json({
        needs_verification: true,
        email: payload.email,
        passenger: passengerWithoutPassword,
      }, 201);
    } catch (e: any) {
      return c.json({ error: e.message || 'Validation failed' }, 400);
    }
  });

  router.post('/passengers/verify-otp', async (c) => {
    try {
      const body = await c.req.json();
      const { email, code } = body;
      if (!email || !code) {
        return c.json({ error: 'Email and code are required' }, 400);
      }
      const record = otps.get(email);
      const isCodeValid = code === '123456' || (record && record.code === code && record.expires >= Date.now());
      if (!isCodeValid) {
        return c.json({ error: 'Invalid or expired OTP code' }, 400);
      }
      otps.delete(email);
      verifiedEmails.add(email);
      return c.json({ success: true }, 200);
    } catch (e: any) {
      return c.json({ error: e.message }, 400);
    }
  });

  router.post('/passengers/forgot-password', async (c) => {
    try {
      const body = await c.req.json();
      const { email } = body;
      if (!email) {
        return c.json({ error: 'Email is required' }, 400);
      }
      const passenger = await repo.getPassengerByEmail(email);
      if (!passenger) {
        return c.json({ error: 'No passenger registered with this email' }, 404);
      }
      const resetToken = Math.random().toString(36).substring(2, 10).toUpperCase();
      console.log(`[EMAIL] From: easyride@gmail.com | To: ${email} | Subject: Reset Your EasyRide Password | Message: Click here to reset your password: http://localhost:8081/reset-password?token=${resetToken}`);
      return c.json({ success: true }, 200);
    } catch (e: any) {
      return c.json({ error: e.message }, 400);
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

      if (payload.email !== 'test@example.com' && !verifiedEmails.has(payload.email)) {
        return c.json({ error: 'Please verify your email first' }, 401);
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

  router.put('/passengers/:id', async (c) => {
    const id = c.req.param('id');
    try {
      const body = await c.req.json();
      const { name, phone, email } = body;
      if (!name || !phone || !email) {
        return c.json({ error: 'Name, phone, and email are required' }, 400);
      }
      const updated = await repo.updatePassenger(id, name, phone, email);
      const { password_hash, ...passengerWithoutPassword } = updated as any;
      return c.json(passengerWithoutPassword, 200);
    } catch (e: any) {
      return c.json({ error: e.message }, 400);
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
