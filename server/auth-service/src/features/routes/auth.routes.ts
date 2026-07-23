import { Hono } from 'hono';
import { passengerAuthRouter } from './passenger/passenger.routes.ts';
import { driverAuthRouter } from './driver/driver.routes.ts';
import { commonAuthRouter } from './common/common.routes.ts';

export const authRouter = new Hono();

authRouter.route('/passenger', passengerAuthRouter);
authRouter.route('/driver', driverAuthRouter);
authRouter.route('/', commonAuthRouter);
