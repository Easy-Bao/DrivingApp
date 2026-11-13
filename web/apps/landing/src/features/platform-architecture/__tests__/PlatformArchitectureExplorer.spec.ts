import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'

describe('PlatformArchitectureExplorer', () => {
  it('renders service nodes and updates selected node detail on click', async () => {
    const wrapper = mount(PlatformArchitectureExplorer)

    expect(wrapper.text()).toContain('API Gateway')
    expect(wrapper.text()).toContain('Core Dispatch')
    expect(wrapper.text()).toContain('Realtime Broker')

    const nodeButtons = wrapper.findAll('button')
    expect(nodeButtons.length).toBe(3)

    const realtimeButton = nodeButtons[2]
    expect(realtimeButton).toBeDefined()
    if (realtimeButton) {
      await realtimeButton.trigger('click')
      expect(wrapper.find('h3').text()).toBe('Realtime Broker')
      expect(wrapper.text()).toContain('90s windows')
    }
  })
})
