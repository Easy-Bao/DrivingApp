import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import AppSettingsPage from '@/pages/settings/app-settings.vue'

describe('settings/app-settings page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('binds rating bonus threshold dynamically and updates low-balance description', async () => {
    const wrapper = mount(AppSettingsPage)

    expect(wrapper.text()).toContain('4.5★ Rating Bonus Factor')
    expect(wrapper.text()).toContain('below ₱50.00')

    await wrapper.find('#rating-bonus-threshold').setValue('4.8')
    await wrapper.find('#min-wallet-balance').setValue('75')

    expect(wrapper.text()).toContain('4.8★ Rating Bonus Factor')
    expect(wrapper.text()).toContain('below ₱75.00')
  })

  it('blocks saving when numeric settings exceed allowed platform bounds', async () => {
    const wrapper = mount(AppSettingsPage)

    await wrapper.find('#bidding-window-seconds').setValue('15')
    await wrapper.find('#save-runtime-config').trigger('click')

    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('between 30 and 300')
  })

  it('commits configuration with mandatory audit reason and appends audit log entry', async () => {
    const wrapper = mount(AppSettingsPage)
    const { config } = usePlatformConfig()
    const { logs } = useAuditLogs()

    await wrapper.find('#min-wallet-balance').setValue('80')
    await wrapper.find('#save-runtime-config').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)

    await dialog.find('textarea').setValue('Aligning minimum commission balance with fuel costs.')
    const confirmBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Runtime Settings'))
    expect(confirmBtn).toBeDefined()
    await confirmBtn!.trigger('click')

    expect(config.value.minWalletBalanceCentavos).toBe(8000)
    expect(wrapper.text()).toContain('Saved Pagadian runtime configuration')
    expect(logs.value[0]?.action).toBe('RUNTIME_CONFIG_UPDATED')
  })

  it('restores default values when Reset Defaults is clicked', async () => {
    const wrapper = mount(AppSettingsPage)

    await wrapper.find('#min-wallet-balance').setValue('120')
    expect(wrapper.text()).toContain('below ₱120.00')

    await wrapper.find('#reset-runtime-defaults').trigger('click')
    expect(wrapper.text()).toContain('below ₱50.00')
  })
})
