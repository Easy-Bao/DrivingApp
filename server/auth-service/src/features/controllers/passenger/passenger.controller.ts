import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { PassengerAuthenticationService } from '../../services/passenger/passenger.service.ts';

const passengerAuthenticationService = new PassengerAuthenticationService();

export async function handleRegisterPassengerAccount(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await passengerAuthenticationService.registerPassengerAccount(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(400, { message: error.message || 'Passenger registration failed' });
  }
}

export async function handleAuthenticatePassenger(c: Context) {
  try {
    const body = c.req.valid('json' as any);
    const result = await passengerAuthenticationService.authenticatePassengerCredential(body);
    return c.json({ success: true, data: result });
  } catch (error: any) {
    throw new HTTPException(401, { message: error.message || 'Passenger authentication failed' });
  }
}
