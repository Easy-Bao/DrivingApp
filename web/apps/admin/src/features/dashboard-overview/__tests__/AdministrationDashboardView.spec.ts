import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AdministrationDashboardView from '@/features/dashboard-overview/components/AdministrationDashboardView.vue'

describe('AdministrationDashboardView', () => {
  it('renders administration dashboard view correctly', () => {
    const wrapper = mount(AdministrationDashboardView)
    expect(wrapper.find('h1').text()).toBe('Administration Overview')
  })
})
