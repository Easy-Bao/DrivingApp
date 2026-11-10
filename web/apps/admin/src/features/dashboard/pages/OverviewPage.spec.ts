import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import OverviewPage from '@/features/dashboard/pages/OverviewPage.vue'

describe('OverviewPage', () => {
  it('renders executive operations overview and telemetry KPIs', () => {
    const wrapper = mount(OverviewPage, {
      global: {
        stubs: {
          RouterLink: true,
        },
      },
    })
    expect(wrapper.text()).toContain('Executive Operations Overview')
    expect(wrapper.text()).toContain('Active Rides')
    expect(wrapper.text()).toContain('Online Drivers')
    expect(wrapper.text()).toContain('Today Revenue')
    expect(wrapper.text()).toContain('Completion Rate')
  })
})
