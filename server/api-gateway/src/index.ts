/// API Gateway routing incoming traffic to passenger, trip, driver, and telemetry services.
import { Hono } from 'hono';
import { cors } from 'hono/cors';

const app = new Hono();

app.use('*', cors());

const SERVICES = {
  passengers: process.env.PASSENGER_SERVICE_URL || 'http://127.0.0.1:8081',
  rides: process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083',
  drivers: process.env.DRIVER_SERVICE_URL || 'http://127.0.0.1:8082',
  telemetry: process.env.TELEMETRY_SERVICE_URL || 'http://127.0.0.1:8085',
};

async function handleProxy(c: any, targetBaseUrl: string) {
  const url = new URL(c.req.url);
  const targetUrl = `${targetBaseUrl}${url.pathname}${url.search}`;
  const headers = new Headers(c.req.raw.headers);
  headers.set('host', new URL(targetBaseUrl).host);
  const body = c.req.method === 'GET' || c.req.method === 'HEAD'
    ? undefined
    : await c.req.raw.clone().arrayBuffer();
  try {
    const res = await fetch(targetUrl, {
      method: c.req.method,
      headers,
      body,
    });
    return new Response(res.body, {
      status: res.status,
      headers: res.headers,
    });
  } catch (e: any) {
    return c.json({ error: 'Service Unavailable', details: e.message }, 502);
  }
}

app.all('/passengers/*', (c) => handleProxy(c, SERVICES.passengers));
app.all('/rides/*', (c) => handleProxy(c, SERVICES.rides));
app.all('/drivers/*', (c) => handleProxy(c, SERVICES.drivers));
app.all('/telemetry/*', (c) => handleProxy(c, SERVICES.telemetry));

app.get('/', (c) => c.json({ status: 'Gateway OK' }));

const port = parseInt(process.env.PORT || '8080');

export default {
  port,
  fetch: app.fetch,
};
