import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DriverApplicationDetailsPage from '@/pages/users/driver-applications/[id].vue'

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { id: 'APP-901' },
  }),
  useRouter: () => ({
    back: vi.fn(),
    push: vi.fn(),
  }),
  RouterLink: true,
}))

describe('DriverApplicationDetailsPage', () => {
  it('renders driver application details, back button, Philippine taxicle info, and allows approval via modal', async () => {
    const wrapper = mount(DriverApplicationDetailsPage, {
      global: {
        stubs: {
          RouterLink: true,
          Teleport: true,
        },
      },
    })

    expect(wrapper.text()).toContain('Back')
    expect(wrapper.text()).toContain('Application APP-901')
    expect(wrapper.text()).toContain('Brandon Lee')
    expect(wrapper.text()).toContain('+63 917 111 2233')
    expect(wrapper.text()).toContain('Bajaj')
    expect(wrapper.text()).toContain('Taxicle')
    expect(wrapper.text()).toContain('A1')
    expect(wrapper.text()).toContain('View License')
    expect(wrapper.text()).toContain('NBI')

    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve Driver & Issue Credentials'))
    expect(approveBtn).toBeDefined()
    if (approveBtn) {
      await approveBtn.trigger('click')
      expect(wrapper.text()).toContain('Approve Driver Application')

      const confirmBtn = wrapper
        .findAll('button')
        .find((b) => b.text().includes('Confirm & Approve Driver'))
      expect(confirmBtn).toBeDefined()
      if (confirmBtn) {
        await confirmBtn.trigger('click')
        expect(wrapper.text()).toContain(
          'Application approved. Taxicle driver credentials and dispatch access active',
        )
      }
    }
  })
})
