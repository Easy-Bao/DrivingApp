import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetTripsForTesting } from '@/features/trips'
import SafetySosPage from '@/pages/config/safety-sos.vue'
import SosAlertsPage from '@/pages/trips/sos-alerts.vue'

describe('config/safety-sos page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  it('saves SOS escalation settings and syncs primary emergency hotline to live SOS Alerts page', async () => {
    const wrapper = mount(SafetySosPage)
    const { logs } = useAuditLogs()

    await wrapper.find('#sos-auto-escalate').setValue('45')
    await wrapper.find('#save-safety-policy').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('textarea').setValue('Tightened SOS escalation timer for night ops.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Safety Policy'))!
      .trigger('click')

    expect(logs.value[0]?.action).toBe('SAFETY_POLICY_UPDATED')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Hotline'))!
      .trigger('click')
    await wrapper.find('#hotline-label').setValue('ZDS Quick Response')
    await wrapper.find('#hotline-agency').setValue('Zamboanga del Sur PDRRMO')
    await wrapper.find('#hotline-phone').setValue('062-999-0911')

    const modalCheckboxes = wrapper.find('[role="dialog"]').findAll('input[type="checkbox"]')
    await modalCheckboxes[0]!.setValue(true)
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Hotline'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Primary: ZDS Quick Response (062-999-0911)')
    expect(logs.value[0]?.action).toBe('EMERGENCY_HOTLINE_CREATED')

    const sosAlertsWrapper = mount(SosAlertsPage)
    expect(sosAlertsWrapper.text()).toContain('ZDS Quick Response (062-999-0911)')
  })
})
