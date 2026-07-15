/**
 * Generic reverse-proxy adapter forwarding any HTTP request to a backing microservice.
 * Target URLs are constructed via the URL API to prevent path-traversal and encoding issues
 * from manual string concatenation.
 */
import { Context } from 'hono';

export async function handleProxy(context: Context, targetBaseUrl: string): Promise<Response> {
  const incomingUrl = new URL(context.req.url);
  const targetUrl = new URL(incomingUrl.pathname + incomingUrl.search, targetBaseUrl);

  const forwardedHeaders = new Headers(context.req.raw.headers);
  forwardedHeaders.set('host', targetUrl.host);

  const requestBody =
    context.req.method === 'GET' || context.req.method === 'HEAD'
      ? undefined
      : await context.req.raw.clone().arrayBuffer();

  try {
    const upstreamResponse = await fetch(targetUrl.toString(), {
      method: context.req.method,
      headers: forwardedHeaders,
      body: requestBody,
    });
    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers: upstreamResponse.headers,
    });
  } catch (err: any) {
    return context.json({ error: 'Service Unavailable', details: err.message }, 502);
  }
}
