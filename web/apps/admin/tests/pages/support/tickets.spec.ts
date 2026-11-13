import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import TicketsPage from '@/pages/support/tickets.vue'

describe('TicketsPage', () => {
  it('opens the support thread modal and resolves a Pagadian inquiry with an operator reply', async () => {
    const wrapper = mount(TicketsPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('TCK-7016-204')
    expect(wrapper.text()).toContain('Rodelio Cruz')

    const inspectBtn = wrapper.findAll('button').find((b) => b.text().includes('Inspect & Reply'))
    expect(inspectBtn).toBeDefined()
    await inspectBtn!.trigger('click')

    expect(wrapper.text()).toContain('Support Ticket Thread · TCK-7016-204')

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Approved QRPh deposit QR-8829104; dispatch unlocked.')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Send Reply & Save'))
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('TCK-7016-204 updated (Resolved) with operator reply.')
  })
})
