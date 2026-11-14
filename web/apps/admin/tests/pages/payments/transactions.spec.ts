import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetPaymentsForTesting } from '@/features/payments'
import TransactionsPage from '@/pages/payments/transactions.vue'

describe('payments/transactions page', () => {
  beforeEach(() => {
    resetPaymentsForTesting()
  })

  it('aligns ledger TOP-8921 with ₱500.00 and supports type filter & CSV export', async () => {
    const wrapper = mount(TransactionsPage)

    expect(wrapper.text()).toContain('TXN-7016-9400')
    expect(wrapper.text()).toContain('+₱500.00')

    await wrapper.find('input[aria-label="Search wallet ledger transactions"]').setValue('9401')
    expect(wrapper.text()).toContain('TRP-7016-8921')
    expect(wrapper.text()).not.toContain('TOP-8921')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Export CSV'))!
      .trigger('click')
    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)
  })
})
