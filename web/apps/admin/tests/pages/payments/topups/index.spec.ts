import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetPaymentsForTesting } from '@/features/payments'
import TopupsIndexPage from '@/pages/payments/topups/index.vue'

const pushSpy = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: pushSpy,
  }),
}))

describe('payments/topups/index page', () => {
  beforeEach(() => {
    resetPaymentsForTesting()
    pushSpy.mockClear()
  })

  it('filters top-up requests and displays canonical ₱500.00 amount for TOP-8921', async () => {
    const wrapper = mount(TopupsIndexPage)

    expect(wrapper.text()).toContain('3 Pending')
    expect(wrapper.text()).toContain('TOP-8921')
    expect(wrapper.text()).toContain('₱500.00')

    await wrapper.find('input[aria-label="Search top-up requests"]').setValue('Danilo')
    expect(wrapper.text()).toContain('TOP-8920')
    expect(wrapper.text()).not.toContain('TOP-8921')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Inspect Proof'))!
      .trigger('click')
    expect(pushSpy).toHaveBeenCalledWith('/payments/topups/TOP-8920')
  })
})
