import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import PlatformArchitecturePage from '@/pages/PlatformArchitecturePage.vue'
import ArchitecturePage from '@/pages/architecture.vue'

describe('PlatformArchitecturePage', () => {
  it('renders architecture page and service explorer', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: { template: '<div>Home</div>' } },
        { path: '/drive', component: { template: '<div>Drive</div>' } },
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

    expect(wrapper.find('h1').text()).toBe('System Architecture')
    expect(wrapper.text()).toContain('API Gateway')
    expect(wrapper.text()).toContain('Core Dispatch')
  })
})
