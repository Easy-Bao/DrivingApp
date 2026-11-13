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
    expect(wrapper.text()).toContain('Payments')
    expect(wrapper.text()).toContain('Reports')
  })

  it('filters navigation items based on search query', async () => {
    const wrapper = mount(Sidebar)
    const searchInput = wrapper.find('input[type="text"]')
    expect(searchInput.exists()).toBe(true)

    await searchInput.setValue('Top-Ups')
    expect(wrapper.text()).toContain('Top-Ups')
  })

  it('toggles collapse state, uses dark pulse indicators, and shows hover flyout dropdown', async () => {
    const wrapper = mount(Sidebar, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })
    expect(wrapper.classes()).toContain('w-72')

    const toggleButton = wrapper.find('button[aria-label="Collapse sidebar"]')
    expect(toggleButton.exists()).toBe(true)

    await toggleButton.trigger('click')
    expect(wrapper.classes()).toContain('w-20')

    const expandButton = wrapper.find('button[aria-label="Expand sidebar"]')
    expect(expandButton.find('[data-test="collapsed-brand-logo"]').exists()).toBe(true)
    await expandButton.trigger('mouseenter')
    expect(expandButton.find('[data-test="collapsed-brand-logo"]').exists()).toBe(false)
    expect(expandButton.find('[data-test="sidebar-toggle-icon"]').exists()).toBe(true)

    const countBadges = wrapper.findAll('[data-test="collapsed-notif-count"]')
    expect(countBadges.length).toBeGreaterThan(0)
    const badgeTexts = countBadges.map((badge) => badge.text())
    expect(badgeTexts).toContain('2')
    for (const badge of countBadges) {
      expect(badge.classes()).not.toContain('animate-pulse')
      expect(badge.classes()).not.toContain('bg-neutral-500')
    }

    const dashboardBtn = wrapper.find('button[aria-label="Dashboard"]')
    await dashboardBtn.trigger('mouseenter')
    const dashboardFlyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(dashboardFlyout.exists()).toBe(true)
    const activeMenuItem = dashboardFlyout.find('[aria-current="page"]')
    expect(activeMenuItem.exists()).toBe(true)
    expect(activeMenuItem.text()).toContain('Overview')
    expect(activeMenuItem.classes()).toContain('bg-neutral-900')

    const tripsBtn = wrapper.find('button[aria-label="Trips"]')
    await tripsBtn.trigger('mouseenter')
    const flyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(flyout.exists()).toBe(true)
    expect(flyout.text()).toContain('Trips')
    expect(flyout.text()).toContain('SOS Alerts')
    expect(flyout.text()).toContain('Live Bidding')

    const profileBtn = wrapper.find('button[aria-label="Profile"]')
    await profileBtn.trigger('mouseenter')
    const profileFlyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(profileFlyout.exists()).toBe(true)
    expect(profileFlyout.text()).toContain('Profile')
    expect(profileFlyout.text()).toContain('Lock Session')

    const lockOption = profileFlyout
      .findAll('button[role="menuitem"]')
      .find((btn) => btn.text().includes('Lock Session'))
    expect(lockOption).toBeDefined()
    await lockOption!.trigger('click')
    expect(wrapper.text()).toContain('Lock Session?')
  })

  it('renders line indent border on expanded child groups', () => {
    const wrapper = mount(Sidebar)
    const childContainers = wrapper.findAll('.border-l')
    expect(childContainers.length).toBeGreaterThan(0)
    const firstContainer = childContainers[0]
    expect(firstContainer).toBeDefined()
    expect(firstContainer?.classes()).toContain('border-neutral-200')
    expect(firstContainer?.classes()).toContain('ml-4')
  })

  it('shows empty search message, allows clearing, and confirms sign out', async () => {
    const wrapper = mount(Sidebar, {
      global: {
        stubs: {
          Teleport: true,
        },
      },
    })
    const searchInput = wrapper.find('input[type="text"]')

    await searchInput.setValue('nonexistent-xyz-section')
    expect(wrapper.text()).toContain('No matching sections for "nonexistent-xyz-section"')

    const clearBtn = wrapper.find('button[aria-label="Clear navigation filter"]')
    expect(clearBtn.exists()).toBe(true)
    await clearBtn.trigger('click')
    expect(wrapper.text()).toContain('Dashboard')

    const lockBtn = wrapper.find('button[aria-label="Lock session"]')
    await lockBtn.trigger('click')
    expect(wrapper.text()).toContain('Lock Session?')
  })
})
