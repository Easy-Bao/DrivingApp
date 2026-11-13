import { beforeEach, describe, expect, it } from 'vitest'
import router from '@/app/router'
import { navigationGroups } from '@/app/navigation/sidebar-menu'
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

  it('resolves every sidebar navigation item path to a valid named route for root_operator', () => {
    const navItems = navigationGroups.flatMap((group) => group.items)
    expect(navItems.length).toBeGreaterThan(20)

    for (const item of navItems) {
      const resolved = router.resolve(item.path)
      expect(resolved.name, `Missing route for sidebar path ${item.path}`).toBeTruthy()
      expect(resolved.name, `Sidebar path ${item.path} hit 404 fallback`).not.toBe(
        '/[...pathMatch]',
      )
    }
  })

  it('marks detail routes with detail transition metadata and sends unknown paths to not-found', () => {
    const detailPaths = [
      '/users/driver-applications/APP-001',
      '/payments/topups/TOP-8921',
      '/payments/settlements/SET-401',
    ]

    for (const path of detailPaths) {
      const resolved = router.resolve(path)
      expect(resolved.meta.isDetail, `Expected meta.isDetail on ${path}`).toBe(true)
    }

    const unknown = router.resolve('/legacy/retired-section')
    expect(unknown.name).toBe('/[...pathMatch]')
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
    await router.push('/settings/app-settings')
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
    expect(router.currentRoute.value.name).toBe('/[...pathMatch]')

    await router.push('/users/driver-applications/<script>')
    expect(router.currentRoute.value.name).toBe('/[...pathMatch]')
  })

  it('enforces role-based authorization boundaries across operational roles', async () => {
    const fin = loginOperator('finance_ops', '7016')
    expect(fin.ok).toBe(true)

    await router.push('/payments/topups')
    expect(router.currentRoute.value.name).toBe('/payments/topups/')

    await router.push('/settings/app-settings')
    expect(router.currentRoute.value.name).toBe('/unauthorized')
    expect(router.currentRoute.value.query.from).toBe('/settings/app-settings')

    const support = loginOperator('support_lead', '7016')
    expect(support.ok).toBe(true)

    await router.push('/trips/safety-reports')
    expect(router.currentRoute.value.name).toBe('/trips/safety-reports')

    await router.push('/payments/topups')
    expect(router.currentRoute.value.name).toBe('/unauthorized')

    const fleet = loginOperator('fleet_ops', '7016')
    expect(fleet.ok).toBe(true)

    await router.push('/documents/verification')
    expect(router.currentRoute.value.name).toBe('/documents/verification')

    await router.push('/users/operators')
    expect(router.currentRoute.value.name).toBe('/unauthorized')
  })
})
