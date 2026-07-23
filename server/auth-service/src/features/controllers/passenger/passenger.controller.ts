import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { PassengerAuthenticationService } from '../../services/passenger/passenger.service.ts';
import { RegisterPassengerInput, LoginPassengerInput } from '../../schemas/passenger/passenger.zod.ts';

const passengerAuthenticationService = new PassengerAuthenticationService();

export async function handleRegisterPassengerAccount(c: Context) {
  try {
    const body = c.req.valid('json' as never) as RegisterPassengerInput;
    const result = await passengerAuthenticationService.registerPassengerAccount(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Passenger registration failed';
    throw new HTTPException(400, { message });
  }
}

export async function handleAuthenticatePassenger(c: Context) {
  try {
    const body = c.req.valid('json' as never) as LoginPassengerInput;
    const result = await passengerAuthenticationService.authenticatePassengerCredential(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Passenger authentication failed';
    throw new HTTPException(401, { message });
  }
}
