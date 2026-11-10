import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DriverApplicationDetailsPage from '@/features/users/pages/DriverApplicationDetailsPage.vue'

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
  it('renders driver application details, internal back button, and allows approval', async () => {
    const wrapper = mount(DriverApplicationDetailsPage, {
      global: {
        stubs: {
          RouterLink: true,
        },
      },
    })

    // Assert internal back button exists inside page
    expect(wrapper.text()).toContain('Back to Driver Applications')

    // Assert application details
    expect(wrapper.text()).toContain('Application APP-901')
    expect(wrapper.text()).toContain('Brandon Lee')
    expect(wrapper.text()).toContain('Tesla')
    expect(wrapper.text()).toContain('Checkr Regulatory API')

    // Assert approve action button is present and click approves it
    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve Driver & Issue Credentials'))
    expect(approveBtn).toBeDefined()
    if (approveBtn) {
      await approveBtn.trigger('click')
      expect(wrapper.text()).toContain(
        'approved! Driver credentials and welcome instructions dispatched',
      )
    }
  })
})
