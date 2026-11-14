import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import { resetUsersForTesting } from '@/features/users'
import DriversPage from '@/pages/users/drivers.vue'

describe('users/drivers page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetUsersForTesting()
  })

  it('reflects live platform wallet minimum, formats centavos, and suspends driver with reason', async () => {
    const { config, commitConfig } = usePlatformConfig()
    commitConfig(
      { ...config.value, minWalletBalanceCentavos: 20000 },
      'Increase fleet wallet threshold for dispatch test.',
    )

    const wrapper = mount(DriversPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('Rodelio Cruz')
    expect(wrapper.text()).toContain('₱420.50')
    expect(wrapper.text()).toContain('Danilo Mendoza')
    expect(wrapper.text()).toContain('₱185.00')
    expect(wrapper.text()).toContain('Low Balance (Locked)')

    const suspendBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Suspend')
    expect(suspendBtn).toBeDefined()
    await suspendBtn!.trigger('click')

    await wrapper.find('textarea').setValue('Failed random vehicle compliance audit.')
    const confirmBtn = wrapper.findAll('button').find((b) => b.text().includes('Suspend Driver'))
    expect(confirmBtn).toBeDefined()
    await confirmBtn!.trigger('click')

    expect(wrapper.text()).toContain('Rodelio Cruz suspended from receiving new dispatches.')
    expect(logs.value[0]?.action).toBe('DRIVER_SUSPENDED')
  })
})
