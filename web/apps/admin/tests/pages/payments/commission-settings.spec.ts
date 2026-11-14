import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import CommissionSettingsPage from '@/pages/payments/commission-settings.vue'

describe('payments/commission-settings page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('validates commission basis points and saves updated tier rules', async () => {
    const wrapper = mount(CommissionSettingsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('1500 bps')
    expect(wrapper.text()).toContain('15%')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Configure Rate & Threshold'))!
      .trigger('click')

    await wrapper.find('#commission-bps').setValue('50')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Commission Config'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').text()).toContain('between 100 bps')

    await wrapper.find('#commission-bps').setValue('1400')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Commission Config'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Updated Standard Fleet to 14% (1400 bps)')
    expect(wrapper.text()).toContain('1400 bps')
    expect(logs.value[0]?.action).toBe('COMMISSION_TIER_UPDATED')
  })
})
