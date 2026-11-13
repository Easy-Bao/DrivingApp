import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AllTripsPage from '@/pages/trips/all.vue'

describe('AllTripsPage', () => {
  it('filters trips, opens Trip Details modal, and copies Booking ID', async () => {
    const wrapper = mount(AllTripsPage)

    expect(wrapper.text()).toContain('Althea Mae Villanueva')
    expect(wrapper.text()).toContain('Brgy. San Jose, Pagadian City')
    expect(wrapper.text()).toContain('Action')

    const search = wrapper.find('input[type="text"]')
    await search.setValue('Reynaldo')
    expect(wrapper.text()).toContain('7016…18919')
    expect(wrapper.text()).not.toContain('7016…18921')

    const inlineCopyBtn = wrapper.find('button[aria-label="Copy Booking ID 701629644618919"]')
    expect(inlineCopyBtn.exists()).toBe(true)
    await inlineCopyBtn.trigger('click')
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('701629644618919')

    const viewBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('View Details'))
    expect(viewBtn).toBeDefined()
    await viewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Trip Details')
    expect(wrapper.text()).toContain('Booking ID: 701629644618919')
    expect(wrapper.text()).toContain('Pick Up')
    expect(wrapper.text()).toContain('Drop Off')
    expect(wrapper.text()).toContain('Zamboanga del Sur Medical Center, Dao')

    const copyBtn = wrapper.find('button[aria-label="Copy Booking ID"]')
    expect(copyBtn.exists()).toBe(true)
    await copyBtn.trigger('click')
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('701629644618919')
    expect(wrapper.text()).toContain('Copied Booking ID')
  })
})
