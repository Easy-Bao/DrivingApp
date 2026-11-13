import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import OverviewPage from '@/pages/dashboard/overview.vue'

describe('OverviewPage', () => {
  it('renders executive KPIs, animated charts, paginated dispatches, and trip details modal', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    })

    const wrapper = mount(OverviewPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

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
    expect(wrapper.text()).not.toContain('Single-type 3-wheeled Bao-Bao')
    expect(wrapper.text()).not.toContain('Standard TukTuk')
    expect(wrapper.text()).not.toContain('Express Bao-Bao')
    expect(wrapper.text()).not.toContain('E-BaoBao Pioneer')
    expect(wrapper.text()).toContain('Route')
    expect(wrapper.text()).toContain('Trip Fare')
    expect(wrapper.text()).toContain('Action')
    expect(wrapper.text()).toContain('7016…18921')
    expect(wrapper.text()).toContain('Peak Window: 15–18')
    expect(wrapper.text()).not.toContain('Route (Pagadian)')
    expect(wrapper.text()).not.toContain('Agreed Fare')
    expect(wrapper.text()).not.toContain('Pending Top-Ups')
    expect(wrapper.text()).not.toContain('Settlement Reviews')

    // Inline Booking ID copy triggers full 15-digit clipboard copy
    const inlineCopyBtn = wrapper.find('button[aria-label="Copy Booking ID 701629644618921"]')
    expect(inlineCopyBtn.exists()).toBe(true)
    await inlineCopyBtn.trigger('click')
    expect(writeText).toHaveBeenCalledWith('701629644618921')
    expect(wrapper.text()).toContain('Copied Booking ID')

    // Switch metric between Trips and Trip Fare on the volume chart
    const tripsMetricBtn = wrapper.findAll('button').find((button) => button.text() === 'Trips')
    const tripFareBtn = wrapper.findAll('button').find((button) => button.text() === 'Trip Fare')
    expect(tripsMetricBtn?.attributes('aria-pressed')).toBe('true')
    expect(tripFareBtn?.attributes('aria-pressed')).toBe('false')

    // Switch timeframe to 7 Days and verify KPI labels + exact 100.0% outcome shares update
    const sevenDayBtn = wrapper.findAll('button').find((button) => button.text() === '7 Days')
    expect(sevenDayBtn).toBeDefined()
    await sevenDayBtn!.trigger('click')
    expect(sevenDayBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('Total Trips')
    expect(wrapper.text()).not.toContain('Completed & Active Trips')
    expect(wrapper.text()).not.toContain('Period Trip Revenue')
    expect(wrapper.text()).toContain('5,420')
    expect(wrapper.text()).toContain('65%')
    expect(wrapper.text()).toContain('95.8%')
    expect(wrapper.text()).toContain('2.1%')
    expect(wrapper.text()).toContain('Peak Window: Fri')

    // Toggle Trip Fare in 7 Days and confirm peak shifts dynamically + currency axis labels render
    await tripFareBtn!.trigger('click')
    expect(tripFareBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('Peak Window: Sat')
    expect(
      wrapper.find('svg[aria-label="Trip volume and fare revenue chart"] text').text(),
    ).toContain('₱')

    // Switch to 30 Days and verify chart SVG elements remain rendered
    const thirtyDayBtn = wrapper.findAll('button').find((button) => button.text() === '30 Days')
    expect(thirtyDayBtn).toBeDefined()
    await thirtyDayBtn!.trigger('click')
    expect(thirtyDayBtn!.attributes('aria-pressed')).toBe('true')
    expect(wrapper.text()).toContain('22,840')
    expect(wrapper.text()).toContain('62%')
    expect(
      wrapper.findAll('svg[aria-label="Trip volume and fare revenue chart"] rect').length,
    ).toBe(4)

    // Paginate dispatches and open Trip Details modal
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
