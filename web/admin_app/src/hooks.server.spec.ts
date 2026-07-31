import { describe, expect, it, vi } from 'vitest';
import { ADMIN_COOKIE } from '$lib/server/session';
import { handle } from './hooks.server';

describe('Admin route guard', () => {
  it('accepts a cryptographically verified Admin session', async () => {
    const locals: App.Locals = {};
    const resolve = vi.fn(async () => new Response('Admin dashboard'));
    const event = {
      cookies: {
        get: vi.fn(() => 'signed-admin-token'),
        delete: vi.fn(),
      },
      fetch: vi.fn(async () => Response.json({
        success: true,
        data: {
          userId: 'adm_test',
          email: 'owner@example.com',
          role: 'admin',
        },
      })),
      locals,
      url: new URL('https://admin.example.com/overview'),
    };

    const response = await handle({ event, resolve } as never);

    expect(await response.text()).toBe('Admin dashboard');
    expect(locals.adminToken).toBe('signed-admin-token');
    expect(resolve).toHaveBeenCalledOnce();
    expect(event.cookies.delete).not.toHaveBeenCalled();
  });

  it('clears an invalid session and redirects a protected route to login', async () => {
    const resolve = vi.fn(async () => new Response('should not render'));
    const event = {
      cookies: {
        get: vi.fn(() => 'expired-admin-token'),
        delete: vi.fn(),
      },
      fetch: vi.fn(async () => Response.json(
        {
          success: false,
          error: {
            code: 'INVALID_ADMIN_SESSION',
            message: 'Admin authentication is invalid or expired.',
          },
        },
        { status: 401 },
      )),
      locals: {} as App.Locals,
      url: new URL('https://admin.example.com/overview'),
    };

    await expect(handle({ event, resolve } as never)).rejects.toMatchObject({
      status: 303,
      location: '/login',
    });
    expect(event.cookies.delete).toHaveBeenCalledWith(
      ADMIN_COOKIE,
      {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        secure: true,
      },
    );
    expect(resolve).not.toHaveBeenCalled();
  });
});
