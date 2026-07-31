import { HTTPException } from 'hono/http-exception';

const sensitiveAuditKey = /password|token|secret|authorization|cookie|otp|pin/i;
const sensitiveAuditText = /\bbearer\s+\S+|(?:password|token|secret|authorization|otp|pin)\s*[:=]\s*\S+/i;

function normalize(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter(([, entry]) => entry !== undefined)
        .sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0)
        .map(([key, entry]) => [key, normalize(entry)]),
    );
  }
  return value;
}

/** Binds an idempotency key to the meaning of a mutation without storing its payload. */
export async function fingerprintMutationPayload(payload: unknown): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(normalize(payload)));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

/** Removes credential-like fields before structured data reaches the audit log. */
export function sanitizeAuditValue(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string' && sensitiveAuditText.test(value)) return '[REDACTED]';
  if (Array.isArray(value)) return value.map(sanitizeAuditValue);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, entry]) => [
        key,
        sensitiveAuditKey.test(key) ? '[REDACTED]' : sanitizeAuditValue(entry),
      ]),
    );
  }
  return value;
}

export function sanitizeAuditReason(reason?: string | null): string | null {
  if (!reason) return null;
  return sensitiveAuditText.test(reason) ? '[REDACTED]' : reason;
}

/** Records only a stable error category and status, never an arbitrary error message. */
export function sanitizeAuditError(error: unknown): Record<string, unknown> {
  if (error instanceof HTTPException) {
    return {
      code: /^[A-Z][A-Z0-9_]+$/.test(error.message)
        ? error.message
        : 'REQUEST_FAILED',
      status: error.status,
    };
  }
  return { code: 'INTERNAL_ERROR' };
}
