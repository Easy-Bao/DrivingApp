import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'

describe('PlatformArchitectureExplorer', () => {
  it('renders architecture service nodes and updates active node specification on click', async () => {
    const wrapper = mount(PlatformArchitectureExplorer)

    expect(wrapper.text()).toContain('Go API Gateway')
    expect(wrapper.text()).toContain('Core Dispatch Service')
    expect(wrapper.text()).toContain('Realtime Bidding Broker')

    const nodeButtons = wrapper.findAll('button')
    expect(nodeButtons.length).toBe(3)

    const realtimeButton = nodeButtons[2]
    expect(realtimeButton).toBeDefined()
    if (realtimeButton) {
      await realtimeButton.trigger('click')
      expect(wrapper.find('h3').text()).toBe('Realtime Bidding Broker')
      expect(wrapper.text()).toContain('90-second deterministic auction countdown timer')
    }
  })
})
