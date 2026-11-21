import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAppSystemConfig, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import AppSystemPage from '@/pages/config/app-system.vue'

describe('config/app-system page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('renders independent configuration directory links and validates app version format', async () => {
    const wrapper = mount(AppSystemPage)

    expect(wrapper.text()).toContain('Fare Configuration')
    expect(wrapper.text()).toContain('Wallet & Top-Up Rules')
    expect(wrapper.text()).toContain('Dispatch & Ride Policy')
    expect(wrapper.text()).toContain('Safety & SOS Config')

    await wrapper.find('#passenger-min-version').setValue('invalid')
    await wrapper.find('#save-system-config').trigger('click')

    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('semantic versioning')
  })

  it('commits maintenance mode and app release gates with mandatory audit trail and supports reset', async () => {
    const wrapper = mount(AppSystemPage)
    const { systemConfig } = useAppSystemConfig()
    const { logs } = useAuditLogs()

    await wrapper.find('#driver-min-version').setValue('1.5.0')
    await wrapper.find('input[aria-label="Platform Maintenance Mode"]').setValue(true)
    await wrapper.find('#save-system-config').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)

    await dialog.find('textarea').setValue('Deploying driver telemetry update.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply System Config'))!
      .trigger('click')

    expect(systemConfig.value.driverMinVersion).toBe('1.5.0')
    expect(systemConfig.value.maintenanceMode).toBe(true)
    expect(wrapper.text()).toContain('Maintenance Active')
    expect(logs.value[0]?.action).toBe('APP_SYSTEM_CONFIG_UPDATED')

    await wrapper.find('#reset-system-defaults').trigger('click')
    expect(systemConfig.value.maintenanceMode).toBe(false)
    expect(wrapper.text()).toContain('Normal Operation')
  })
})
