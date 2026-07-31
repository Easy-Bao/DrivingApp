import { dev } from '$app/environment';
import { isRecord } from '$lib/admin';
import { adminApi } from '$lib/server/admin-api';
import type { Cookies } from '@sveltejs/kit';

export const ADMIN_COOKIE = 'baobao_admin_session';
export const ADMIN_SESSION_SECONDS = 8 * 60 * 60;

export function adminSessionCookieIsSecure(
  url: URL,
  isDevelopment = dev,
): boolean {
  const isLoopback =
    url.hostname === 'localhost'
    || url.hostname === '127.0.0.1'
    || url.hostname === '[::1]';
  return url.protocol === 'https:' || (!isDevelopment && !isLoopback);
}

export async function validateAdminSession(
  fetcher: typeof fetch,
  token: string,
): Promise<boolean> {
  try {
    const session = await adminApi<unknown>(
      fetcher,
      '/auth/admin/verify',
      undefined,
      {
        method: 'POST',
        body: JSON.stringify({ token }),
      },
    );
    return (
      isRecord(session) &&
      typeof session.userId === 'string' &&
      typeof session.email === 'string' &&
      session.role === 'admin'
    );
  } catch {
    return false;
  }
}

export function setAdminSession(cookies: Cookies, token: string, secure: boolean): void {
  cookies.set(ADMIN_COOKIE, token, {
    path: '/',
    httpOnly: true,
    sameSite: 'strict',
    secure,
    maxAge: ADMIN_SESSION_SECONDS,
  });
}

export function clearAdminSession(cookies: Cookies, secure: boolean): void {
  cookies.delete(ADMIN_COOKIE, {
    path: '/',
    httpOnly: true,
    sameSite: 'strict',
    secure,
  });
}
