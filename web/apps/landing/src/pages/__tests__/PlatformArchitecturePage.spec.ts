import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import PlatformArchitecturePage from '@/pages/PlatformArchitecturePage.vue'
import ArchitecturePage from '@/pages/architecture.vue'

describe('PlatformArchitecturePage', () => {
  it('renders platform architecture page with client cards and explorer', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: { template: '<div>Home</div>' } },
        { path: '/drive', component: { template: '<div>Drive</div>' } },
        { path: '/safety', component: { template: '<div>Safety</div>' } },
        { path: '/download', component: { template: '<div>Download</div>' } },
        { path: '/architecture', component: ArchitecturePage },
      ],
    })
    await router.push('/architecture')
    await router.isReady()

    const wrapper = mount(PlatformArchitecturePage, {
      global: {
        plugins: [router],
      },
    })

    expect(wrapper.find('h1').text()).toBe(
      'Dispatch platform architecture built for real-time reliability',
    )
    expect(wrapper.text()).toContain('apps/passenger (Flutter)')
    expect(wrapper.text()).toContain('Go API Gateway')
    expect(wrapper.text()).toContain('Realtime Bidding Broker')
  })
})
