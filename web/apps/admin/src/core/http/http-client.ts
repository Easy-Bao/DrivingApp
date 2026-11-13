import { getAuthSession, isSessionAuthenticated, lockAuthSession } from '@/core/auth/auth-session'

export class HttpClientError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.name = 'HttpClientError'
    this.status = status
  }
}

export async function httpClient<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options?.headers as Record<string, string> | undefined),
  }

  if (isSessionAuthenticated()) {
    const session = getAuthSession()
    if (session.token) {
      headers.Authorization = `Bearer ${session.token}`
    }
  }

  const response = await fetch(endpoint, {
    ...options,
    headers,
  })

  if (response.status === 401) {
    lockAuthSession()
  }

  if (!response.ok) {
    throw new HttpClientError(
      response.status,
      `HTTP error: ${response.status} ${response.statusText}`,
    )
  }

  return response.json() as Promise<T>
}
