import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { OneTimePasswordStoreService } from '../../services/common/otp_store.ts';
import { JsonWebTokenService } from '../../services/common/jwt.service.ts';
import { PassengerAuthenticationService } from '../../services/passenger/passenger.service.ts';
import { DriverAuthenticationService } from '../../services/driver/driver.service.ts';
import { VerifyOtpInput, ForgotPasswordInput, VerifyTokenInput } from '../../schemas/common/common.zod.ts';

export async function handleVerifyOneTimePassword(c: Context) {
  try {
    const { email, code } = c.req.valid('json' as never) as VerifyOtpInput;
    const isVerified = OneTimePasswordStoreService.verifyOneTimePasswordCode(email, code);
    if (isVerified) {
      PassengerAuthenticationService.verifyPassengerAccountState(email);
      DriverAuthenticationService.verifyDriverAccountState(email);
    }
    return c.json({ success: true, data: { verified: true } });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'OTP verification failed';
    throw new HTTPException(400, { message });
  }
}

export async function handleSendForgotPasswordOneTimePassword(c: Context) {
  try {
    const { email } = c.req.valid('json' as never) as ForgotPasswordInput;
    OneTimePasswordStoreService.generateOneTimePasswordCode(email);
    return c.json({ success: true, data: { success: true } });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Forgot password failed';
    throw new HTTPException(400, { message });
  }
}

export async function handleVerifyAuthenticationToken(c: Context) {
  try {
    const { token } = c.req.valid('json' as never) as VerifyTokenInput;
    const decodedToken = JsonWebTokenService.verifyJsonWebToken(token);
    return c.json({ success: true, data: decodedToken });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Token verification failed';
    throw new HTTPException(401, { message });
  }
}
