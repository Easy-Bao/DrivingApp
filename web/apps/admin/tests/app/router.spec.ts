import { beforeEach, describe, expect, it } from 'vitest'
import router from '@/app/router'
import { allNavigationItems } from '@/app/navigation/menu'
import { sanitizeRedirectPath } from '@/app/router/guards'
import {
  lockAuthSession,
  loginOperator,
  restoreDefaultDemoSession,
  setAuthSessionForTesting,
} from '@/core/auth/auth-session'

describe('router security guards', () => {
  beforeEach(() => {
    restoreDefaultDemoSession()
  })

  it('resolves every sidebar navigation item path to a valid named route for admin', () => {
    expect(allNavigationItems.length).toBeGreaterThan(30)

    for (const item of allNavigationItems) {
      const resolved = router.resolve(item.path)
      expect(resolved.name, `Missing route for sidebar path ${item.path}`).toBeTruthy()
      expect(resolved.name, `Sidebar path ${item.path} hit 404 fallback`).not.toBe('/[...path]')
    }
  })

  it('redirects legacy configuration and governance routes to their new independent namespaces', async () => {
    const legacyPairs = [
      ['/payments/fare-pricing', '/config/fare-pricing'],
      ['/payments/commission-settings', '/config/commissions'],
      ['/payments/methods', '/config/payment-channels'],
      ['/settings/service-zones', '/config/service-zones'],
      ['/settings/cities', '/config/cities'],
      ['/settings/content', '/config/legal-policies'],
      ['/settings/app-settings', '/config/app-system'],
      ['/settings/audit-logs', '/admin/audit-logs'],
      ['/support/faqs', '/config/help-center'],
      ['/users/operators', '/admin/operators'],
      ['/users/roles', '/admin/roles'],
    ] as const

    for (const [legacy, expected] of legacyPairs) {
      await router.push(legacy)
      expect(router.currentRoute.value.path, `Expected ${legacy} -> ${expected}`).toBe(expected)
    }
  })

  it('marks detail routes with detail transition metadata and sends unknown paths to not-found', () => {
    const detailPaths = [
      '/users/driver-applications/APP-901',
      '/payments/topups/TOP-8921',
      '/payments/settlements/STL-9401',
    ]

    for (const path of detailPaths) {
      const resolved = router.resolve(path)
      expect(resolved.meta.isDetail, `Expected meta.isDetail on ${path}`).toBe(true)
    }

    const unknown = router.resolve('/legacy/retired-section')
    expect(unknown.name).toBe('/[...path]')
  })

  it('redirects root path to the executive overview route', async () => {
    await router.push('/')
    await router.isReady()
    expect(router.currentRoute.value.path).toBe('/dashboard/overview')
  })

  it('blocks protected routes when session is locked or expired and preserves safe redirect targets', async () => {
    lockAuthSession()
    await router.push('/payments/topups')
    expect(router.currentRoute.value.name).toBe('/auth/login')
    expect(router.currentRoute.value.query.redirect).toBe('/payments/topups')

    restoreDefaultDemoSession()
    setAuthSessionForTesting({ expiresAt: Date.now() - 10_000 })
    await router.push('/config/app-system')
    expect(router.currentRoute.value.name).toBe('/auth/login')
  })

  it('neutralizes open-redirect and unsafe route parameter injection attempts', async () => {
    expect(sanitizeRedirectPath('//evil.com')).toBe('/dashboard/overview')
    expect(sanitizeRedirectPath('https://evil.com/phish')).toBe('/dashboard/overview')
    expect(sanitizeRedirectPath('javascript:alert(1)')).toBe('/dashboard/overview')
    expect(sanitizeRedirectPath('/\\phish')).toBe('/dashboard/overview')
    expect(sanitizeRedirectPath('/auth/login')).toBe('/dashboard/overview')
    expect(sanitizeRedirectPath('/payments/topups?tab=pending')).toBe(
      '/payments/topups?tab=pending',
    )

    await router.push('/auth/login?redirect=//evil.com')
    expect(router.currentRoute.value.path).toBe('/dashboard/overview')

    await router.push('/payments/topups/bad..id')
    expect(router.currentRoute.value.name).toBe('/[...path]')

    await router.push('/users/driver-applications/<script>')
    expect(router.currentRoute.value.name).toBe('/[...path]')
  })

  it('enforces role-based authorization boundaries across operations, configuration, and governance', async () => {
    const fin = loginOperator('finance', '7016')
    expect(fin.ok).toBe(true)

    await router.push('/config/fare-pricing')
    expect(router.currentRoute.value.name).toBe('/config/fare-pricing')

    await router.push('/config/wallet-rules')
    expect(router.currentRoute.value.name).toBe('/config/wallet-rules')

    await router.push('/config/app-system')
    expect(router.currentRoute.value.name).toBe('/unauthorized')
    expect(router.currentRoute.value.query.from).toBe('/config/app-system')

    const support = loginOperator('support', '7016')
    expect(support.ok).toBe(true)

    await router.push('/config/safety-sos')
    expect(router.currentRoute.value.name).toBe('/config/safety-sos')

    await router.push('/payments/topups')
    expect(router.currentRoute.value.name).toBe('/unauthorized')

    const fleet = loginOperator('fleet', '7016')
    expect(fleet.ok).toBe(true)

    await router.push('/config/dispatch-policy')
    expect(router.currentRoute.value.name).toBe('/config/dispatch-policy')

    await router.push('/admin/operators')
    expect(router.currentRoute.value.name).toBe('/unauthorized')
  })
})
