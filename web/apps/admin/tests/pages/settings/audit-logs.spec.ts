import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import AuditLogsPage from '@/pages/admin/audit-logs.vue'

describe('settings/audit-logs page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('displays canonical operators and filters logs cleanly with inspect modal & CSV export', async () => {
    const wrapper = mount(AuditLogsPage)

    expect(wrapper.text()).toContain('AUD-7016-8904')
    expect(wrapper.text()).toContain('TOP-8921 (Rodelio Cruz · +₱500.00)')
    expect(wrapper.text()).toContain('Clarisse Mendoza')

    await wrapper.find('input[aria-label="Search audit logs"]').setValue('SUSPENDED')
    expect(wrapper.text()).toContain('AUD-7016-8903')
    expect(wrapper.text()).not.toContain('AUD-7016-8904')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Inspect Payload'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').text()).toContain('DRIVER_SUSPENDED')

    await wrapper.find('input[aria-label="Search audit logs"]').setValue('')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Export CSV'))!
      .trigger('click')

    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)
  })
})
