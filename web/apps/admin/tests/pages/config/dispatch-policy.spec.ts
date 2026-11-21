import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import {
  resetSettingsForTesting,
  useAuditLogs,
  useDispatchPolicy,
  usePlatformConfig,
} from '@/features/settings'
import DispatchPolicyPage from '@/pages/config/dispatch-policy.vue'

describe('config/dispatch-policy page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('validates dispatch and telemetry bounds and commits updates with audit trail', async () => {
    const wrapper = mount(DispatchPolicyPage)
    const { policy } = useDispatchPolicy()
    const { config } = usePlatformConfig()
    const { logs } = useAuditLogs()

    await wrapper.find('#bidding-window-seconds').setValue('15')
    await wrapper.find('#save-dispatch-policy').trigger('click')
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('between 30 and 300')

    await wrapper.find('#bidding-window-seconds').setValue('60')
    await wrapper.find('#passenger-noshow-wait').setValue('8')
    await wrapper.find('#arrival-radius-meters').setValue('300')
    await wrapper.find('#save-dispatch-policy').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('textarea').setValue('Aligned geofence and wait times with field test.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Dispatch Policy'))!
      .trigger('click')

    expect(policy.value.biddingWindowSeconds).toBe(60)
    expect(config.value.biddingWindowSeconds).toBe(60)
    expect(policy.value.passengerNoShowWaitMinutes).toBe(8)
    expect(policy.value.arrivalRadiusMeters).toBe(300)
    expect(logs.value[0]?.action).toBe('DISPATCH_POLICY_UPDATED')

    await wrapper.find('#reset-dispatch-defaults').trigger('click')
    expect(policy.value.biddingWindowSeconds).toBe(90)
  })
})
