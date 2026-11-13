import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RolesPage from '@/pages/users/roles.vue'

describe('RolesPage', () => {
  it('creates a new custom role with selected permissions', async () => {
    const wrapper = mount(RolesPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: true,
        },
      },
    })

    const createTrigger = wrapper.findAll('button').find((b) => b.text().includes('+ Create Role'))
    expect(createTrigger).toBeDefined()
    await createTrigger!.trigger('click')

    const inputs = wrapper.findAll('input[type="text"]')
    expect(inputs.length).toBeGreaterThanOrEqual(2)
    await inputs[0]!.setValue('Night Shift Dispatch')
    await inputs[1]!.setValue('Handles evening terminal queues.')

    await wrapper.find('form').trigger('submit')

    expect(wrapper.text()).toContain('Night Shift Dispatch')
    expect(wrapper.text()).toContain('Created role "Night Shift Dispatch".')
  })

  it('opens permission editor for an existing role and saves changes', async () => {
    const wrapper = mount(RolesPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: true,
        },
      },
    })

    const editBtn = wrapper.findAll('button').find((b) => b.text().includes('Edit Permissions'))
    expect(editBtn).toBeDefined()
    await editBtn!.trigger('click')

    expect(wrapper.text()).toContain('Edit Role Permissions')

    const titleInput = wrapper.find('input[type="text"]')
    await titleInput.setValue('Root Lead')

    await wrapper.find('form').trigger('submit')
    expect(wrapper.text()).toContain('Root Lead')
    expect(wrapper.text()).toContain('Updated permissions for Root Lead.')
  })
})
