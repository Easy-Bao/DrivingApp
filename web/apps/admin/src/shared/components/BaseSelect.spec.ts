import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import BaseSelect from '@/shared/components/BaseSelect.vue'

describe('BaseSelect', () => {
  it('opens a light square dropdown menu with no border radius and updates the selected value', async () => {
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
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    const trigger = wrapper.find('button[role="combobox"]')
    expect(trigger.classes()).toContain('rounded-none')
    expect(trigger.classes()).toContain('bg-white')
    expect(trigger.text()).toContain('All Payment Methods')

    await trigger.trigger('click')

    const listbox = wrapper.find('[role="listbox"]')
    expect(listbox.exists()).toBe(true)
    expect(listbox.classes()).toContain('rounded-none')
    expect(listbox.classes()).toContain('bg-white')

    const options = wrapper.findAll('[role="option"]')
    expect(options).toHaveLength(3)
    expect(options[1]!.classes()).toContain('rounded-none')
    expect(options[1]!.classes()).toContain('bg-white')

    await options[1]!.trigger('click')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['Company QR Code'])
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
  })

  it('prevents opening the menu when disabled', async () => {
    const wrapper = mount(BaseSelect, {
      props: {
        modelValue: 'Super Administrator',
        disabled: true,
        options: ['Super Administrator', 'Dispatch & Safety Supervisor'],
      },
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    const trigger = wrapper.find('button[role="combobox"]')
    expect(trigger.attributes('disabled')).toBeDefined()

    await trigger.trigger('click')
    expect(wrapper.find('[role="listbox"]').exists()).toBe(false)
  })
})
