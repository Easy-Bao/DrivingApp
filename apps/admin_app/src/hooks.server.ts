import { redirect, type Handle } from '@sveltejs/kit';
import { ADMIN_COOKIE } from '$lib/server/session';

const PUBLIC_PATHS = new Set(['/login', '/robots.txt']);

export const handle: Handle = async ({ event, resolve }) => {
  event.locals.adminToken = event.cookies.get(ADMIN_COOKIE);

  if (!event.locals.adminToken && !PUBLIC_PATHS.has(event.url.pathname)) {
    redirect(303, '/login');
  }

  if (event.locals.adminToken && event.url.pathname === '/login') {
    redirect(303, '/overview');
  }

  return resolve(event);
};
