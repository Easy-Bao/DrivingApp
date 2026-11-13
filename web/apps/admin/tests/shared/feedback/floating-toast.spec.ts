import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FloatingToast from '@/shared/feedback/FloatingToast.vue'

describe('FloatingToast', () => {
  it('renders a status toast when message is non-null and hides when null', async () => {
    const wrapper = mount(FloatingToast, {
      props: { message: null },
    })

    expect(wrapper.find('[role="status"]').exists()).toBe(false)

    await wrapper.setProps({ message: 'Copied Booking ID' })
    expect(wrapper.find('[role="status"]').text()).toContain('Copied Booking ID')
  })
})
