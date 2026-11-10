import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Sidebar from '@/app/layouts/Sidebar.vue'

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/dashboard/overview', query: {} }),
  useRouter: () => ({ push: vi.fn() }),
  RouterLink: { template: '<a><slot /></a>' },
}))

describe('Sidebar', () => {
  it('renders branding and core navigation sections', () => {
    const wrapper = mount(Sidebar)
    expect(wrapper.text()).toContain('EasyRide')
    expect(wrapper.text()).toContain('Dashboard')
    expect(wrapper.text()).toContain('Users')
    expect(wrapper.text()).toContain('Trips')
    expect(wrapper.text()).toContain('Payment & Wallet')
    expect(wrapper.text()).toContain('Reports')
  })

  it('filters navigation items based on search query', async () => {
    const wrapper = mount(Sidebar)
    const searchInput = wrapper.find('input[type="text"]')
    expect(searchInput.exists()).toBe(true)

    await searchInput.setValue('Top-Ups')
    expect(wrapper.text()).toContain('Driver Top-Ups')
  })

  it('toggles collapse state without layout overflow', async () => {
    const wrapper = mount(Sidebar)
    expect(wrapper.classes()).toContain('w-72')

    const toggleButton = wrapper.find('button[aria-label="Collapse sidebar"]')
    expect(toggleButton.exists()).toBe(true)

    await toggleButton.trigger('click')
    expect(wrapper.classes()).toContain('w-20')
  })
})
