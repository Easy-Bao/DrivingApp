import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RolesPage from '@/pages/users/roles.vue'

describe('RolesPage', () => {
  it('creates a new custom role with selected permissions', async () => {
    const wrapper = mount(RolesPage)

    const createTrigger = wrapper.findAll('button').find((b) => b.text().includes('+ Create Role'))
    expect(createTrigger).toBeDefined()
    await createTrigger!.trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('input[placeholder*="Dispatch Reviewer"]').setValue('Night Shift Dispatch')
    await dialog
      .find('input[placeholder*="Role responsibilities"]')
      .setValue('Handles evening terminal queues.')

    await dialog.find('form').trigger('submit')

    expect(wrapper.text()).toContain('Night Shift Dispatch')
    expect(wrapper.text()).toContain('Created role "Night Shift Dispatch".')
  })

  it('opens permission editor for an existing role and saves changes', async () => {
    const wrapper = mount(RolesPage)

    const editBtn = wrapper.findAll('button').find((b) => b.text().includes('Edit Permissions'))
    expect(editBtn).toBeDefined()
    await editBtn!.trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.text()).toContain('Edit Role Permissions')

    await dialog.find('input[placeholder*="Dispatch Reviewer"]').setValue('Root Lead')

    await dialog.find('form').trigger('submit')
    expect(wrapper.text()).toContain('Root Lead')
    expect(wrapper.text()).toContain('Updated permissions for Root Lead.')
  })
})
