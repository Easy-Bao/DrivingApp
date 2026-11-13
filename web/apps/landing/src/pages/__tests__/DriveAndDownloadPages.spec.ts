import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import DownloadPage from '@/pages/download.vue'
import DrivePage from '@/pages/drive.vue'
import SafetyPage from '@/pages/safety.vue'

function createPagesRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<div>Home</div>' } },
      { path: '/drive', component: DrivePage },
      { path: '/safety', component: SafetyPage },
      { path: '/download', component: DownloadPage },
      { path: '/architecture', component: { template: '<div>Architecture</div>' } },
    ],
  })
}

describe('File-based secondary routes', () => {
  it('renders drive page with QRPh wallet and earnings calculator', async () => {
    const router = createPagesRouter()
    await router.push('/drive')
    await router.isReady()

    const wrapper = mount(DrivePage, {
      global: { plugins: [router] },
    })

    expect(wrapper.find('h1').text()).toContain('10%–15% fees')
    expect(wrapper.text()).toContain('Driver Earnings Estimator (PHP)')
    expect(wrapper.text()).toContain('GCash QRPh')
  })

  it('reads prefilled route query parameters on /download', async () => {
    const router = createPagesRouter()
    await router.push('/download?from=Agora+Market&to=Dao+Capitol&tier=comfort&fare=69')
    await router.isReady()

    const wrapper = mount(DownloadPage, {
      global: { plugins: [router] },
    })

    expect(wrapper.text()).toContain('Selected Route Estimate Ready')
    expect(wrapper.text()).toContain('Agora Market')
    expect(wrapper.text()).toContain('Dao Capitol')
    expect(wrapper.text()).toContain('Terminal & Uphill')
    expect(wrapper.text()).toContain('₱69')
  })

  it('renders safety verification gates and Pagadian CDRRMO escalation on /safety', async () => {
    const router = createPagesRouter()
    await router.push('/safety')
    await router.isReady()

    const wrapper = mount(SafetyPage, {
      global: { plugins: [router] },
    })

    expect(wrapper.find('h1').text()).toBe('Verified Pagadian operators before every pickup')
    expect(wrapper.text()).toContain('062-925-0911')
    expect(wrapper.text()).toContain('Dial 911')
  })
})
