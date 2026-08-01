import type { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';

import type {
  LoginPassengerInput,
  RegisterPassengerInput,
} from '../../schemas/passenger/passenger.zod.ts';
import {
  InvalidPassengerCredentialsError,
  PassengerAuthenticationService,
} from '../../services/passenger/passenger.service.ts';

const passengerAuthenticationService = new PassengerAuthenticationService();

export async function handleRegisterPassengerAccount(c: Context) {
  try {
    const body = c.req.valid('json' as never) as RegisterPassengerInput;
    const result = await passengerAuthenticationService
      .registerPassengerAccount(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Passenger registration failed';
    throw new HTTPException(400, { message });
  }
}

export async function handleAuthenticatePassenger(c: Context) {
  try {
    const body = c.req.valid('json' as never) as LoginPassengerInput;
    const result = await passengerAuthenticationService
      .authenticatePassengerCredential(body);
    return c.json({ success: true, data: result });
  } catch (error: unknown) {
    if (error instanceof InvalidPassengerCredentialsError) {
      throw new HTTPException(401, { message: error.message });
    }
    console.error('Passenger authentication service failed.', error);
    throw new HTTPException(500, {
      message: 'Passenger authentication is temporarily unavailable',
    });
  }
}
