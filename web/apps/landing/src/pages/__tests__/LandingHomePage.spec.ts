import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import LandingHomePage from '@/pages/LandingHomePage.vue'

describe('LandingHomePage', () => {
  it('renders landing home page with hero and fare estimator', () => {
    const wrapper = mount(LandingHomePage, {
      global: {
        stubs: {
          RouterLink: true,
        },
      },
    })
    expect(wrapper.text()).toContain('Seamless, reliable rides at your fingertips.')
    expect(wrapper.text()).toContain('Estimate Your Trip')
  })
})
