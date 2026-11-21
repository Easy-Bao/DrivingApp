import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import WalletRulesPage from '@/pages/config/wallet-rules.vue'
import WalletPage from '@/pages/payments/wallet.vue'

describe('config/wallet-rules page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('validates thresholds, saves wallet rules with audit trail, and syncs live into Wallets', async () => {
    const wrapper = mount(WalletRulesPage)
    const { config } = usePlatformConfig()
    const { logs } = useAuditLogs()

    await wrapper.find('#wallet-min-dispatch').setValue('200')
    await wrapper.find('#wallet-low-warning').setValue('50')
    await wrapper.find('#save-wallet-policy').trigger('click')
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('greater than or equal to the minimum dispatch balance')

    await wrapper.find('#wallet-low-warning').setValue('250')
    await wrapper.find('#wallet-min-topup').setValue('100')
    await wrapper.find('#save-wallet-policy').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('textarea').setValue('Adjusted Pagadian prepaid reserve and top-up step.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Wallet Rules'))!
      .trigger('click')

    expect(config.value.minWalletBalanceCentavos).toBe(20000)
    expect(logs.value[0]?.action).toBe('WALLET_POLICY_UPDATED')

    const walletPage = mount(WalletPage)
    expect(walletPage.text()).toContain('₱200.00 dispatch threshold')
    expect(walletPage.text()).toContain('₱100.00')
  })

  it('restores default wallet thresholds cleanly', async () => {
    const wrapper = mount(WalletRulesPage)
    await wrapper.find('#wallet-min-dispatch').setValue('150')
    expect(wrapper.text()).toContain('below ₱150.00')

    await wrapper.find('#reset-wallet-defaults').trigger('click')
    expect(wrapper.text()).toContain('below ₱50.00')
  })
})
