import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchField from '@/shared/forms/SearchField.vue'

describe('SearchField', () => {
  it('emits search updates and clears query via button or Escape key', async () => {
    const wrapper = mount(SearchField, {
      props: {
        modelValue: 'Pagadian',
        placeholder: 'Search routes...',
        ariaLabel: 'Search routes',
      },
    })

    const clearBtn = wrapper.find('button[aria-label="Clear search"]')
    expect(clearBtn.exists()).toBe(true)

    await clearBtn.trigger('click')
    expect(wrapper.emitted('update:modelValue')).toEqual([['']])

    const input = wrapper.find('input')
    await input.setValue('Bao-Bao')
    expect(wrapper.emitted('update:modelValue')?.[1]).toEqual(['Bao-Bao'])

    await input.trigger('keydown.escape')
    expect(wrapper.emitted('update:modelValue')?.[2]).toEqual([''])
  })
})
