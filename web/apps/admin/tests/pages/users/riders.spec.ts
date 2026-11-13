import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RidersPage from '@/pages/users/riders.vue'

describe('RidersPage', () => {
  it('filters Pagadian passengers and opens inspection modal', async () => {
    const wrapper = mount(RidersPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: true,
        },
      },
    })

    expect(wrapper.text()).toContain('Althea Mae Villanueva')
    expect(wrapper.text()).toContain('+63 935 812 4091')

    const search = wrapper.find('input[type="text"]')
    await search.setValue('Mark Anthony')
    expect(wrapper.text()).toContain('Mark Anthony Reyes')
    expect(wrapper.text()).not.toContain('Althea Mae Villanueva')

    const inspectBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Inspect')
    expect(inspectBtn).toBeDefined()
    await inspectBtn!.trigger('click')

    expect(wrapper.text()).toContain('Trust & Safety Notes')
    expect(wrapper.text()).toContain('Santiago District')
  })

  it('suspends a passenger with mandatory audit reason', async () => {
    const wrapper = mount(RidersPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: true,
        },
      },
    })

    const suspendBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Suspend')
    expect(suspendBtn).toBeDefined()
    await suspendBtn!.trigger('click')

    const reasonBox = wrapper.find('textarea')
    await reasonBox.setValue('Confirmed repeated cash settlement dispute.')

    const confirmBtn = wrapper.findAll('button').find((b) => b.text().includes('Suspend Passenger'))
    expect(confirmBtn).toBeDefined()
    await confirmBtn!.trigger('click')

    expect(wrapper.text()).toContain('Althea Mae Villanueva suspended from booking new rides.')
  })
})
