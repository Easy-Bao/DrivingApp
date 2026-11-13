import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import SosAlertsPage from '@/features/trips/pages/SosAlertsPage.vue'

describe('SosAlertsPage', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('displays actual incident counts, filters status tabs, and auto-dismisses action toasts', async () => {
    const wrapper = mount(SosAlertsPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('2 Active')
    expect(wrapper.text()).toContain('All (3)')
    expect(wrapper.text()).toContain('Active (2)')
    expect(wrapper.text()).toContain('Resolved (1)')

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
})
