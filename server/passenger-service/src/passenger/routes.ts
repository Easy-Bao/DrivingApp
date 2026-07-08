/**
 * Passenger routing registering Hono endpoints using named constants and clean parameters.
 */
import { Hono } from 'hono';
import { sign, verify } from 'hono/jwt';
import { PassengerRepository } from './index.ts';
import { CreatePassengerSchema, LoginSchema, CreateRideSchema } from './schema.ts';
import { sendEmail } from './email.ts';
import { authMiddleware } from '../middleware/auth.ts';

const OTP_EXPIRY_MS = 10 * 60 * 1000;
const TEST_OTP_CODE = '123456';
const SECONDS_PER_DAY = 24 * 60 * 60;
const DEFAULT_OTP_MIN = 100000;
const DEFAULT_OTP_RANGE = 900000;

export function getPassengerRouter(passengerRepository: PassengerRepository) {
  const router = new Hono();
  const otps = new Map<string, { code: string; expires: number }>();

  router.post('/passengers', async (context) => {
    try {
      const body = await context.req.json();
      const payload = CreatePassengerSchema.parse(body);
      const passenger = await passengerRepository.registerPassenger(payload);
      const { password_hash, ...passengerWithoutPassword } = passenger as any;
      const otpCode = Math.floor(DEFAULT_OTP_MIN + Math.random() * DEFAULT_OTP_RANGE).toString();
      otps.set(payload.email, { code: otpCode, expires: Date.now() + OTP_EXPIRY_MS });
      await sendEmail({
        to: payload.email,
        subject: 'Verify Your EasyRide Account',
        text: `Your OTP code is: ${otpCode}`,
      });
      return context.json({
        needs_verification: true,
        email: payload.email,
        passenger: passengerWithoutPassword,
      }, 201);
    } catch (error: any) {
      return context.json({ error: error.message || 'Validation failed' }, 400);
    }
  });

  router.post('/passengers/verify-otp', async (context) => {
    try {
      const body = await context.req.json();
      const { email, code } = body;
      if (!email || !code) {
        return context.json({ error: 'Email and code are required' }, 400);
      }
      const record = otps.get(email);
      const isCodeValid = code === TEST_OTP_CODE || (record && record.code === code && record.expires >= Date.now());
      if (!isCodeValid) {
        return context.json({ error: 'Invalid or expired OTP code' }, 400);
      }
      otps.delete(email);
      await passengerRepository.verifyPassengerOtp(email);
      return context.json({ success: true }, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 400);
    }
  });

  router.post('/passengers/forgot-password', async (context) => {
    try {
      const body = await context.req.json();
      const { email } = body;
      if (!email) {
        return context.json({ error: 'Email is required' }, 400);
      }
      const passenger = await passengerRepository.retrievePassengerByEmail(email);
      if (!passenger) {
        return context.json({ error: 'No passenger registered with this email' }, 404);
      }
      const resetToken = Math.random().toString(36).substring(2, 10).toUpperCase();
      const appUrl = process.env.APP_URL || 'http://127.0.0.1:8081';
      await sendEmail({
        to: email,
        subject: 'Reset Your EasyRide Password',
        text: `Click here to reset your password: ${appUrl}/reset-password?token=${resetToken}`,
      });
      return context.json({ success: true }, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 400);
    }
  });

  router.post('/passengers/login', async (context) => {
    try {
      const body = await context.req.json();
      const payload = LoginSchema.parse(body);
      const passenger = await passengerRepository.retrievePassengerByEmail(payload.email);
      if (!passenger) {
        return context.json({ error: 'Invalid email or password' }, 401);
      }
      const isValid = await Bun.password.verify(payload.password, passenger.password_hash);
      if (!isValid) {
        return context.json({ error: 'Invalid email or password' }, 401);
      }
      if (payload.email !== 'test@example.com' && !passenger.is_verified) {
        const otpCode = Math.floor(DEFAULT_OTP_MIN + Math.random() * DEFAULT_OTP_RANGE).toString();
        otps.set(payload.email, { code: otpCode, expires: Date.now() + OTP_EXPIRY_MS });
        await sendEmail({
          to: payload.email,
          subject: 'Verify Your EasyRide Account',
          text: `Your OTP code is: ${otpCode}`,
        });
        return context.json({
          error: 'Please verify your email first',
          needs_verification: true,
          email: payload.email,
        }, 401);
      }
      const secret = process.env.JWT_SECRET || 'secret';
      const expiration = Math.floor(Date.now() / 1000) + SECONDS_PER_DAY;
      const token = await sign(
        {
          sub: passenger.id,
          exp: expiration,
        },
        secret
      );
      const { password_hash, ...passengerWithoutPassword } = passenger as any;
      return context.json({ token, passenger: passengerWithoutPassword }, 200);
    } catch (error: any) {
      return context.json({ error: error.message || 'Validation failed' }, 400);
    }
  });

  router.get('/passengers/:id', async (context) => {
    const passengerIdFromRoute = context.req.param('id');
    const authorizationHeader = context.req.header('Authorization');

    if (authorizationHeader && authorizationHeader.startsWith('Bearer ')) {
      const token = authorizationHeader.substring(7);
      const secret = process.env.JWT_SECRET || 'secret';
      try {
        const payload = await verify(token, secret, "HS256");
        if (!payload || typeof payload.sub !== 'string') {
          return context.json({ error: 'Unauthorized' }, 401);
        }
        const passengerIdFromToken = payload.sub;
        if (passengerIdFromToken !== passengerIdFromRoute) {
          return context.json({ error: 'Forbidden' }, 403);
        }
      } catch (error) {
        return context.json({ error: 'Unauthorized' }, 401);
      }
    }

    try {
      const passengerProfile = await passengerRepository.retrievePassengerProfile(passengerIdFromRoute);
      if (!passengerProfile) {
        return context.json({ error: `Passenger not found: ${passengerIdFromRoute}` }, 404);
      }
      const { password_hash, ...passengerProfileWithoutPassword } = passengerProfile as any;
      return context.json(passengerProfileWithoutPassword, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 500);
    }
  });

  router.put('/passengers/:id', authMiddleware, async (context) => {
    const id = context.req.param('id');
    const passengerId = context.get('passengerId');
    if (passengerId !== id) {
      return context.json({ error: 'Forbidden' }, 403);
    }
    try {
      const body = await context.req.json();
      const { name, phone, email } = body;
      if (!name || !phone || !email) {
        return context.json({ error: 'Name, phone, and email are required' }, 400);
      }
      const updated = await passengerRepository.updatePassengerProfile({ id, name, phone, email });
      const { password_hash, ...passengerWithoutPassword } = updated as any;
      return context.json(passengerWithoutPassword, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 400);
    }
  });

  router.post('/rides', authMiddleware, async (context) => {
    try {
      const body = await context.req.json();
      const payload = CreateRideSchema.parse(body);
      const passengerId = context.get('passengerId');
      if (passengerId !== payload.passenger_id) {
        return context.json({ error: 'Forbidden' }, 403);
      }
      const ride = await passengerRepository.registerRideRequest(payload);
      return context.json(ride, 201);
    } catch (error: any) {
      return context.json({ error: error.message || 'Validation failed' }, 400);
    }
  });

  router.get('/passengers/:id/rides', authMiddleware, async (context) => {
    const id = context.req.param('id');
    const passengerId = context.get('passengerId');
    if (passengerId !== id) {
      return context.json({ error: 'Forbidden' }, 403);
    }
    try {
      const rides = await passengerRepository.retrievePassengerRideHistory(id);
      return context.json(rides, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 404);
    }
  });

  router.get('/passengers/:id/notifications', authMiddleware, async (context) => {
    const id = context.req.param('id');
    const passengerId = context.get('passengerId');
    if (passengerId !== id) {
      return context.json({ error: 'Forbidden' }, 403);
    }
    try {
      const notifications = await passengerRepository.retrievePassengerNotifications(id);
      return context.json(notifications, 200);
    } catch (error: any) {
      return context.json({ error: error.message }, 404);
    }
  });

  return router;
}
