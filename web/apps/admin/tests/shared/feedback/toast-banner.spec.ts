import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

describe('ToastBanner', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  it('auto-dismisses after the configured delay', async () => {
    const wrapper = mount(ToastBanner, {
      props: {
        message: 'Calling Driver · +63 917 773 8810',
        tone: 'warning',
      },
    })

    expect(wrapper.text()).toContain('Calling Driver')

    vi.advanceTimersByTime(3400)
    expect(wrapper.emitted('dismiss')).toBeUndefined()

    vi.advanceTimersByTime(100)
    expect(wrapper.emitted('dismiss')).toHaveLength(1)
  })

  it('resets the dismiss timer when the message changes and supports manual dismiss', async () => {
    const wrapper = mount(ToastBanner, {
      props: {
        message: 'First message',
        duration: 2000,
      },
    })

    vi.advanceTimersByTime(1500)
    await wrapper.setProps({ message: 'Second message' })

    vi.advanceTimersByTime(1500)
    expect(wrapper.emitted('dismiss')).toBeUndefined()

    vi.advanceTimersByTime(500)
    expect(wrapper.emitted('dismiss')).toHaveLength(1)

    await wrapper.find('button[aria-label="Dismiss notification"]').trigger('click')
    expect(wrapper.emitted('dismiss')).toHaveLength(2)
  })
})
