import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import { resetPaymentsForTesting, useWalletTransactions } from '@/features/payments'
import WalletPage from '@/pages/payments/wallet.vue'

describe('payments/wallet page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('tracks live platform minimum dispatch balance and credits driver wallet with audit trail', async () => {
    const { config, commitConfig } = usePlatformConfig()
    commitConfig(
      { ...config.value, minWalletBalanceCentavos: 20000 },
      'Increase prepaid reserve test threshold.',
    )

    const wrapper = mount(WalletPage)
    const { transactions } = useWalletTransactions()
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('₱200.00 dispatch threshold')
    expect(wrapper.text()).toContain('Dispatch Locked (< ₱200.00 min)')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Adjust Credit'))!
      .trigger('click')

    await wrapper.find('#wallet-adjustment-amount').setValue('200')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Continue to Audit Note'))!
      .trigger('click')

    await wrapper.find('textarea').setValue('Operator reserve bonus credit.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Adjustment'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Credited ₱200.00 for Rodelio Cruz')
    expect(wrapper.text()).toContain('₱218.50')
    expect(transactions.value[0]?.amountCentavos).toBe(20000)
    expect(logs.value[0]?.action).toBe('WALLET_ADJUSTED')
  })

  it('exports CSV rows using canonical threshold', async () => {
    const wrapper = mount(WalletPage)
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Export CSV'))!
      .trigger('click')
    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)
  })
})
