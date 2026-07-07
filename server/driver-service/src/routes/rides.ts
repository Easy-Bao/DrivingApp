import { Hono } from 'hono';
import { retrieveActiveRideRequests } from '../services/drivers.ts';

export const ridesRouter = new Hono();

ridesRouter.get('/active', async (context) => {
  try {
    const activeRideRequests = await retrieveActiveRideRequests();
    return context.json(activeRideRequests);
  } catch (error: any) {
    const errorMessage = error.message;
    return context.json({ error: 'Trip service unavailable', details: errorMessage }, 502);
  }
});
