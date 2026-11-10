import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import OverviewPage from '@/pages/OverviewPage.vue'

describe('OverviewPage', () => {
  it('renders executive overview metrics and recent dispatches', () => {
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
    expect(wrapper.text()).toContain('Recent Trip Dispatches')
  })
})
