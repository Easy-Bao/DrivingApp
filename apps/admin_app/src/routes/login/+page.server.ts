import { fail, redirect } from '@sveltejs/kit';
import { AdminApiError, adminApi, loginToken } from '$lib/server/admin-api';
import { setAdminSession } from '$lib/server/session';
import type { Actions } from './$types';

export const actions: Actions = {
  default: async ({ request, fetch, cookies, url }) => {
    const form = await request.formData();
    const email = String(form.get('email') ?? '').trim().toLowerCase();
    const password = String(form.get('password') ?? '');

    if (!email || !password) {
      return fail(400, {
        email,
        message: 'Enter the owner email and password.',
      });
    }

    let token: string | null;
    try {
      const response = await adminApi<unknown>(fetch, '/auth/admin/login', undefined, {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      token = loginToken(response);
    } catch (error) {
      if (error instanceof AdminApiError) {
        return fail(error.status === 401 ? 401 : error.status === 429 ? 429 : 503, {
          email,
          message:
            error.status === 401
              ? 'The email or password is incorrect.'
              : error.status === 429
                ? 'Too many sign-in attempts. Wait for the lockout to expire, then try again.'
              : 'Owner sign-in is unavailable. Check the gateway and try again.',
        });
      }
      return fail(500, { email, message: 'Owner sign-in failed.' });
    }

    if (!token) {
      return fail(502, {
        email,
        message: 'The authentication service returned an invalid session.',
      });
    }

    setAdminSession(cookies, token, url.protocol === 'https:');
    redirect(303, '/overview');
  },
};
