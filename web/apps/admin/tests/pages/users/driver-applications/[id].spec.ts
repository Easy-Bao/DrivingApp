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
  it('renders driver application details, back button, vehicle info, and allows approval via modal', async () => {
    const wrapper = mount(DriverApplicationDetailsPage)

    expect(wrapper.text()).toContain('Back')
    expect(wrapper.text()).toContain('Application APP-901')
    expect(wrapper.text()).toContain('Brandon Lee')
    expect(wrapper.text()).toContain('+63 917 111 2233')
    expect(wrapper.text()).toContain('Bajaj')
    expect(wrapper.text()).toContain('Bao-Bao')
    expect(wrapper.text()).toContain('A1')
    expect(wrapper.text()).toContain('View License')
    expect(wrapper.text()).toContain('NBI')

    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve & Activate Driver'))
    expect(approveBtn).toBeDefined()
    if (approveBtn) {
      await approveBtn.trigger('click')
      expect(wrapper.text()).toContain('Approve Driver Application')

      const confirmBtn = wrapper
        .findAll('button')
        .find((b) => b.text().includes('Confirm & Activate Driver'))
      expect(confirmBtn).toBeDefined()
      if (confirmBtn) {
        await confirmBtn.trigger('click')
        expect(wrapper.text()).toContain(
          'Application approved. Driver credentials and dispatch access active.',
        )
      }
    }
  })
})
