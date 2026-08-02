import { redirect, type Handle } from '@sveltejs/kit';
import {
  ADMIN_COOKIE,
  adminSessionCookieIsSecure,
  clearAdminSession,
  validateAdminSession,
} from '$lib/server/session';

const PUBLIC_PATHS = new Set(['/login', '/robots.txt']);

export const handle: Handle = async ({ event, resolve }) => {
  const token = event.cookies.get(ADMIN_COOKIE);
  const hasValidAdminSession = token
    ? await validateAdminSession(event.fetch, token)
    : false;

  event.locals.adminToken = hasValidAdminSession ? token : undefined;
  if (token && !hasValidAdminSession) {
    clearAdminSession(
      event.cookies,
      adminSessionCookieIsSecure(event.url),
    );
  }

  if (!hasValidAdminSession && !PUBLIC_PATHS.has(event.url.pathname)) {
    redirect(303, '/login');
  }

  if (hasValidAdminSession && event.url.pathname === '/login') {
    redirect(303, '/overview');
  }

  return resolve(event);
};
