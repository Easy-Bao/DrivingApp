import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import DocumentRulesPage from '@/pages/config/document-rules.vue'

describe('config/document-rules page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('commits document gate policy and supports adding new compliance checklist rules', async () => {
    const wrapper = mount(DocumentRulesPage)
    const { config } = usePlatformConfig()
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('DOC-RULE-LTO')
    expect(wrapper.text()).toContain('DOC-RULE-MTOP')

    await wrapper.find('#doc-warning-days').setValue('45')
    await wrapper.find('input[aria-label="Enforce LTO and TODA Document Gate"]').setValue(false)
    await wrapper.find('#save-compliance-policy').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('textarea').setValue('Extended renewal lead notice for Q4.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Gate Policy'))!
      .trigger('click')

    expect(config.value.enforceDocumentGate).toBe(false)
    expect(logs.value[0]?.action).toBe('COMPLIANCE_POLICY_UPDATED')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Document Rule'))!
      .trigger('click')
    await wrapper.find('#doc-rule-name').setValue('Barangay Residency Certificate')
    await wrapper.find('#doc-rule-authority').setValue('Pagadian Barangay Hall')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Document Rule'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Barangay Residency Certificate')
    expect(logs.value[0]?.action).toBe('DOCUMENT_RULE_CREATED')
  })
})
