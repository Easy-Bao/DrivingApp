import { Hono } from 'hono';
import { handleProxy, wsHandler, SERVICES } from '../services/gateway.ts';

export const gatewayRouter = new Hono();

gatewayRouter.get('/chat', wsHandler);
gatewayRouter.get('/chat/ws', wsHandler);

gatewayRouter.all('/passengers/*', (c) => handleProxy(c, SERVICES.passengers));
gatewayRouter.all('/rides/*', (c) => handleProxy(c, SERVICES.rides));
gatewayRouter.all('/drivers/*', (c) => handleProxy(c, SERVICES.drivers));
gatewayRouter.all('/telemetry/*', (c) => handleProxy(c, SERVICES.telemetry));
gatewayRouter.all('/bids/*', (c) => handleProxy(c, SERVICES.bidding));
gatewayRouter.all('/chat/*', (c) => handleProxy(c, SERVICES.chat));
