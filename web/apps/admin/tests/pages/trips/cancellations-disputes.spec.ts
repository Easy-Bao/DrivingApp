import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import { resetTripsForTesting } from '@/features/trips'
import CancellationsDisputesPage from '@/pages/trips/cancellations-disputes.vue'

describe('CancellationsDisputesPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  it('requires investigation reason before resolving a disputed fee waiver', async () => {
    const wrapper = mount(CancellationsDisputesPage)

    expect(wrapper.text()).toContain('CAN-7016-301')
    expect(wrapper.text()).toContain('Under Review')

    const reviewBtn = wrapper.findAll('button').find((b) => b.text().trim() === 'Review')
    expect(reviewBtn).toBeDefined()
    await reviewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Responsibility Override')

    const findSaveBtn = () =>
      wrapper.findAll('button').find((b) => b.text().includes('Save Determination'))
    expect(findSaveBtn()).toBeDefined()
    expect(findSaveBtn()!.attributes('disabled')).toBeDefined()

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Telemetry shows 7-minute traffic standstill near Agora junction.')
    expect(findSaveBtn()!.attributes('disabled')).toBeUndefined()

    await wrapper.find('form').trigger('submit.prevent')
    expect(wrapper.text()).toContain('Fee Waived & Overridden')
    expect(wrapper.text()).toContain('₱0.00')
  })
})
