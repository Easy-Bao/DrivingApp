import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DriverApplicationsPage from '@/pages/users/driver-applications/index.vue'

const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: mockPush,
  }),
  useRoute: () => ({
    path: '/users/driver-applications',
  }),
}))

describe('DriverApplicationsPage', () => {
  it('renders streamlined queue table with Pagadian City barangays and separate applied date column', async () => {
    const wrapper = mount(DriverApplicationsPage)

    expect(wrapper.text()).toContain('Driver Applications')
    expect(wrapper.text()).toContain('Submitted')
    expect(wrapper.text()).toContain('Service Area')
    expect(wrapper.text()).toContain('Vehicle & Body No.')
    expect(wrapper.text()).not.toContain('Clearance Status')
    expect(wrapper.text()).not.toContain('Region / City')
    expect(wrapper.text()).not.toContain('Driver Applications Queue')

    expect(wrapper.text()).toContain('Pagadian City')
    expect(wrapper.text()).toContain('Brgy. San Jose')
    expect(wrapper.text()).toContain('Brandon Lee')
    expect(wrapper.text()).toContain('+63 917 111 2233')
    expect(wrapper.text()).toContain('2026-11-11')
    expect(wrapper.text()).toContain('2 hours ago')

    const reviewBtn = wrapper.findAll('button').find((b) => b.text().includes('Review Application'))
    expect(reviewBtn).toBeDefined()
    if (reviewBtn) {
      await reviewBtn.trigger('click')
      expect(mockPush).toHaveBeenCalledWith('/users/driver-applications/APP-901')
    }
  })
})
