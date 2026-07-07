import { Hono } from 'hono';
import { handleProxy, wsHandler, SERVICES } from '../services/gateway.ts';

export const gatewayRouter = new Hono();

gatewayRouter.get('/chat', wsHandler);
gatewayRouter.get('/chat/ws', wsHandler);

gatewayRouter.all('/passengers/*', (context) => handleProxy(context, SERVICES.passengers));
gatewayRouter.all('/rides/*', (context) => handleProxy(context, SERVICES.rides));
gatewayRouter.all('/drivers/*', (context) => handleProxy(context, SERVICES.drivers));
gatewayRouter.all('/telemetry/*', (context) => handleProxy(context, SERVICES.telemetry));
gatewayRouter.all('/bids/*', (context) => handleProxy(context, SERVICES.bidding));
gatewayRouter.all('/chat/*', (context) => handleProxy(context, SERVICES.chat));
