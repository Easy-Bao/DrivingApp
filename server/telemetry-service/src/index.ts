import { Hono } from 'hono';
import { cors } from 'hono/cors';

const app = new Hono();

app.use('*', cors());

interface Coordinate {
  lat: number;
  lng: number;
  updatedAt: string;
}

const locations = new Map<string, Coordinate>();

app.post('/telemetry/location', async (c) => {
  try {
    const { driverId, lat, lng } = await c.req.json();
    locations.set(driverId, {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      updatedAt: new Date().toISOString(),
    });
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/telemetry/location/:driverId', (c) => {
  const driverId = c.req.param('driverId');
  const loc = locations.get(driverId);
  if (!loc) return c.json({ error: 'No location telemetry found' }, 404);
  return c.json(loc);
});

app.get('/', (c) => c.json({ status: 'Telemetry Service OK' }));

const port = parseInt(process.env.PORT || '8085');
console.log(`Telemetry Service listening at http://0.0.0.0:${port}`);

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};
