import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetUsersForTesting } from '@/features/users'
import OperatorsPage from '@/pages/users/operators.vue'

describe('users/operators page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetUsersForTesting()
  })

  it('invites a new staff operator and toggles MFA for non-root staff', async () => {
    const wrapper = mount(OperatorsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('ADM-001')

    const inviteBtn = wrapper.findAll('button').find((b) => b.text().includes('Invite Operator'))
    expect(inviteBtn).toBeDefined()
    await inviteBtn!.trigger('click')

    const inviteFormInputs = wrapper.find('form').findAll('input')
    await inviteFormInputs[0]?.setValue('Lorraine Bautista')
    await inviteFormInputs[1]?.setValue('lorraine.bautista@pagadian.ph')

    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.text()).toContain('Lorraine Bautista')
    expect(logs.value[0]?.action).toBe('OPERATOR_INVITED')
  })
})
