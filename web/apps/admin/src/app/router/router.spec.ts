import { describe, expect, it } from 'vitest'
import router from '@/app/router'
import { navigationGroups } from '@/app/navigation/sidebar-menu'

describe('admin router', () => {
  it('resolves every sidebar navigation item path to a valid named route', () => {
    const navItems = navigationGroups.flatMap((group) => group.items)
    expect(navItems.length).toBeGreaterThan(20)

    for (const item of navItems) {
      const resolved = router.resolve(item.path)
      expect(resolved.name, `Missing route for sidebar path ${item.path}`).toBeTruthy()
      expect(resolved.name, `Sidebar path ${item.path} hit 404 fallback`).not.toBe('not-found')
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
    expect(unknown.name).toBe('not-found')
  })

  it('redirects root path to the executive overview route', async () => {
    await router.push('/')
    await router.isReady()
    expect(router.currentRoute.value.path).toBe('/dashboard/overview')
  })
})
