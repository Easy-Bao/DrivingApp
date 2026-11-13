import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import AllTripsPage from '@/pages/trips/all.vue'

describe('AllTripsPage', () => {
  it('filters trips, opens Trip Details modal without redundant labels, and copies Booking ID', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    })

    const wrapper = mount(AllTripsPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Althea Mae Villanueva')
    expect(wrapper.text()).toContain('Brgy. San Jose, Pagadian City')
    expect(wrapper.text()).not.toContain('Cash + Tip')

    expect(wrapper.text()).toContain('Action')

    const search = wrapper.find('input[type="text"]')
    await search.setValue('Reynaldo')
    expect(wrapper.text()).toContain('7016…18919')
    expect(wrapper.text()).not.toContain('7016…18921')

    const inlineCopyBtn = wrapper.find('button[aria-label="Copy Booking ID 701629644618919"]')
    expect(inlineCopyBtn.exists()).toBe(true)
    await inlineCopyBtn.trigger('click')
    expect(writeText).toHaveBeenCalledWith('701629644618919')

    const viewBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('View Details'))
    expect(viewBtn).toBeDefined()
    await viewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Trip Details')
    expect(wrapper.text()).toContain('Booking ID: 701629644618919')
    expect(wrapper.text()).toContain('Pick Up')
    expect(wrapper.text()).toContain('Drop Off')
    expect(wrapper.text()).not.toContain('Dropoff Destination')
    expect(wrapper.text()).not.toContain('(Cash)')
    expect(wrapper.text()).toContain('Zamboanga del Sur Medical Center, Dao')

    const copyBtn = wrapper.find('button[aria-label="Copy Booking ID"]')
    expect(copyBtn.exists()).toBe(true)
    await copyBtn.trigger('click')
    expect(writeText).toHaveBeenCalledWith('701629644618919')
    expect(wrapper.text()).toContain('Copied Booking ID')
  })
})
