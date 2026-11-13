import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import SegmentedToggle from '@/shared/forms/SegmentedToggle.vue'

describe('SegmentedToggle', () => {
  it('renders options with aria-pressed state and emits model updates on selection', async () => {
    const wrapper = mount(SegmentedToggle, {
      props: {
        modelValue: 'today',
        ariaLabel: 'Select reporting window',
        options: [
          { label: 'Today', value: 'today' },
          { label: '7 Days', value: '7d' },
          { label: '30 Days', value: '30d' },
        ],
      },
    })

    const buttons = wrapper.findAll('button')
    expect(buttons).toHaveLength(3)
    expect(buttons[0]!.attributes('aria-pressed')).toBe('true')
    expect(buttons[1]!.attributes('aria-pressed')).toBe('false')

    await buttons[1]!.trigger('click')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['7d'])
  })
})
