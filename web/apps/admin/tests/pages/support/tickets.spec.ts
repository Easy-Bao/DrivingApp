import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetSupportForTesting } from '@/features/support'
import TicketsPage from '@/pages/support/tickets.vue'

describe('TicketsPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetSupportForTesting()
  })

  it('opens the support thread modal and resolves a Pagadian inquiry with an operator reply', async () => {
    const wrapper = mount(TicketsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('TCK-7016-204')
    expect(wrapper.text()).toContain('Rodelio Cruz')
    expect(wrapper.text()).toContain('3 Active Inquiries')

    const inspectBtn = wrapper.findAll('button').find((b) => b.text().includes('Inspect & Reply'))
    expect(inspectBtn).toBeDefined()
    await inspectBtn!.trigger('click')

    expect(wrapper.text()).toContain('Support Ticket Thread · TCK-7016-204')

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Approved QRPh deposit QR-8829104; dispatch unlocked.')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Send Reply & Save'))
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('TCK-7016-204 updated (Resolved) with operator reply.')
    expect(wrapper.text()).toContain('2 Active Inquiries')
    expect(logs.value[0]!.action).toBe('SUPPORT_TICKET_UPDATED')
  })
})
