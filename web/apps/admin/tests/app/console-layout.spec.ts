import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { reactive } from 'vue'
import ConsoleLayout from '@/app/layouts/ConsoleLayout.vue'

const mockRoute = reactive({
  path: '/dashboard/overview',
  params: {} as Record<string, string>,
})

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
  RouterLink: {
    props: ['to'],
    template: "<a :href=\"typeof to === 'string' ? to : ''\"><slot /></a>",
  },
}))

describe('ConsoleLayout', () => {
  beforeEach(() => {
    mockRoute.path = '/dashboard/overview'
    mockRoute.params = {}
  })

  function mountLayout() {
    return mount(ConsoleLayout, {
      global: {
        stubs: {
          Sidebar: { template: '<aside />' },
          Icon: { template: '<span />' },
          RouterLink: {
            props: ['to'],
            template: '<a :href="String(to)"><slot /></a>',
          },
        },
      },
      slots: {
        default: '<div>Page Content</div>',
      },
    })
  }

  it('renders standard two-level breadcrumbs for collection pages', () => {
    mockRoute.path = '/payments/topups'
    const wrapper = mountLayout()
    const nav = wrapper.find('nav[aria-label="Breadcrumb"]')

    expect(nav.exists()).toBe(true)
    expect(nav.text()).toContain('Payments')
    expect(nav.text()).toContain('Top-Ups')
    expect(nav.find('[aria-current="page"]').text()).toBe('Top-Ups')
  })

  it('nests detail record breadcrumbs under their clickable parent collection', () => {
    mockRoute.path = '/payments/topups/TOP-8921'
    mockRoute.params = { id: 'TOP-8921' }
    const wrapper = mountLayout()
    const nav = wrapper.find('nav[aria-label="Breadcrumb"]')

    const links = nav
      .findAll('a')
      .map((anchor) => ({ text: anchor.text().trim(), href: anchor.attributes('href') }))
    expect(links).toContainEqual({ text: 'Payments', href: '/payments/topups' })
    expect(links).toContainEqual({ text: 'Top-Ups', href: '/payments/topups' })
    expect(nav.find('[aria-current="page"]').text()).toBe('#TOP-8921')
  })

  it('nests settlement and driver application detail routes consistently', () => {
    mockRoute.path = '/users/driver-applications/APP-901'
    mockRoute.params = { id: 'APP-901' }
    const wrapper = mountLayout()
    const nav = wrapper.find('nav[aria-label="Breadcrumb"]')

    const links = nav
      .findAll('a')
      .map((anchor) => ({ text: anchor.text().trim(), href: anchor.attributes('href') }))
    expect(links).toContainEqual({ text: 'Users', href: '/users/drivers' })
    expect(links).toContainEqual({
      text: 'Driver Applications',
      href: '/users/driver-applications',
    })
    expect(nav.find('[aria-current="page"]').text()).toBe('#APP-901')
  })
})
