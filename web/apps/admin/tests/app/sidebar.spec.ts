import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Sidebar from '@/app/layouts/Sidebar.vue'
import { loginOperator } from '@/core/auth/auth-session'

const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/dashboard/overview', query: {} }),
  useRouter: () => ({ push: mockPush }),
}))

describe('Sidebar', () => {
  beforeEach(() => {
    mockPush.mockClear()
  })
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

  it('toggles collapse state, displays notification counts, and shows hover flyout dropdown', async () => {
    const wrapper = mount(Sidebar)

    const toggleButton = wrapper.find('button[aria-label="Collapse sidebar"]')
    expect(toggleButton.exists()).toBe(true)

    await toggleButton.trigger('click')

    const expandButton = wrapper.find('button[aria-label="Expand sidebar"]')
    expect(expandButton.exists()).toBe(true)
    expect(expandButton.find('[data-test="collapsed-brand-logo"]').exists()).toBe(true)
    await expandButton.trigger('mouseenter')
    expect(expandButton.find('[data-test="collapsed-brand-logo"]').exists()).toBe(false)
    expect(expandButton.find('[data-test="sidebar-toggle-icon"]').exists()).toBe(true)

    const countBadges = wrapper.findAll('[data-test="collapsed-notif-count"]')
    expect(countBadges.length).toBeGreaterThan(0)
    const badgeTexts = countBadges.map((badge) => badge.text())
    expect(badgeTexts).toContain('2')

    const dashboardBtn = wrapper.find('button[aria-label="Dashboard"]')
    await dashboardBtn.trigger('mouseenter')
    const dashboardFlyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(dashboardFlyout.exists()).toBe(true)
    const activeMenuItem = dashboardFlyout.find('[aria-current="page"]')
    expect(activeMenuItem.exists()).toBe(true)
    expect(activeMenuItem.text()).toContain('Overview')

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

  it('renders expanded child items and navigates when a section item is clicked', async () => {
    const wrapper = mount(Sidebar)
    const overviewBtn = wrapper.findAll('button').find((btn) => btn.text().trim() === 'Overview')
    expect(overviewBtn).toBeDefined()

    await overviewBtn!.trigger('click')
    expect(mockPush).toHaveBeenCalledWith('/dashboard/overview')
  })

  it('shows empty search message, allows clearing, and confirms sign out', async () => {
    const wrapper = mount(Sidebar)
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

  it('hides navigation groups and items unauthorized for the signed-in role', async () => {
    loginOperator('finance_ops', '7016')
    const wrapper = mount(Sidebar)

    expect(wrapper.text()).toContain('Payments')
    expect(wrapper.text()).toContain('Reports')
    expect(wrapper.text()).not.toContain('Operators')
    expect(wrapper.text()).not.toContain('Staff Roles')
    expect(wrapper.text()).not.toContain('App Settings')
    expect(wrapper.text()).not.toContain('Verification')

    loginOperator('support_lead', '7016')
    const supportWrapper = mount(Sidebar)
    const supportToggle = supportWrapper
      .findAll('button')
      .find((btn) => btn.text().trim() === 'Support')
    expect(supportToggle).toBeDefined()
    await supportToggle!.trigger('click')

    expect(supportWrapper.text()).toContain('Tickets')
    expect(supportWrapper.text()).toContain('Safety Reports')
    expect(supportWrapper.text()).toContain('Refunds')
    expect(supportWrapper.text()).not.toContain('Top-Ups')
    expect(supportWrapper.text()).not.toContain('Cities')
  })
})
