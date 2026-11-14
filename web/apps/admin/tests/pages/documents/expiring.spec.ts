import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetDocumentsForTesting } from '@/features/documents'
import ExpiringDocumentsPage from '@/pages/documents/expiring.vue'

describe('documents/expiring page', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-11-13T10:00:00Z'))
    resetSettingsForTesting()
    resetDocumentsForTesting()
  })

  it('sends individual renewal SMS reminders and logs audit trail', async () => {
    const wrapper = mount(ExpiringDocumentsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('EXP-101')

    const smsBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Send SMS')
    expect(smsBtn).toBeDefined()
    await smsBtn!.trigger('click')

    expect(wrapper.text()).toContain('Renewal SMS sent')
    expect(logs.value[0]?.action).toBe('EXPIRY_REMINDER_SENT')
  })

  it('broadcasts reminders to critical expiry queue when Notify Critical is clicked', async () => {
    const wrapper = mount(ExpiringDocumentsPage)
    const { logs } = useAuditLogs()

    const broadcastBtn = wrapper.findAll('button').find((b) => b.text().includes('Notify Critical'))
    expect(broadcastBtn).toBeDefined()
    await broadcastBtn!.trigger('click')

    expect(wrapper.text()).toContain('Renewal SMS sent to')
    expect(logs.value[0]?.action).toBe('EXPIRY_REMINDER_BROADCAST')
  })
})
