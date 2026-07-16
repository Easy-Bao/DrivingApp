import { Hono } from 'hono';
import { handleProxy } from '../proxy/gateway.proxy.ts';
import { wsTunnelHandler } from '../ws/gateway.ws.ts';
import { SERVICE_REGISTRY } from '../config/gateway.config.ts';

export const gatewayRouter = new Hono();

gatewayRouter.get('/chat/ws', wsTunnelHandler);

gatewayRouter.all('/passengers/*', (context) => handleProxy(context, SERVICE_REGISTRY.passengers));
gatewayRouter.all('/rides/*',      (context) => handleProxy(context, SERVICE_REGISTRY.rides));
gatewayRouter.all('/drivers/*',    (context) => handleProxy(context, SERVICE_REGISTRY.drivers));
gatewayRouter.all('/telemetry/*',  (context) => handleProxy(context, SERVICE_REGISTRY.telemetry));
gatewayRouter.all('/bids/*',       (context) => handleProxy(context, SERVICE_REGISTRY.bidding));
gatewayRouter.all('/chat/*',       (context) => handleProxy(context, SERVICE_REGISTRY.chat));
