import { HTTPException } from 'hono/http-exception';
import { ContentfulStatusCode } from 'hono/utils/http-status';

export type ServiceName = 'driver' | 'passenger' | 'trip' | 'bidding' | 'fare';

function requiredEnvironment(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Configuration Error: ${name} is required.`);
  return value;
}

const SERVICE_ENVIRONMENT: Record<ServiceName, string> = {
  driver: 'DRIVER_SERVICE_URL',
  passenger: 'PASSENGER_SERVICE_URL',
  trip: 'TRIP_SERVICE_URL',
  bidding: 'BIDDING_SERVICE_URL',
  fare: 'FARE_SERVICE_URL',
};

export class AdminClients {
  async request<T>(
    service: ServiceName,
    path: string,
    init: RequestInit = {},
  ): Promise<T> {
    const internalToken = requiredEnvironment('INTERNAL_SERVICE_TOKEN');
    const headers = new Headers(init.headers);
    headers.set('X-Internal-Service-Token', internalToken);
    headers.set('X-Service-Name', 'admin-service');
    if (init.body && !headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json');
    }

    const response = await fetch(
      new URL(path, requiredEnvironment(SERVICE_ENVIRONMENT[service])),
      { ...init, headers },
    );
    const body = await response.json().catch(() => null) as Record<string, any> | null;
    if (!response.ok) {
      const message = typeof body?.code === 'string'
        ? body.code
        : typeof body?.error?.code === 'string'
        ? body.error.code
        : typeof body?.message === 'string'
          ? body.message
          : typeof body?.error === 'string'
            ? body.error
        : `${service} service rejected the request`;
      throw new HTTPException(
        (response.status >= 400 && response.status < 600
          ? response.status
          : 502) as ContentfulStatusCode,
        { message },
      );
    }
    return body as T;
  }

  async safeRequest<T>(
    service: ServiceName,
    path: string,
  ): Promise<{ ok: true; data: T } | { ok: false; error: string }> {
    try {
      return { ok: true, data: await this.request<T>(service, path) };
    } catch (error) {
      return {
        ok: false,
        error: error instanceof Error ? error.message : 'Service unavailable',
      };
    }
  }
}
