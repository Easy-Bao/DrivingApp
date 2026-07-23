import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { OneTimePasswordStoreService } from '../../services/common/otp_store.ts';
import { JsonWebTokenService } from '../../services/common/jwt.service.ts';
import { PassengerAuthenticationService } from '../../services/passenger/passenger.service.ts';
import { DriverAuthenticationService } from '../../services/driver/driver.service.ts';

export async function handleVerifyOneTimePassword(c: Context) {
  try {
    const { email, code } = c.req.valid('json' as any);
    const isVerified = OneTimePasswordStoreService.verifyOneTimePasswordCode(email, code);
    if (isVerified) {
      PassengerAuthenticationService.verifyPassengerAccountState(email);
      DriverAuthenticationService.verifyDriverAccountState(email);
    }
    return c.json({ success: true, data: { verified: true } });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'OTP verification failed' });
  }
}

export async function handleSendForgotPasswordOneTimePassword(c: Context) {
  try {
    const { email } = c.req.valid('json' as any);
    OneTimePasswordStoreService.generateOneTimePasswordCode(email);
    return c.json({ success: true, data: { success: true } });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Forgot password failed' });
  }
}

export async function handleVerifyAuthenticationToken(c: Context) {
  try {
    const { token } = c.req.valid('json' as any);
    const decodedToken = JsonWebTokenService.verifyJsonWebToken(token);
    return c.json({ success: true, data: decodedToken });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Token verification failed' });
  }
}
