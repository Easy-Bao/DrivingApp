import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FarePricingPage from '@/pages/payments/fare-pricing.vue'

describe('FarePricingPage', () => {
  it('simulates Solo Taxicle PHP fare floor and edits a tariff rule', async () => {
    const wrapper = mount(FarePricingPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Solo Taxicle · Standard Poblacion')
    expect(wrapper.text()).toContain('₱25.00')
    expect(wrapper.text()).not.toContain('USD')

    const distanceInput = wrapper.find('input[aria-label="Simulator distance in kilometers"]')
    await distanceInput.setValue('5')
    expect(wrapper.find('[data-testid="estimated-fare"]').text()).toContain('₱97.00')

    const ratingCheckbox = wrapper.find('input[type="checkbox"]')
    await ratingCheckbox.setValue(true)
    expect(wrapper.find('[data-testid="estimated-fare"]').text()).toContain('₱101.85')

    const editBtn = wrapper.findAll('button').find((b) => b.text().includes('Edit Tariff'))
    expect(editBtn).toBeDefined()
    await editBtn!.trigger('click')

    expect(wrapper.text()).toContain('Edit Tariff · Solo Taxicle · Standard Poblacion')

    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Save Tariff Rule'))
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('Saved tariff updates for Solo Taxicle · Standard Poblacion')
  })
})
