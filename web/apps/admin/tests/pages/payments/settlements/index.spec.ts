import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetPaymentsForTesting } from '@/features/payments'
import SettlementsIndexPage from '@/pages/payments/settlements/index.vue'

const pushSpy = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: pushSpy,
  }),
}))

describe('payments/settlements/index page', () => {
  beforeEach(() => {
    resetPaymentsForTesting()
    pushSpy.mockClear()
  })

  it('displays summary totals, filters by cash outcome & search, navigates, and exports CSV', async () => {
    const wrapper = mount(SettlementsIndexPage)

    expect(wrapper.text()).toContain('STL-9401')
    expect(wrapper.text()).toContain('₱60.00')
    expect(wrapper.text()).toContain('₱20.00')

    await wrapper.find('input[aria-label="Search cash settlement records"]').setValue('Javier')
    expect(wrapper.text()).toContain('STL-9401')
    expect(wrapper.text()).not.toContain('STL-9400')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Review Record'))!
      .trigger('click')
    expect(pushSpy).toHaveBeenCalledWith('/payments/settlements/STL-9401')

    await wrapper
      .find('input[aria-label="Search cash settlement records"]')
      .setValue('MissingQuery')
    expect(wrapper.text()).toContain('No matching settlement records')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Reset'))!
      .trigger('click')
    expect(wrapper.text()).toContain('STL-9400')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Export CSV'))!
      .trigger('click')
    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)
  })
})
