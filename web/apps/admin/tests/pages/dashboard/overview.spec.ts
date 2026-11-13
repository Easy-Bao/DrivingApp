import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import OverviewPage from '@/pages/dashboard/overview.vue'

describe('OverviewPage', () => {
  it('renders executive KPIs, animated charts, paginated dispatches, and trip details modal', async () => {
    const wrapper = mount(OverviewPage)

    expect(wrapper.text()).toContain('Overview')
    expect(wrapper.text()).toContain('Active Rides')
    expect(wrapper.text()).toContain('Online Drivers')
    expect(wrapper.text()).toContain('Trip Revenue')
    expect(wrapper.text()).toContain('Completion Rate')
    expect(wrapper.text()).toContain('Trip Volume & Revenue Trend')
    expect(wrapper.text()).toContain('Dispatch Breakdown')
    expect(wrapper.text()).toContain('Breakdown by booking mode and dispatch outcome')
    expect(wrapper.text()).toContain('Open Broadcast')
    expect(wrapper.text()).toContain('Chosen Driver')
    expect(wrapper.text()).toContain('Route')
    expect(wrapper.text()).toContain('Trip Fare')
    expect(wrapper.text()).toContain('Action')
    expect(wrapper.text()).toContain('7016…18921')
    expect(wrapper.text()).toContain('Peak Window: 15–18')

    const inlineCopyBtn = wrapper.find('button[aria-label="Copy Booking ID 701629644618921"]')
    expect(inlineCopyBtn.exists()).toBe(true)
    await inlineCopyBtn.trigger('click')
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('701629644618921')
    expect(wrapper.text()).toContain('Copied Booking ID')

    const tripsMetricBtn = wrapper.findAll('button').find((button) => button.text() === 'Trips')
    const tripFareBtn = wrapper.findAll('button').find((button) => button.text() === 'Trip Fare')
    expect(tripsMetricBtn?.attributes('aria-pressed')).toBe('true')
    expect(tripFareBtn?.attributes('aria-pressed')).toBe('false')

    const sevenDayBtn = wrapper.findAll('button').find((button) => button.text() === '7 Days')
    expect(sevenDayBtn).toBeDefined()
    await sevenDayBtn!.trigger('click')
    expect(sevenDayBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('Total Trips')
    expect(wrapper.text()).toContain('5,420')
    expect(wrapper.text()).toContain('65%')
    expect(wrapper.text()).toContain('95.8%')
    expect(wrapper.text()).toContain('2.1%')
    expect(wrapper.text()).toContain('Peak Window: Fri')

    await tripFareBtn!.trigger('click')
    expect(tripFareBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('Peak Window: Sat')
    expect(
      wrapper.find('svg[aria-label="Trip volume and fare revenue chart"] text').text(),
    ).toContain('₱')

    const thirtyDayBtn = wrapper.findAll('button').find((button) => button.text() === '30 Days')
    expect(thirtyDayBtn).toBeDefined()
    await thirtyDayBtn!.trigger('click')
    expect(thirtyDayBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('22,840')
    expect(wrapper.text()).toContain('62%')
    expect(
      wrapper.findAll('svg[aria-label="Trip volume and fare revenue chart"] rect').length,
    ).toBe(4)

    const nextPageBtn = wrapper.find('button[aria-label="Page 2"]')
    expect(nextPageBtn.exists()).toBe(true)
    await nextPageBtn.trigger('click')
    expect(wrapper.text()).toContain('7016…18916')

    const detailsBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('View Details'))
    expect(detailsBtn).toBeDefined()
    await detailsBtn!.trigger('click')
    expect(wrapper.text()).toContain('Trip Details')
    expect(wrapper.text()).toContain('Booking ID: 701629644618916')
  })
})
