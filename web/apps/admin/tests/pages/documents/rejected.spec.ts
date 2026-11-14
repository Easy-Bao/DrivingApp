import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetDocumentsForTesting, useVerificationDocuments } from '@/features/documents'
import RejectedDocumentsPage from '@/pages/documents/rejected.vue'

describe('documents/rejected page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetDocumentsForTesting()
  })

  it('inspects rejected items and re-opens them into the live verification queue', async () => {
    const wrapper = mount(RejectedDocumentsPage)
    const { pendingDocs } = useVerificationDocuments()
    const { logs } = useAuditLogs()
    const initialPending = pendingDocs.value.length

    expect(wrapper.text()).toContain('REJ-401')

    const inspectBtn = wrapper.findAll('button').find((b) => b.text().includes('Inspect'))
    expect(inspectBtn).toBeDefined()
    await inspectBtn!.trigger('click')

    const reopenBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Re-Open for Verification'))
    expect(reopenBtn).toBeDefined()
    await reopenBtn!.trigger('click')

    expect(wrapper.text()).toContain('moved back to active verification queue.')
    expect(pendingDocs.value).toHaveLength(initialPending + 1)
    expect(logs.value[0]?.action).toBe('DOCUMENT_REOPENED')
  })
})
