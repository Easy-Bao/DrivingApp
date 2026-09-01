import { redirect } from '@sveltejs/kit';
import {
  adminSessionCookieIsSecure,
  clearAdminSession,
} from '$lib/server/session';

export function POST({ cookies, url }): never {
  clearAdminSession(cookies, adminSessionCookieIsSecure(url));
  redirect(303, '/login');
}
