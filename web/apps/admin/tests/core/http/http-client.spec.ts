import { describe, expect, it, vi } from 'vitest'
import { env } from '@/core/config/env'
import { isSessionAuthenticated, loginOperator } from '@/core/auth/auth-session'
import { HttpClientError, httpClient } from '@/core/http/http-client'

describe('httpClient', () => {
  it('resolves relative endpoints against env.apiBaseUrl and handles 204 No Content safely', async () => {
    loginOperator('root_operator', '7016')
    const fetchMock = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    vi.stubGlobal('fetch', fetchMock)

    const result = await httpClient<void>('/api/v1/trips/7016', { method: 'DELETE' })

    expect(result).toBeUndefined()
    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0]!
    expect(url).toBe(`${env.apiBaseUrl}/api/v1/trips/7016`)
    expect(new Headers(init?.headers).get('Authorization')).toMatch(/^Bearer /)
  })

  it('extracts structured server error messages and throws HttpClientError', async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ message: 'Invalid top-up reference number' }), {
        status: 422,
        headers: { 'Content-Type': 'application/json' },
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(
      httpClient('/api/v1/payments/topups', { method: 'POST', body: '{}' }),
    ).rejects.toMatchObject({
      name: 'HttpClientError',
      status: 422,
      message: 'Invalid top-up reference number',
    })
  })

  it('locks the active operator session when the API responds with 401 Unauthorized', async () => {
    loginOperator('finance_ops', '7016')
    expect(isSessionAuthenticated()).toBe(true)

    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ error: 'Token expired' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await expect(httpClient('/api/v1/payments/settlements')).rejects.toBeInstanceOf(HttpClientError)
    expect(isSessionAuthenticated()).toBe(false)
  })
})
