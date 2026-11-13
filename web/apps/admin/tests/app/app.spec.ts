import { nextTick, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import App from '@/App.vue'

type NavigationGuard = (
  to: {
    path: string
    name?: string
    params?: Record<string, string>
    meta?: Record<string, unknown>
  },
  from: {
    path: string
    name?: string
    params?: Record<string, string>
    meta?: Record<string, unknown>
  },
) => void

let registeredGuard: NavigationGuard | null = null

const mockCurrentRoute = reactive<{
  path: string
  query: Record<string, unknown>
  meta: Record<string, unknown>
}>({
  path: '/dashboard/overview',
  query: {},
  meta: {},
})

vi.mock('vue-router', () => ({
  useRouter: () => ({
    beforeEach: (guard: NavigationGuard) => {
      registeredGuard = guard
    },
  }),
  useRoute: () => mockCurrentRoute,
  RouterView: {
    template:
      '<div data-test="router-view"><slot :Component="{ template: \'<div data-test=page>Page</div>\' }" :route="{ path: \'/dashboard/overview\' }" /></div>',
  },
}))

vi.mock('@/app/layouts/ConsoleLayout.vue', () => ({
  default: { template: '<div data-test="console-layout"><slot /></div>' },
}))

const TransitionStub = {
  name: 'Transition',
  props: ['name', 'css', 'mode'],
  template:
    '<div data-test="route-transition" :data-name="name" :data-css="String(css)" :data-mode="mode ?? \'\'"><slot /></div>',
}

describe('App', () => {
  beforeEach(() => {
    registeredGuard = null
    mockCurrentRoute.path = '/dashboard/overview'
    mockCurrentRoute.query = {}
    mockCurrentRoute.meta = {}
  })

  it('registers navigation guard and applies slide transitions only between details and parent list', async () => {
    const wrapper = mount(App, {
      global: {
        stubs: {
          Transition: TransitionStub,
        },
      },
    })
    expect(registeredGuard).toBeTypeOf('function')
    expect(wrapper.find('[data-test="console-layout"]').exists()).toBe(true)

    const transitionEl = () => wrapper.find('[data-test="route-transition"]')
    expect(transitionEl().attributes('data-name')).toBe('')
    expect(transitionEl().attributes('data-css')).toBe('false')

    registeredGuard!(
      { path: '/users/riders', name: 'users-riders' },
      { path: '/users/drivers', name: 'users-drivers' },
    )
    await nextTick()
    expect(transitionEl().attributes('data-name')).toBe('')
    expect(transitionEl().attributes('data-css')).toBe('false')
    expect(transitionEl().attributes('data-mode')).toBe('')

    registeredGuard!(
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
      { path: '/users/driver-applications', name: 'users-driver-applications' },
    )
    await nextTick()
    expect(transitionEl().attributes('data-name')).toBe('slide-left')
    expect(transitionEl().attributes('data-css')).toBe('true')
    expect(transitionEl().attributes('data-mode')).toBe('out-in')

    registeredGuard!(
      { path: '/users/driver-applications', name: 'users-driver-applications' },
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
    )
    await nextTick()
    expect(transitionEl().attributes('data-name')).toBe('slide-right')
    expect(transitionEl().attributes('data-css')).toBe('true')
    expect(transitionEl().attributes('data-mode')).toBe('out-in')

    registeredGuard!(
      { path: '/users/riders', name: 'users-riders' },
      {
        path: '/users/driver-applications/APP-901',
        name: 'users-driver-application-details',
        params: { id: 'APP-901' },
        meta: { isDetail: true },
      },
    )
    await nextTick()
    expect(transitionEl().attributes('data-name')).toBe('')
    expect(transitionEl().attributes('data-css')).toBe('false')
    expect(transitionEl().attributes('data-mode')).toBe('')
  })

  it('omits ConsoleLayout when route meta.hideChrome is true', () => {
    mockCurrentRoute.meta = { hideChrome: true }
    const wrapper = mount(App)
    expect(wrapper.find('[data-test="console-layout"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="page"]').exists()).toBe(true)
  })
})
