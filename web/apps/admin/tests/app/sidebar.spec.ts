import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Sidebar from '@/app/layouts/Sidebar.vue'
import { loginOperator } from '@/core/auth/auth-session'
import { resetDocumentsForTesting } from '@/features/documents'
import { resetPaymentsForTesting } from '@/features/payments'
import { resetSettingsForTesting } from '@/features/settings'
import { resetSupportForTesting, useSupportTickets } from '@/features/support'
import { resetTripsForTesting, useSosAlerts } from '@/features/trips'
import { resetUsersForTesting } from '@/features/users'

const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/dashboard/overview', query: {} }),
  useRouter: () => ({ push: mockPush }),
}))

describe('Sidebar', () => {
  beforeEach(() => {
    mockPush.mockClear()
    resetSettingsForTesting()
    resetUsersForTesting()
    resetDocumentsForTesting()
    resetPaymentsForTesting()
    resetTripsForTesting()
    resetSupportForTesting()
  })

  it('renders branding, pinned Overview, and separated Operations, Configuration, and Administration sections', () => {
    const wrapper = mount(Sidebar)
    expect(wrapper.text()).toContain('EasyRide')
    expect(wrapper.text()).toContain('Overview')
    expect(wrapper.text()).toContain('Operations')
    expect(wrapper.text()).toContain('Configuration')
    expect(wrapper.text()).toContain('Administration')
    expect(wrapper.text()).toContain('Users & Fleet')
    expect(wrapper.text()).toContain('Trips & Safety')
    expect(wrapper.text()).toContain('Finance')
    expect(wrapper.text()).toContain('Pricing & Billing')
    expect(wrapper.text()).toContain('Fare Configuration')
    expect(wrapper.text()).toContain('Dispatch & Coverage')
    expect(wrapper.text()).toContain('Fleet & Safety')
    expect(wrapper.text()).toContain('Content & System')
    expect(wrapper.text()).toContain('Access & Audit')
  })

  it('filters navigation items by label, section, and configuration keywords', async () => {
    const wrapper = mount(Sidebar)
    const searchInput = wrapper.find('input[type="text"]')
    expect(searchInput.exists()).toBe(true)

    await searchInput.setValue('Top-Ups')
    expect(wrapper.text()).toContain('Top-Ups')
    expect(wrapper.text()).toContain('Finance')

    await searchInput.setValue('surge')
    expect(wrapper.text()).toContain('Fare Configuration')
    expect(wrapper.text()).toContain('Service Zones')

    await searchInput.setValue('no-show')
    expect(wrapper.text()).toContain('Dispatch & Ride Policy')
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

    const overviewBtn = wrapper.find('button[aria-label="Overview"]')
    expect(overviewBtn.attributes('aria-current')).toBe('page')
    await overviewBtn.trigger('mouseenter')
    const overviewTooltip = wrapper.find('[data-test="collapsed-tooltip"]')
    expect(overviewTooltip.exists()).toBe(true)
    expect(overviewTooltip.text()).toContain('Overview')

    const tripsBtn = wrapper.find('button[aria-label="Trips & Safety"]')
    await tripsBtn.trigger('mouseenter')
    const flyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(flyout.exists()).toBe(true)
    expect(flyout.text()).toContain('Trips & Safety')
    expect(flyout.text()).toContain('SOS Alerts')
    expect(flyout.text()).toContain('Live Bidding')

    const pricingBtn = wrapper.find('button[aria-label="Pricing & Billing"]')
    await pricingBtn.trigger('mouseenter')
    const pricingFlyout = wrapper.find('[data-test="collapsed-flyout"]')
    expect(pricingFlyout.text()).toContain('Fare Configuration')
    expect(pricingFlyout.text()).toContain('Wallet & Top-Up Rules')

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

  it('navigates when pinned Overview or independent config item is clicked and supports expand-all toggle', async () => {
    const wrapper = mount(Sidebar)
    const overviewBtn = wrapper.findAll('button').find((btn) => btn.text().trim() === 'Overview')
    expect(overviewBtn).toBeDefined()

    await overviewBtn!.trigger('click')
    expect(mockPush).toHaveBeenCalledWith('/dashboard/overview')

    const fareBtn = wrapper
      .findAll('button')
      .find((btn) => btn.text().trim() === 'Fare Configuration')
    expect(fareBtn).toBeDefined()
    await fareBtn!.trigger('click')
    expect(mockPush).toHaveBeenCalledWith('/config/fare-pricing')

    const expandAllBtn = wrapper.find('button[aria-label="Expand all navigation groups"]')
    expect(expandAllBtn.exists()).toBe(true)
    await expandAllBtn.trigger('click')
    expect(wrapper.text()).toContain('Audit Logs')
    expect(wrapper.text()).toContain('Vehicle Classes')
  })

  it('shows empty search message, allows clearing, and confirms sign out', async () => {
    const wrapper = mount(Sidebar)
    const searchInput = wrapper.find('input[type="text"]')

    await searchInput.setValue('nonexistent-xyz-section')
    expect(wrapper.text()).toContain('No matching sections for "nonexistent-xyz-section"')

    const clearBtn = wrapper.find('button[aria-label="Clear navigation filter"]')
    expect(clearBtn.exists()).toBe(true)
    await clearBtn.trigger('click')
    expect(wrapper.text()).toContain('Overview')

    const lockBtn = wrapper.find('button[aria-label="Lock session"]')
    await lockBtn.trigger('click')
    expect(wrapper.text()).toContain('Lock Session?')
  })

  it('hides navigation groups and configuration modules unauthorized for the signed-in role', async () => {
    loginOperator('finance', '7016')
    const wrapper = mount(Sidebar)

    expect(wrapper.text()).toContain('Finance')
    expect(wrapper.text()).toContain('Pricing & Billing')
    expect(wrapper.text()).toContain('Fare Configuration')
    expect(wrapper.text()).toContain('Wallet & Top-Up Rules')
    expect(wrapper.text()).toContain('Reports')
    expect(wrapper.text()).not.toContain('Administration')
    expect(wrapper.text()).not.toContain('Access & Audit')
    expect(wrapper.text()).not.toContain('Dispatch & Coverage')
    expect(wrapper.text()).not.toContain('Compliance')

    loginOperator('support', '7016')
    const supportWrapper = mount(Sidebar)
    const expandAll = supportWrapper.find('button[aria-label="Expand all navigation groups"]')
    await expandAll.trigger('click')

    expect(supportWrapper.text()).toContain('Tickets')
    expect(supportWrapper.text()).toContain('Safety Reports')
    expect(supportWrapper.text()).toContain('Refunds')
    expect(supportWrapper.text()).toContain('Safety & SOS Config')
    expect(supportWrapper.text()).toContain('Help Center')
    expect(supportWrapper.text()).not.toContain('Top-Ups')
    expect(supportWrapper.text()).not.toContain('Cities & Markets')
    expect(supportWrapper.text()).not.toContain('App & System')
  })

  it('reactively updates sidebar notification badges when underlying operational stores change', async () => {
    const wrapper = mount(Sidebar)
    const { resolveAlert } = useSosAlerts()

    const tripsToggle = wrapper
      .findAll('button')
      .find((btn) => btn.text().includes('Trips & Safety'))
    expect(tripsToggle).toBeDefined()
    expect(tripsToggle!.find('[data-test="folded-group-notif-count"]').text()).toBe('2')
    await tripsToggle!.trigger('click')

    const sosItemBefore = wrapper.findAll('button').find((btn) => btn.text().includes('SOS Alerts'))
    expect(sosItemBefore?.text()).toContain('2')

    expect(resolveAlert('SOS-7016-104', 'Resolved by dispatch').ok).toBe(true)
    await wrapper.vm.$nextTick()

    const sosItemAfter = wrapper.findAll('button').find((btn) => btn.text().includes('SOS Alerts'))
    expect(sosItemAfter?.text()).toContain('1')

    const { replyToTicket } = useSupportTickets()
    const supportToggle = wrapper.findAll('button').find((btn) => btn.text().includes('Support'))
    await supportToggle?.trigger('click')

    const ticketsBefore = wrapper.findAll('button').find((btn) => btn.text().includes('Tickets'))
    expect(ticketsBefore?.text()).toContain('3')

    expect(
      replyToTicket('TCK-7016-204', {
        status: 'Resolved',
        reply: 'Approved QRPh deposit and unlocked dispatch.',
      }).ok,
    ).toBe(true)
    await wrapper.vm.$nextTick()

    const ticketsAfter = wrapper.findAll('button').find((btn) => btn.text().includes('Tickets'))
    expect(ticketsAfter?.text()).toContain('2')
  })
})
