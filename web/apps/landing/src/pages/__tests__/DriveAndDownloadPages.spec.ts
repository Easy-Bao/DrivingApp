import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import DownloadPage from '@/pages/download.vue'
import DrivePage from '@/pages/drive.vue'

function createPagesRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<div>Home</div>' } },
      { path: '/drive', component: DrivePage },
      { path: '/download', component: DownloadPage },
      { path: '/architecture', component: { template: '<div>Architecture</div>' } },
    ],
  })
}

describe('Drive and Download pages', () => {
  it('renders drive page with earnings estimate', async () => {
    const router = createPagesRouter()
    await router.push('/drive')
    await router.isReady()

    const wrapper = mount(DrivePage, {
      global: { plugins: [router] },
    })

    expect(wrapper.find('h1').text()).toBe('Drive EasyRide')
    expect(wrapper.text()).toContain('Earnings Estimate')
  })

  it('displays compact route handoff summary on /download when query params are present', async () => {
    const router = createPagesRouter()
    await router.push('/download?from=Agora+Market&to=Dao+Capitol&tier=comfort&fare=69')
    await router.isReady()

    const wrapper = mount(DownloadPage, {
      global: { plugins: [router] },
    })

    expect(wrapper.find('h1').text()).toBe('Get EasyRide')
    expect(wrapper.text()).toContain('Agora Market')
    expect(wrapper.text()).toContain('Dao Capitol')
    expect(wrapper.text()).toContain('Uphill')
    expect(wrapper.text()).toContain('₱69')
    expect(wrapper.text()).toContain('Google Play')
    expect(wrapper.text()).toContain('App Store')
    expect(wrapper.text()).toContain('Scan for EasyRide Passenger')
  })
})
