import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { AuthService } from '../services/auth.service.ts';

const authService = new AuthService();

export async function handleRegisterPassenger(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.registerPassenger(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Registration failed' });
  }
}

export async function handleLoginPassenger(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.authenticateUser(body, 'passenger');
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Authentication failed' });
  }
}

export async function handleRegisterDriver(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.registerDriver(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Registration failed' });
  }
}

export async function handleLoginDriver(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.authenticateUser(body, 'driver');
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Authentication failed' });
  }
}

export async function handleVerifyOtp(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.verifyOtpCode(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'OTP verification failed' });
  }
}

export async function handleForgotPassword(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await authService.sendForgotPasswordOtp(body.email);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Forgot password failed' });
  }
}

export async function handleVerifyToken(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const decoded = authService.verifyJwt(body.token);
    return c.json({ success: true, data: decoded });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Token verification failed' });
  }
}
