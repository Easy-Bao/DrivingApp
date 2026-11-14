import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import { resetTripsForTesting } from '@/features/trips'
import DispatchPage from '@/pages/trips/dispatch.vue'

describe('DispatchPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  it('adjusts zone surge multiplier and assigns driver to unassigned dispatch', async () => {
    const wrapper = mount(DispatchPage)

    expect(wrapper.text()).toContain('Agora Market - Poblacion Core')
    expect(wrapper.text()).toContain('DSP-7016-883')

    const adjustBtn = wrapper.findAll('button').find((b) => b.text().includes('Adjust'))
    expect(adjustBtn).toBeDefined()
    await adjustBtn!.trigger('click')

    const surgeTrigger = wrapper.find('button[aria-label="Select surge zone multiplier"]')
    expect(surgeTrigger.exists()).toBe(true)
    await surgeTrigger.trigger('click')

    const opt16 = wrapper.findAll('[role="option"]').find((o) => o.text().includes('1.6x'))
    expect(opt16).toBeDefined()
    await opt16!.trigger('click')

    await wrapper.find('form').trigger('submit.prevent')
    expect(wrapper.text()).toContain('1.6x')

    const assignBtn = wrapper.findAll('button').find((b) => b.text().includes('Assign Driver'))
    expect(assignBtn).toBeDefined()
    await assignBtn!.trigger('click')

    expect(wrapper.text()).toContain('Manual Dispatch · DSP-7016-883')
    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.text()).toContain('Manually dispatched')
  })
})
