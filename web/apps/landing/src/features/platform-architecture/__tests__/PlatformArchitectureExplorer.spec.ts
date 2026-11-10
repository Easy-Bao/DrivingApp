import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'

describe('PlatformArchitectureExplorer', () => {
  it('renders platform architecture service nodes', () => {
    const wrapper = mount(PlatformArchitectureExplorer)
    expect(wrapper.find('h2').text()).toBe('Platform Architecture Topology')
    expect(wrapper.text()).toContain('Gateway')
    expect(wrapper.text()).toContain('Core Service')
  })
})
