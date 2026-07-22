import { Context } from 'hono';
import { AuthService } from '../services/auth.service.ts';

const authService = new AuthService();

export async function handleRegisterPassenger(c: Context) {
  const body = c.req.valid('json' as any);
  const result = await authService.registerUser({ ...body, role: 'passenger' });
  return c.json({ success: true, data: result });
}

export async function handleLoginPassenger(c: Context) {
  const body = c.req.valid('json' as any);
  const result = await authService.authenticateUser({ ...body, role: 'passenger' });
  return c.json({ success: true, data: result });
}

export async function handleRegisterDriver(c: Context) {
  const body = c.req.valid('json' as any);
  const result = await authService.registerUser({ ...body, role: 'driver' });
  return c.json({ success: true, data: result });
}

export async function handleLoginDriver(c: Context) {
  const body = c.req.valid('json' as any);
  const result = await authService.authenticateUser({ ...body, role: 'driver' });
  return c.json({ success: true, data: result });
}

export async function handleVerifyOtp(c: Context) {
  const body = c.req.valid('json' as any);
  const result = await authService.verifyOtpCode(body);
  return c.json({ success: true, data: result });
}

export async function handleVerifyToken(c: Context) {
  const body = c.req.valid('json' as any);
  const decoded = authService.verifyJwt(body.token);
  return c.json({ success: true, data: decoded });
}
