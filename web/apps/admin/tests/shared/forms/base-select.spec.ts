import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import BaseSelect from '@/shared/forms/BaseSelect.vue'

describe('BaseSelect', () => {
  it('opens the listbox menu and updates the selected value on option click', async () => {
    const wrapper = mount(BaseSelect, {
      props: {
        modelValue: 'All',
        ariaLabel: 'Filter by payment method',
        options: [
          { label: 'All Payment Methods', value: 'All' },
          { label: 'Company QR Code', value: 'Company QR Code' },
          { label: 'Company Bank Transfer', value: 'Company Bank Transfer' },
        ],
      },
    })

    const trigger = wrapper.find('button[role="combobox"]')
    expect(trigger.attributes('aria-expanded')).toBe('false')
    expect(trigger.text()).toContain('All Payment Methods')

    await trigger.trigger('click')

    expect(trigger.attributes('aria-expanded')).toBe('true')
    const listbox = wrapper.find('[role="listbox"]')
    expect(listbox.exists()).toBe(true)

    const options = wrapper.findAll('[role="option"]')
    expect(options).toHaveLength(3)
    expect(options[0]!.attributes('aria-selected')).toBe('true')
    expect(options[1]!.attributes('aria-selected')).toBe('false')

    await options[1]!.trigger('click')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['Company QR Code'])
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
  })

  it('prevents opening the menu when disabled', async () => {
    const wrapper = mount(BaseSelect, {
      props: {
        modelValue: 'Operations Director',
        disabled: true,
        options: ['Operations Director', 'Dispatch & Safety Supervisor'],
      },
    })

    const trigger = wrapper.find('button[role="combobox"]')
    expect(trigger.attributes('disabled')).toBeDefined()

    await trigger.trigger('click')
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
  })
})
