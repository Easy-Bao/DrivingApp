import { Context } from 'hono';
import { verify } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import { PassengerRepositoryImpl } from '../repositories/passenger.repository.ts';
import { PassengerService } from '../services/passenger.service.ts';

const passengerRepository = new PassengerRepositoryImpl();
const passengerService = new PassengerService(passengerRepository);

export async function handleGetPassengerProfile(context: Context) {
  const passengerIdFromRoute = context.req.param('id')!;
  const authorizationHeader = context.req.header('Authorization');

  if (authorizationHeader && authorizationHeader.startsWith('Bearer ')) {
    const token = authorizationHeader.substring(7);
    const secret = process.env.JWT_SECRET;
    if (!secret || secret.trim().length === 0) {
      throw new Error('Security Configuration Error: JWT_SECRET environment variable is missing.');
    }
    try {
      const payload = await verify(token, secret, "HS256");
      if (
        payload
        && typeof payload.sub === 'string'
        && payload.role === 'passenger'
      ) {
        const passengerIdFromToken = payload.sub;
        if (passengerIdFromToken !== passengerIdFromRoute) {
          throw new HTTPException(403, { message: 'Forbidden' });
        }
      } else {
        throw new HTTPException(401, { message: 'Unauthorized' });
      }
    } catch (error) {
      if (error instanceof HTTPException) throw error;
      throw new HTTPException(401, { message: 'Unauthorized' });
    }
  } else {
    throw new HTTPException(401, { message: 'Unauthorized' });
  }

  const profile = await passengerService.getPassengerProfile(passengerIdFromRoute);
  return context.json(profile, 200);
}

export async function handleUpdatePassengerProfile(context: Context) {
  const id = context.req.param('id')!;
  const passengerId = context.get('passengerId');
  if (passengerId !== id) {
    throw new HTTPException(403, { message: 'Forbidden' });
  }

  const { name, phone, email } = await context.req.json();
  if (!name || !phone || !email) {
    throw new HTTPException(400, { message: 'Name, phone, and email are required' });
  }

  const result = await passengerService.updatePassengerProfile(id, { name, phone, email });
  return context.json(result, 200);
}

export async function handleCreateRideRequest(context: Context) {
  const body = await context.req.json();
  const passengerId = context.get('passengerId');
  if (passengerId !== body.passenger_id) {
    throw new HTTPException(403, { message: 'Forbidden' });
  }

  const result = await passengerService.createRideRequest(body);
  return context.json(result, 201);
}

export async function handleGetPassengerRideHistory(context: Context) {
  const id = context.req.param('id')!;
  const passengerId = context.get('passengerId');
  if (passengerId !== id) {
    throw new HTTPException(403, { message: 'Forbidden' });
  }

  const result = await passengerService.getPassengerRideHistory(id);
  return context.json(result, 200);
}

export async function handleGetPassengerNotifications(context: Context) {
  const id = context.req.param('id')!;
  const passengerId = context.get('passengerId');
  if (passengerId !== id) {
    throw new HTTPException(403, { message: 'Forbidden' });
  }

  const result = await passengerService.getPassengerNotifications(id);
  return context.json(result, 200);
}

export async function handleGetPassengersBatch(context: Context) {
  const { ids } = await context.req.json();
  if (!Array.isArray(ids) || ids.length === 0) {
    throw new HTTPException(400, { message: 'ids must be a non-empty array of passenger IDs' });
  }
  const result = await passengerService.getPassengersBatch(ids);
  return context.json(result, 200);
}

export async function handleGetPassengerRideAccess(context: Context) {
  return context.json(
    await passengerService.getRideAccess(context.req.param('id')!),
    200,
  );
}

export async function handleRestrictPassenger(context: Context) {
  const body = await context.req.json() as {
    case_id?: string | null;
    ends_at?: string | null;
    reason: string;
    admin_id: string;
  };
  const idempotencyKey = context.req.header('Idempotency-Key');
  if (!idempotencyKey) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const result = await passengerService.restrictPassenger({
    passengerId: context.req.param('id')!,
    caseId: body.case_id,
    reason: body.reason,
    endsAt: body.ends_at ? new Date(body.ends_at) : null,
    createdBy: body.admin_id,
    idempotencyKey,
  });
  return context.json(result, 201);
}

export async function handleListPassengerRestrictions(context: Context) {
  return context.json(
    await passengerService.listPassengerRestrictions(context.req.param('id')!),
    200,
  );
}

export async function handleLiftPassengerRestriction(context: Context) {
  const idempotencyKey = context.req.header('Idempotency-Key');
  if (!idempotencyKey) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const { reason, admin_id: adminId } = await context.req.json() as {
    reason: string;
    admin_id: string;
  };
  return context.json(await passengerService.liftPassengerRestriction({
    restrictionId: context.req.param('restrictionId')!,
    reason,
    adminId,
    idempotencyKey,
  }), 200);
}
