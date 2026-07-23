import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { DriverAuthenticationService } from '../../services/driver/driver.service.ts';
import { RegisterDriverInput, LoginDriverInput } from '../../schemas/driver/driver.zod.ts';

const driverAuthenticationService = new DriverAuthenticationService();

export async function handleRegisterDriverAccount(c: Context) {
  try {
    const body = c.req.valid('json' as never) as RegisterDriverInput;
    const result = await driverAuthenticationService.registerDriverAccount(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Driver registration failed';
    throw new HTTPException(400, { message });
  }
}

export async function handleAuthenticateDriver(c: Context) {
  try {
    const body = c.req.valid('json' as never) as LoginDriverInput;
    const result = await driverAuthenticationService.authenticateDriverCredential(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Driver authentication failed';
    throw new HTTPException(401, { message });
  }
}
