import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import DocumentVerificationPage from '@/pages/documents/verification.vue'

describe('DocumentVerificationPage', () => {
  it('requires all four compliance checkboxes before enabling approval', async () => {
    const wrapper = mount(DocumentVerificationPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Rodelio Cruz')
    expect(wrapper.text()).toContain('Pagadian City Franchising Board')
    expect(wrapper.text()).toContain('Expired')
    expect(wrapper.text()).not.toContain('Taxicle Franchising Board')
    expect(wrapper.text()).not.toContain('Brgy. San Jose')

    const reviewBtn = wrapper.findAll('button').find((b) => b.text().includes('Review Document'))
    expect(reviewBtn).toBeDefined()
    await reviewBtn!.trigger('click')

    const findApproveBtn = () =>
      wrapper.findAll('button').find((b) => b.text().includes('Approve & Validate'))

    expect(findApproveBtn()?.attributes('disabled')).toBeDefined()

    const checkboxes = wrapper.findAll('input[type="checkbox"]')
    expect(checkboxes.length).toBe(4)
    for (const box of checkboxes) {
      await box.setValue(true)
    }

    expect(findApproveBtn()?.attributes('disabled')).toBeUndefined()
    await findApproveBtn()?.trigger('click')

    expect(wrapper.text()).toContain('DOC-901 approved for Rodelio Cruz.')
  })

  it('requires a selected regulatory reason before confirming document rejection', async () => {
    const wrapper = mount(DocumentVerificationPage, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    const reviewBtn = wrapper.findAll('button').find((b) => b.text().includes('Review Document'))
    await reviewBtn!.trigger('click')

    const rejectTrigger = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Reject Document'))
    await rejectTrigger!.trigger('click')

    const findConfirmReject = () =>
      wrapper.findAll('button').find((b) => b.text().includes('Confirm Rejection'))

    expect(findConfirmReject()?.attributes('disabled')).toBeDefined()

    const reasonTrigger = wrapper.find('button[aria-label="Regulatory rejection ground"]')
    await reasonTrigger.trigger('click')
    const reasonOption = wrapper
      .findAll('[role="option"]')
      .find((opt) => opt.text().includes('Image blurred or unreadable official seal'))
    expect(reasonOption).toBeDefined()
    await reasonOption!.trigger('click')
    expect(findConfirmReject()?.attributes('disabled')).toBeUndefined()

    await findConfirmReject()?.trigger('click')
    expect(wrapper.text()).toContain(
      'DOC-901 rejected (Image blurred or unreadable official seal).',
    )
  })
})
