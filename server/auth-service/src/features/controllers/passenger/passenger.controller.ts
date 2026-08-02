import type { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';

import type {
  LoginPassengerInput,
  RegisterPassengerInput,
} from '../../schemas/passenger/passenger.zod.ts';
import {
  InvalidPassengerCredentialsError,
  PassengerAccountAlreadyExistsError,
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
    if (error instanceof PassengerAccountAlreadyExistsError) {
      throw new HTTPException(400, { message: error.message });
    }
    console.error('Passenger registration service failed.', error);
    throw new HTTPException(500, {
      message: 'Passenger registration is temporarily unavailable',
    });
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
