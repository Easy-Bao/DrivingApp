import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting } from '@/features/payments'
import FarePricingPage from '@/pages/config/fare-pricing.vue'

describe('FarePricingPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('displays server-synced tariff configuration without client-side fare simulator and edits VIP rating bonus', async () => {
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

    await wrapper.find('#tariff-rating-bonus').setValue('1.12')
    const saveBtn = wrapper.findAll('button').find((b) => b.text().includes('Save Tariff Rule'))
    expect(saveBtn).toBeDefined()
    await saveBtn!.trigger('click')

    expect(wrapper.text()).toContain('Saved tariff updates for Standard Poblacion')
    expect(wrapper.text()).toContain('1.12x VIP')
  })

  it('supports creating new tariff tiers, committing global surge/rating policy, and managing statutory discounts', async () => {
    const wrapper = mount(FarePricingPage)
    const { logs } = useAuditLogs()

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Tariff Tier'))!
      .trigger('click')
    await wrapper.find('#tariff-tier-name').setValue('Airport Direct Express')
    await wrapper.find('#tariff-corridor-scope').setValue('Pagadian Airport to Poblacion')
    await wrapper.find('#tariff-base-fare').setValue('45')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Tariff Rule'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Airport Direct Express')
    expect(wrapper.text()).toContain('₱45.00')
    expect(logs.value[0]?.action).toBe('TARIFF_MATRIX_CREATED')

    await wrapper.find('#policy-low-rating-penalty').setValue('0.85')
    await wrapper.find('#policy-cancel-grace').setValue('5')
    await wrapper.find('#save-pricing-policy').trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    await dialog.find('textarea').setValue('Updated rating penalty and grace period.')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Apply Pricing Policy'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Saved global fare, surge, and rating pricing policy.')
    expect(logs.value[0]?.action).toBe('PRICING_POLICY_UPDATED')

    expect(wrapper.text()).toContain('Senior Citizen Statutory Discount')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Discount Rule'))!
      .trigger('click')
    await wrapper.find('#discount-name').setValue('Solo Parent LGU Discount')
    await wrapper.find('#discount-reference').setValue('City Ordinance 2026-08')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Discount Rule'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Solo Parent LGU Discount')
  })
})
