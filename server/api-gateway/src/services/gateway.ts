import { upgradeWebSocket } from 'hono/bun';

const getRequiredEnvVar = (variableName: string): string => {
  const value = process.env[variableName];
  if (!value) {
    throw new Error(`Configuration Error: Environment variable '${variableName}' is required but not set.`);
  }
  return value;
};

export const SERVICES = {
  passengers: getRequiredEnvVar('PASSENGER_SERVICE_URL'),
  rides: getRequiredEnvVar('TRIP_SERVICE_URL'),
  drivers: getRequiredEnvVar('DRIVER_SERVICE_URL'),
  telemetry: getRequiredEnvVar('TELEMETRY_SERVICE_URL'),
  bidding: getRequiredEnvVar('BIDDING_SERVICE_URL'),
  chat: getRequiredEnvVar('CHAT_SERVICE_URL'),
};

export async function handleProxy(context: any, targetBaseUrl: string) {
  const url = new URL(context.req.url);
  const targetUrl = `${targetBaseUrl}${url.pathname}${url.search}`;
  const headers = new Headers(context.req.raw.headers);
  headers.set('host', new URL(targetBaseUrl).host);
  const body = context.req.method === 'GET' || context.req.method === 'HEAD'
    ? undefined
    : await context.req.raw.clone().arrayBuffer();
  try {
    const res = await fetch(targetUrl, {
      method: context.req.method,
      headers,
      body,
    });
    return new Response(res.body, {
      status: res.status,
      headers: res.headers,
    });
  } catch (error: any) {
    return context.json({ error: 'Service Unavailable', details: error.message }, 502);
  }
}

export const wsHandler = upgradeWebSocket((context) => {
  let backendWs: WebSocket;
  const targetUrl = SERVICES.chat.replace(/^http/, 'ws') + '/chat/ws' + (new URL(context.req.url).search || '');
  return {
    onOpen(_event, ws) {
      backendWs = new WebSocket(targetUrl);
      backendWs.onmessage = (msg) => {
        ws.send(msg.data);
      };
      backendWs.onclose = () => {
        ws.close();
      };
    },
    onMessage(event, _ws) {
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
