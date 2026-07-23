import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { DriverAuthenticationService } from '../../services/driver/driver.service.ts';

const driverAuthenticationService = new DriverAuthenticationService();

export async function handleRegisterDriverAccount(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await driverAuthenticationService.registerDriverAccount(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Driver registration failed' });
  }
}

export async function handleAuthenticateDriver(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await driverAuthenticationService.authenticateDriverCredential(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Driver authentication failed' });
  }
}
