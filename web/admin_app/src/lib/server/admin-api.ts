import { env } from '$env/dynamic/private';
import { isRecord, unwrapData } from '$lib/admin';

type Fetch = typeof fetch;

export class AdminApiError extends Error {
  constructor(
    message: string,
    readonly status = 500,
    readonly code = 'ADMIN_API_ERROR',
  ) {
    super(message);
  }
}

function gatewayUrl(): string {
  const configuredUrl = env.GATEWAY_URL?.trim();
  if (!configuredUrl) {
    throw new Error('Security Configuration Error: GATEWAY_URL is required.');
  }
  return configuredUrl.replace(/\/+$/, '');
}

function errorDetails(body: unknown, fallback: string): { message: string; code: string } {
  if (!isRecord(body)) {
    return { message: fallback, code: 'ADMIN_API_ERROR' };
  }

  const error = isRecord(body.error) ? body.error : body;
  return {
    message: typeof error.message === 'string' ? error.message : fallback,
    code: typeof error.code === 'string' ? error.code : 'ADMIN_API_ERROR',
  };
}

/**
 * Calls the gateway from the SvelteKit server so the admin token never reaches
 * browser JavaScript.
 */
export async function adminApi<T>(
  fetcher: Fetch,
  path: string,
  token: string | undefined,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  if (!headers.has('accept')) {
    headers.set('accept', 'application/json');
  }
  if (token) {
    headers.set('authorization', `Bearer ${token}`);
  }
  if (init.body && !headers.has('content-type')) {
    headers.set('content-type', 'application/json');
  }

  let response: Response;
  try {
    response = await fetcher(`${gatewayUrl()}${path}`, {
      ...init,
      headers,
    });
  } catch {
    throw new AdminApiError('The EasyRide gateway is unavailable.', 503, 'GATEWAY_UNAVAILABLE');
  }

  const contentType = response.headers.get('content-type') ?? '';
  const body = contentType.includes('json')
    ? await response.json().catch(() => null)
    : await response.text().catch(() => '');

  if (!response.ok) {
    const details = errorDetails(body, `Request failed with status ${response.status}.`);
    throw new AdminApiError(details.message, response.status, details.code);
  }

  return unwrapData(body) as T;
}

export function adminMutation<T>(
  fetcher: Fetch,
  path: string,
  token: string | undefined,
  method: 'POST' | 'PUT' | 'PATCH',
  body: Record<string, unknown>,
): Promise<T> {
  return adminApi<T>(fetcher, path, token, {
    method,
    headers: {
      'idempotency-key': crypto.randomUUID(),
    },
    body: JSON.stringify(body),
  });
}

export function loginToken(value: unknown): string | null {
  if (!isRecord(value)) {
    return null;
  }

  for (const key of ['accessToken', 'token', 'jwt']) {
    if (typeof value[key] === 'string' && value[key]) {
      return value[key];
    }
  }

  return null;
}
