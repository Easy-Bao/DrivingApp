import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import SafetyReportsPage from '@/features/trips/pages/SafetyReportsPage.vue'

describe('SafetyReportsPage', () => {
  it('filters safety reports by severity and saves a moderation disposition', async () => {
    const wrapper = mount(SafetyReportsPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('RPT-7016-409')
    expect(wrapper.text()).toContain('Driver Identity Mismatch')

    const severitySelect = wrapper.findAll('select')[0]!
    await severitySelect.setValue('standard')
    expect(wrapper.text()).toContain('RPT-7016-407')
    expect(wrapper.text()).not.toContain('RPT-7016-409')

    await severitySelect.setValue('all')
    const reviewBtn = wrapper.findAll('button').find((b) => b.text().includes('Review & Moderate'))
    expect(reviewBtn).toBeDefined()
    await reviewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Safety Report Moderation · RPT-7016-409')

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Driver verified at TODA hub; temporary flag cleared after ID check.')
    const modalSelect = wrapper.findAll('select')[2]!
    await modalSelect.setValue('resolved')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Save Decision'))
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('RPT-7016-409 updated to Resolved.')
  })
})
