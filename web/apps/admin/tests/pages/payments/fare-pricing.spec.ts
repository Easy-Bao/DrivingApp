import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import FarePricingPage from '@/pages/payments/fare-pricing.vue'

describe('FarePricingPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('displays server-synced tariff configuration without client-side fare simulator', async () => {
    const wrapper = mount(FarePricingPage)

    expect(wrapper.text()).toContain('Standard Poblacion')
    expect(wrapper.text()).toContain('₱25.00')
    expect(wrapper.text()).toContain('Server-computed fare calculation')
    expect(wrapper.find('[data-testid="estimated-fare"]').exists()).toBe(false)
    expect(wrapper.find('input[aria-label="Simulator distance in kilometers"]').exists()).toBe(
      false,
    )

    const editBtn = wrapper.findAll('button').find((b) => b.text().includes('Edit Tariff'))
    expect(editBtn).toBeDefined()
    await editBtn!.trigger('click')
    expect(wrapper.text()).toContain('Edit Tariff · Standard Poblacion')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Save Tariff Rule'))
    expect(saveBtn).toBeDefined()
    await saveBtn!.trigger('click')
    expect(wrapper.text()).toContain('Saved tariff updates for Standard Poblacion')
  })
})
