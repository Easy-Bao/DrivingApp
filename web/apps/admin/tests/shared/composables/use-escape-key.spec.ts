import { defineComponent, ref } from 'vue'
import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { useEscapeKey } from '@/shared/composables/use-escape-key'

describe('useEscapeKey', () => {
  it('invokes handler on Escape only while enabled and removes listener on unmount', async () => {
    const onEscape = vi.fn()
    const enabled = ref(false)

    const Harness = defineComponent({
      setup() {
        useEscapeKey(enabled, onEscape)
        return {}
      },
      template: '<div />',
    })

    const wrapper = mount(Harness)
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(onEscape).not.toHaveBeenCalled()

    enabled.value = true
    await wrapper.vm.$nextTick()
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(onEscape).toHaveBeenCalledTimes(1)

    wrapper.unmount()
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(onEscape).toHaveBeenCalledTimes(1)
  })
})
