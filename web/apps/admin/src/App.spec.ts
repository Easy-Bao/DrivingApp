import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import App from '@/App.vue'

type NavigationGuard = (
  to: { path: string; name?: string; params?: Record<string, string>; meta?: Record<string, unknown> },
  from: { path: string; name?: string; params?: Record<string, string>; meta?: Record<string, unknown> },
) => void

let registeredGuard: NavigationGuard | null = null

vi.mock('vue-router', () => ({
  useRouter: () => ({
    beforeEach: (guard: NavigationGuard) => {
      registeredGuard = guard
    },
  }),
  useRoute: () => ({ path: '/dashboard/overview', query: {} }),
  RouterView: {
    template: '<div><slot :Component="{ template: \'<div>Page</div>\' }" :route="{ path: \'/dashboard/overview\' }" /></div>',
  },
}))

vi.mock('@/app/layouts/AdminLayout.vue', () => ({
  default: { template: '<div><slot /></div>' },
}))

describe('App', () => {
  it('registers navigation guard and applies transitions only between details and parent list', () => {
    mount(App)
    expect(registeredGuard).toBeTypeOf('function')

    registeredGuard!(
      { path: '/users/riders', name: 'users-riders' },
      { path: '/users/drivers', name: 'users-drivers' },
    )

    registeredGuard!(
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
      { path: '/users/driver-applications', name: 'users-driver-applications' },
    )

    registeredGuard!(
      { path: '/users/driver-applications', name: 'users-driver-applications' },
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
    )

    registeredGuard!(
      { path: '/users/riders', name: 'users-riders' },
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
    )
  })
})
