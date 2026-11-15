import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import ContentPage from '@/pages/settings/content.vue'

describe('settings/content page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('displays seeded policies and enforces non-empty title/body when publishing', async () => {
    const wrapper = mount(ContentPage)

    expect(wrapper.text()).toContain('DOC-TOS-PH')
    expect(wrapper.text()).toContain('v2.1')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Edit Policy'))!
      .trigger('click')

    await wrapper.find('#policy-title').setValue('')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Publish Revision'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').text()).toContain('required')

    await wrapper.find('#policy-title').setValue('Passenger Terms of Service (2026 Q4)')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Publish Revision'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Passenger Terms of Service (2026 Q4)')
    expect(wrapper.text()).toContain('v2.2')
    expect(wrapper.text()).toContain('Published DOC-TOS-PH v2.2')
  })
})
