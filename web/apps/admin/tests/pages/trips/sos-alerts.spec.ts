import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import { resetTripsForTesting } from '@/features/trips'
import SosAlertsPage from '@/pages/trips/sos-alerts.vue'

describe('SosAlertsPage', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('displays actual incident counts, filters status tabs, and auto-dismisses action toasts', async () => {
    const wrapper = mount(SosAlertsPage)

    expect(wrapper.text()).toContain('2 Active')
    expect(wrapper.text()).toContain('All (3)')
    expect(wrapper.text()).toContain('Active (2)')
    expect(wrapper.text()).toContain('Resolved (1)')
    expect(wrapper.text()).toContain('Call Passenger')
    expect(wrapper.text()).toContain('Passenger: +63 917 842 9103')

    const resolvedTab = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Resolved (1)'))
    await resolvedTab?.trigger('click')
    expect(wrapper.text()).toContain('SOS-7016-102')
    expect(wrapper.text()).not.toContain('SOS-7016-104')

    const callButton = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Call Driver'))
    await callButton?.trigger('click')
    expect(wrapper.text()).toContain('Calling Driver · +63 917 773 8810')

    vi.advanceTimersByTime(3500)
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).not.toContain('Calling Driver · +63 917 773 8810')
  })

  it('opens geolocation container modal on View Map and copies coordinates', async () => {
    const wrapper = mount(SosAlertsPage)

    const viewMapBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('View Map'))
    expect(viewMapBtn).toBeDefined()
    await viewMapBtn!.trigger('click')

    expect(wrapper.text()).toContain('SOS-7016-104')
    expect(wrapper.text()).toContain('Live Map')
    expect(wrapper.text()).toContain('7.8257° N, 123.4370° E')

    const copyCoordsBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Copy Coordinates'))
    expect(copyCoordsBtn).toBeDefined()
    await copyCoordsBtn!.trigger('click')
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('7.8257, 123.4370')
  })
})
