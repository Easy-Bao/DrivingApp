/**
 * WebSocket tunnel bridging a connected client to the chat-service WebSocket endpoint.
 * The backend URL uses the URL API to swap the scheme from http(s) to ws(s) without
 * string replacement, avoiding silent corruption when the base URL ends with a slash.
 */
import { upgradeWebSocket } from 'hono/bun';
import { SERVICE_REGISTRY } from '../config/gateway.config.ts';

export const wsTunnelHandler = upgradeWebSocket((context) => {
  const chatBaseUrl = new URL(SERVICE_REGISTRY.chat);

  // Derive the WebSocket scheme from the HTTP scheme so the tunnel works for both
  // plain-text (ws://) and TLS-terminated (wss://) deployments.
  chatBaseUrl.protocol = chatBaseUrl.protocol === 'https:' ? 'wss:' : 'ws:';
  chatBaseUrl.pathname = '/chat/ws';
  chatBaseUrl.search = new URL(context.req.url).search;

  const backendWsUrl = chatBaseUrl.toString();

  return {
    onOpen(_event, ws) {
      const backendWs = new WebSocket(backendWsUrl);

      backendWs.onmessage = (msg) => {
        ws.send(msg.data);
      };
      backendWs.onclose = () => {
        ws.close();
      };

      (ws as any)._backendWs = backendWs;
    },
    onMessage(event, ws) {
      const backendWs: WebSocket | undefined = (ws as any)._backendWs;
      if (backendWs && backendWs.readyState === WebSocket.OPEN) {
        backendWs.send(event.data);
      }
    },
    onClose(_event, ws) {
      const backendWs: WebSocket | undefined = (ws as any)._backendWs;
      if (backendWs) {
        backendWs.close();
      }
    },
  };
});
