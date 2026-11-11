import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import TopupDetailsPage from '@/features/payments/pages/TopupDetailsPage.vue'

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { id: 'TOP-8921' },
  }),
  useRouter: () => ({
    back: vi.fn(),
    push: vi.fn(),
  }),
  RouterLink: true,
}))

describe('TopupDetailsPage', () => {
  it('renders topup request details, internal back button, and allows credit approval', async () => {
    const wrapper = mount(TopupDetailsPage, {
      global: {
        stubs: {
          RouterLink: true,
        },
      },
    })

    // Assert internal back button exists inside page
    expect(wrapper.text()).toContain('Back to Driver Top-Ups')

    // Assert request details are displayed
    expect(wrapper.text()).toContain('Top-Up Request TOP-8921')
    expect(wrapper.text()).toContain('Marcus Miller')
    expect(wrapper.text()).toContain('₱50.00')
    expect(wrapper.text()).toContain('Company QR Code')

    // Assert approve action button is present and click approves it
    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve & Credit Wallet'))
    expect(approveBtn).toBeDefined()
    if (approveBtn) {
      await approveBtn.trigger('click')
      expect(wrapper.text()).toContain('Successfully verified TOP-8921')
    }
  })
})
