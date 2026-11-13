import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import PaymentMethodsPage from '@/pages/payments/methods.vue'

describe('PaymentMethodsPage', () => {
  it('supports adding a company account, editing details, and updating a QRPh image', async () => {
    const wrapper = mount(PaymentMethodsPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('GCash QRPh · Pagadian Dispatch Treasury')
    expect(wrapper.text()).toContain('BDO Unibank · Pagadian Rizal Ave Branch')

    const addBtn = wrapper.findAll('button').find((b) => b.text().includes('+ Add Company Account'))
    await addBtn!.trigger('click')
    expect(wrapper.text()).toContain('Add Company Collection Account')

    const addInputs = wrapper.findAll('input[type="text"]')
    await addInputs[0]!.setValue('Landbank Pagadian Express')
    await addInputs[1]!.setValue('Land Bank of the Philippines')
    await addInputs[2]!.setValue('0912-3456-78')
    await addInputs[4]!.setValue('LBP-PAG-8809')

    const saveAccountBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Collection Account'))
    await saveAccountBtn!.trigger('click')
    expect(wrapper.text()).toContain('Landbank Pagadian Express')

    const editBtn = wrapper.findAll('button').find((b) => b.text().includes('Edit Account Info'))
    await editBtn!.trigger('click')
    expect(wrapper.text()).toContain('Edit Account Info ·')
    const saveEditBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Update Account Details'))
    await saveEditBtn!.trigger('click')
    expect(wrapper.text()).toContain('Updated account details for')

    const qrBtn = wrapper.findAll('button').find((b) => b.text().includes('Update QR Code Image'))
    await qrBtn!.trigger('click')
    expect(wrapper.text()).toContain('Update QR Code Image ·')

    const refInput = wrapper.find('input[aria-label="QRPh Merchant Reference"]')
    await refInput.setValue('QRPH-PAG-9001')
    const regenerateBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Regenerate Preview'))
    await regenerateBtn!.trigger('click')

    const publishBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Publish Updated QR Code'))
    await publishBtn!.trigger('click')
    expect(wrapper.text()).toContain('Updated QRPh collection image')
    expect(wrapper.text()).toContain('QRPH-PAG-9001')
  })
})
