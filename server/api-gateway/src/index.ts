/// API Gateway routing incoming traffic to passenger, trip, driver, telemetry, and chat services.
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { createBunWebSocket } from 'hono/bun';

const app = new Hono();
const { upgradeWebSocket, websocket } = createBunWebSocket();

app.use('*', cors());

const SERVICES = {
  passengers: process.env.PASSENGER_SERVICE_URL || 'http://127.0.0.1:8081',
  rides: process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083',
  drivers: process.env.DRIVER_SERVICE_URL || 'http://127.0.0.1:8082',
  telemetry: process.env.TELEMETRY_SERVICE_URL || 'http://127.0.0.1:8085',
  bidding: process.env.BIDDING_SERVICE_URL || 'http://127.0.0.1:8084',
  chat: process.env.CHAT_SERVICE_URL || 'http://127.0.0.1:8086',
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

const wsHandler = upgradeWebSocket((c) => {
  let backendWs: WebSocket;
  const targetUrl = SERVICES.chat.replace(/^http/, 'ws') + '/chat/ws' + (new URL(c.req.url).search || '');
  return {
    onOpen(event, ws) {
      backendWs = new WebSocket(targetUrl);
      backendWs.onmessage = (msg) => {
        ws.send(msg.data);
      };
      backendWs.onclose = () => {
        ws.close();
      };
    },
    onMessage(event, ws) {
      if (backendWs && backendWs.readyState === WebSocket.OPEN) {
        backendWs.send(event.data);
      }
    },
    onClose() {
      if (backendWs) {
        backendWs.close();
      }
    }
  };
});

app.get('/chat', wsHandler);
app.get('/chat/ws', wsHandler);

app.all('/passengers/*', (c) => handleProxy(c, SERVICES.passengers));
app.all('/rides/*', (c) => handleProxy(c, SERVICES.rides));
app.all('/drivers/*', (c) => handleProxy(c, SERVICES.drivers));
app.all('/telemetry/*', (c) => handleProxy(c, SERVICES.telemetry));
app.all('/bids/*', (c) => handleProxy(c, SERVICES.bidding));
app.all('/chat/*', (c) => handleProxy(c, SERVICES.chat));

app.get('/', (c) => c.json({ status: 'Gateway OK' }));

const port = parseInt(process.env.PORT || '8080');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};
