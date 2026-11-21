import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import VehicleClassesPage from '@/pages/config/vehicle-classes.vue'

describe('config/vehicle-classes page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('lists seeded Bao-Bao classes, creates a new class, and toggles active status', async () => {
    const wrapper = mount(VehicleClassesPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('Standard Bao-Bao')
    expect(wrapper.text()).toContain('Electric Bao-Bao (Eco)')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Vehicle Class'))!
      .trigger('click')

    await wrapper.find('#vc-name').setValue('Cargo Bao-Bao Utility')
    await wrapper.find('#vc-code').setValue('BAO-CRG')
    await wrapper.find('#vc-description').setValue('Market goods and parcel utility carrier.')
    await wrapper.find('#vc-capacity').setValue('2')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Vehicle Class'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Cargo Bao-Bao Utility')
    expect(wrapper.text()).toContain('BAO-CRG')
    expect(logs.value[0]?.action).toBe('VEHICLE_CLASS_CREATED')

    const pauseBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Pause')
    expect(pauseBtn).toBeDefined()
    await pauseBtn!.trigger('click')
    expect(wrapper.text()).toContain('Paused')
    expect(logs.value[0]?.action).toBe('VEHICLE_CLASS_TOGGLED')
  })
})
