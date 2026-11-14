import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetPaymentsForTesting } from '@/features/payments'
import EarningsPage from '@/pages/payments/earnings.vue'

describe('payments/earnings page', () => {
  beforeEach(() => {
    resetPaymentsForTesting()
  })

  it('renders basis-point commission rates, filters by driver, and exports CSV', async () => {
    const wrapper = mount(EarningsPage)

    expect(wrapper.text()).toContain('Rodelio Cruz')
    expect(wrapper.text()).toContain('₱4,680.00')
    expect(wrapper.text()).toContain('(15%)')
    expect(wrapper.text()).toContain('(12%)')

    await wrapper.find('input[aria-label="Search driver earnings"]').setValue('Bautista')
    expect(wrapper.text()).toContain('Reynaldo Bautista')
    expect(wrapper.text()).not.toContain('Rodelio Cruz')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Export CSV'))!
      .trigger('click')
    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)
  })
})
