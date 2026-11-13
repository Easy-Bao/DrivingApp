import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import OverviewPage from '@/pages/dashboard/overview.vue'

describe('OverviewPage', () => {
  it('renders executive KPIs, charts, paginated dispatches, and trip details modal', async () => {
    const wrapper = mount(OverviewPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Operations Overview')
    expect(wrapper.text()).toContain('Active Rides')
    expect(wrapper.text()).toContain('Online Drivers')
    expect(wrapper.text()).toContain('Today Trip Revenue')
    expect(wrapper.text()).toContain('Completion Rate')
    expect(wrapper.text()).toContain('Trip Volume & Revenue Trend')
    expect(wrapper.text()).toContain('Fleet Mix & Status')
    expect(wrapper.text()).toContain('Route')
    expect(wrapper.text()).toContain('Trip Fare')
    expect(wrapper.text()).not.toContain('Route (Pagadian)')
    expect(wrapper.text()).not.toContain('Agreed Fare')
    expect(wrapper.text()).not.toContain('Pending Top-Ups')
    expect(wrapper.text()).not.toContain('Settlement Reviews')

    const sevenDayBtn = wrapper.findAll('button').find((button) => button.text() === '7 Days')
    expect(sevenDayBtn).toBeDefined()
    await sevenDayBtn!.trigger('click')
    expect(wrapper.text()).toContain('5,420')

    const nextPageBtn = wrapper.find('button[aria-label="Page 2"]')
    expect(nextPageBtn.exists()).toBe(true)
    await nextPageBtn.trigger('click')
    expect(wrapper.text()).toContain('701629644618916')

    const detailsBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('View Details'))
    expect(detailsBtn).toBeDefined()
    await detailsBtn!.trigger('click')
    expect(wrapper.text()).toContain('Trip Details')
    expect(wrapper.text()).toContain('Booking ID: 701629644618916')
  })
})
