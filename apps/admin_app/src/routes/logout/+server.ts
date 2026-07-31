import { redirect } from '@sveltejs/kit';
import { clearAdminSession } from '$lib/server/session';

export function POST({ cookies, url }): never {
  clearAdminSession(cookies, url.protocol === 'https:');
  redirect(303, '/login');
}
