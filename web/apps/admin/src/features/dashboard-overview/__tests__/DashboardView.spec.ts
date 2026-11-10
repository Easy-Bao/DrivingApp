import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import DashboardView from '@/features/dashboard-overview/components/DashboardView.vue'

describe('DashboardView', () => {
  it('renders dashboard view correctly', () => {
    const wrapper = mount(DashboardView)
    expect(wrapper.find('h1').text()).toBe('Dashboard Overview')
  })
})
