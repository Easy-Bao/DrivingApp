import { describe, expect, it, vi } from 'vitest'

const SESSION_STORAGE_KEY = 'easyride_console_session_v1'

describe('auth session security', () => {
  it('fails closed into a locked session when persisted session JSON is corrupt', async () => {
    window.sessionStorage.setItem(SESSION_STORAGE_KEY, '{corrupt-json')
    vi.resetModules()

    const auth = await import('@/core/auth/auth-session')
    expect(auth.getAuthSession().locked).toBe(true)
    expect(auth.isSessionAuthenticated()).toBe(false)
  })

  it('rejects active stored sessions with missing string identity fields or short tokens', async () => {
    window.sessionStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({
        token: 'short',
        userId: 'op-root',
        role: 'root_operator',
        operatorName: 12345,
        operatorEmail: null,
        expiresAt: Date.now() + 60_000,
        locked: false,
      }),
    )
    vi.resetModules()

    const auth = await import('@/core/auth/auth-session')
    expect(auth.getAuthSession().locked).toBe(true)
    expect(auth.isSessionAuthenticated()).toBe(false)
  })

  it('validates passcodes, signs in active roles, and locks the session on sign out', async () => {
    const auth = await import('@/core/auth/auth-session')

    expect(auth.loginOperator('finance_ops', '999')).toEqual({
      ok: false,
      error: 'PIN must be at least 4 characters.',
    })

    const signedIn = auth.loginOperator('finance_ops', '7016')
    expect(signedIn.ok).toBe(true)
    expect(auth.getAuthSession().role).toBe('finance_ops')
    expect(auth.getAuthSession().operatorName).toBe('Clarisse Mendoza')
    expect(auth.isSessionAuthenticated()).toBe(true)

    auth.lockAuthSession()
    expect(auth.getAuthSession().locked).toBe(true)
    expect(auth.isSessionAuthenticated()).toBe(false)
  })
})
