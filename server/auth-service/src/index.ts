import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { authRouter } from './features/routes/auth.routes.ts';

const app = new Hono();

app.use('*', cors());
app.route('/auth', authRouter);

app.get('/', (c) => c.json({ status: 'Auth Service OK', hasher: 'Bun.password (Native)' }));

const port = parseInt(process.env.PORT || '8088');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};
