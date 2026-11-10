import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AdministrationDashboardPage from '@/pages/AdministrationDashboardPage.vue'

describe('AdministrationDashboardPage', () => {
  it('renders administration dashboard page layout and view', () => {
    const wrapper = mount(AdministrationDashboardPage)
    expect(wrapper.text()).toContain('EasyRide Admin Portal')
    expect(wrapper.text()).toContain('Administration Overview')
  })
})
