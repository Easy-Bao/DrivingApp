import type { Cookies } from '@sveltejs/kit';

export const ADMIN_COOKIE = 'baobao_admin_session';
export const ADMIN_SESSION_SECONDS = 8 * 60 * 60;

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
