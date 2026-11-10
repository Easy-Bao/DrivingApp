import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AdminSidebar from '@/shared/components/AdminSidebar.vue'

describe('AdminSidebar', () => {
  it('renders all core admin navigation sections and items', () => {
    const wrapper = mount(AdminSidebar)

    // Verify main brand
    expect(wrapper.text()).toContain('EasyRide')

    // Verify key categories exist
    expect(wrapper.text()).toContain('Dashboard')
    expect(wrapper.text()).toContain('Users')
    expect(wrapper.text()).toContain('Vehicle')
    expect(wrapper.text()).toContain('Documents')
    expect(wrapper.text()).toContain('Trips')
    expect(wrapper.text()).toContain('Payment')
    expect(wrapper.text()).toContain('Reports')
    expect(wrapper.text()).toContain('Support')
    expect(wrapper.text()).toContain('Settings')

    // Verify specific critical operational items
    expect(wrapper.text()).toContain('Overview')
    expect(wrapper.text()).toContain('Drivers')
    expect(wrapper.text()).toContain('SOS Alerts')
  })

  it('filters navigation items based on search query', async () => {
    const wrapper = mount(AdminSidebar)
    const searchInput = wrapper.find('input[type="text"]')
    expect(searchInput.exists()).toBe(true)

    // Search for "Refunds"
    await searchInput.setValue('Refunds')

    expect(wrapper.text()).toContain('Refunds')
    expect(wrapper.text()).not.toContain('Lost & Found')
  })

  it('toggles collapse state when clicking collapse button', async () => {
    const wrapper = mount(AdminSidebar)
    expect(wrapper.classes()).toContain('w-72')

    const toggleButton = wrapper.find('button[aria-label="Collapse sidebar"]')
    expect(toggleButton.exists()).toBe(true)

    await toggleButton.trigger('click')
    expect(wrapper.classes()).toContain('w-20')
  })

  it('updates active item when clicking a navigation link', async () => {
    const wrapper = mount(AdminSidebar)
    const tripButton = wrapper.findAll('nav button').find((b) => b.text().includes('Drivers'))

    expect(tripButton).toBeDefined()
    await tripButton!.trigger('click')

    expect(tripButton!.classes()).toContain('bg-neutral-900')
    expect(tripButton!.classes()).toContain('text-white')
  })
})
