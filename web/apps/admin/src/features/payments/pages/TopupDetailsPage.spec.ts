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
  it('renders localized topup details with receipt preview image and approval workflow', async () => {
    const wrapper = mount(TopupDetailsPage, {
      global: {
        stubs: {
          RouterLink: true,
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Back')
    expect(wrapper.text()).toContain('Top-Up Request TOP-8921')
    expect(wrapper.text()).toContain('Rodelio Cruz')
    expect(wrapper.text()).toContain('+63 917 440 2184')
    expect(wrapper.text()).toContain('₱500.00')
    expect(wrapper.text()).toContain('GCash QRPh')

    const proofImg = wrapper.find('img')
    expect(proofImg.exists()).toBe(true)
    expect(proofImg.attributes('src')).toContain('data:image/svg+xml')

    const enlargeBtn = wrapper.findAll('button').find((b) => b.text().includes('Enlarge'))
    expect(enlargeBtn).toBeDefined()
    await enlargeBtn?.trigger('click')
    expect(wrapper.text()).toContain('Proof of Transfer · GC-90281944210')

    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve & Credit Wallet'))
    expect(approveBtn).toBeDefined()
    await approveBtn?.trigger('click')
    expect(wrapper.text()).toContain('Successfully verified TOP-8921')
  })
})
