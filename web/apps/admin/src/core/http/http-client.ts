import { env } from '@/core/config/env'
import { getAuthSession, isSessionAuthenticated, lockAuthSession } from '@/core/auth/auth-session'

export class HttpClientError extends Error {
  status: number
  details?: unknown

  constructor(message: string, status: number, details?: unknown) {
    super(message)
    this.name = 'HttpClientError'
    this.status = status
    this.details = details
  }
}

export function resolveApiUrl(endpoint: string): string {
  if (/^https?:\/\//i.test(endpoint)) {
    return endpoint
  }
  const base = env.apiBaseUrl.replace(/\/+$/, '')
  const normalizedPath = endpoint.startsWith('/') ? endpoint : `/${endpoint}`
  return `${base}${normalizedPath}`
}

async function readResponsePayload(
  response: Response,
): Promise<{ parsed: unknown; rawText: string }> {
  if (response.status === 204 || response.status === 205) {
    return { parsed: undefined, rawText: '' }
  }
  const contentLength = response.headers.get('content-length')
  if (contentLength === '0') {
    return { parsed: undefined, rawText: '' }
  }
  const rawText = await response.text().catch(() => '')
  if (!rawText.trim()) {
    return { parsed: undefined, rawText: '' }
  }
  try {
    return { parsed: JSON.parse(rawText) as unknown, rawText }
  } catch {
    return { parsed: rawText, rawText }
  }
}

function extractErrorMessage(payload: unknown, rawText: string, status: number): string {
  if (payload && typeof payload === 'object') {
    const record = payload as Record<string, unknown>
    if (typeof record.message === 'string' && record.message.trim()) {
      return record.message.trim()
    }
    if (typeof record.error === 'string' && record.error.trim()) {
      return record.error.trim()
    }
  }
  if (rawText.trim()) {
    return rawText.trim()
  }
  return `HTTP error: ${status}`
}

export async function httpClient<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const headers = new Headers(options?.headers)
  if (!headers.has('Accept')) {
    headers.set('Accept', 'application/json')
  }
  if (
    options?.body &&
    !(typeof FormData !== 'undefined' && options.body instanceof FormData) &&
    !headers.has('Content-Type')
  ) {
    headers.set('Content-Type', 'application/json')
  }
  const session = getAuthSession()
  if (!headers.has('Authorization') && isSessionAuthenticated() && session.token) {
    headers.set('Authorization', `Bearer ${session.token}`)
  }

  const response = await fetch(resolveApiUrl(endpoint), {
    ...options,
    headers,
  })

  const { parsed, rawText } = await readResponsePayload(response)

  if (!response.ok) {
    if (response.status === 401) {
      lockAuthSession()
    }
    throw new HttpClientError(
      extractErrorMessage(parsed, rawText, response.status),
      response.status,
      parsed,
    )
  }

  return parsed as T
}
