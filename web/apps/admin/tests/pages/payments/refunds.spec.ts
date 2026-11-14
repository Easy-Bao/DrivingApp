import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import RefundsPage from '@/pages/payments/refunds.vue'

describe('payments/refunds page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('approves a pending rebate claim with mandatory audit note', async () => {
    const wrapper = mount(RefundsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('2 Pending Review')
    expect(wrapper.text()).toContain('ADJ-7016-501')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve & Credit'))!
      .trigger('click')

    await wrapper.find('textarea').setValue('Confirmed drop-off shortfall via GPS trace.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve Credit'))!
      .trigger('click')

    expect(wrapper.text()).toContain('ADJ-7016-501 marked Approved & Credited')
    expect(wrapper.text()).toContain('1 Pending Review')
    expect(logs.value[0]?.action).toBe('REFUND_CLAIM_APPROVED')
  })
})
