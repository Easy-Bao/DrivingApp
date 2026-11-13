import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import SafetyReportsPage from '@/pages/trips/safety-reports.vue'

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

    const severityTrigger = wrapper.find('button[aria-label="Filter safety reports by severity"]')
    await severityTrigger.trigger('click')
    const standardOption = wrapper
      .findAll('[role="option"]')
      .find((opt) => opt.text().includes('Standard'))
    expect(standardOption).toBeDefined()
    await standardOption!.trigger('click')
    expect(wrapper.text()).toContain('RPT-7016-407')
    expect(wrapper.text()).not.toContain('RPT-7016-409')

    await severityTrigger.trigger('click')
    const allOption = wrapper
      .findAll('[role="option"]')
      .find((opt) => opt.text().includes('All Severities'))
    expect(allOption).toBeDefined()
    await allOption!.trigger('click')
    const reviewBtn = wrapper.findAll('button').find((b) => b.text().includes('Review & Moderate'))
    expect(reviewBtn).toBeDefined()
    await reviewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Safety Report Moderation · RPT-7016-409')

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Driver verified at TODA hub; temporary flag cleared after ID check.')
    const modalTrigger = wrapper.find('button[aria-label="Updated moderation status"]')
    await modalTrigger.trigger('click')
    const resolvedOption = wrapper
      .findAll('[role="option"]')
      .find((opt) => opt.text().includes('Resolved & Action Taken'))
    expect(resolvedOption).toBeDefined()
    await resolvedOption!.trigger('click')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Save Decision'))
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('RPT-7016-409 updated to Resolved.')
  })
})
