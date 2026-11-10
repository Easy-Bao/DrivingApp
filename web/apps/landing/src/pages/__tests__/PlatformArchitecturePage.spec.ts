import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import PlatformArchitecturePage from '@/pages/PlatformArchitecturePage.vue'

describe('PlatformArchitecturePage', () => {
  it('renders platform architecture page with explorer', () => {
    const wrapper = mount(PlatformArchitecturePage, {
      global: {
        stubs: {
          RouterLink: true,
        },
      },
    })
    expect(wrapper.text()).toContain('Platform Infrastructure')
    expect(wrapper.text()).toContain('Platform Architecture Topology')
  })
})
