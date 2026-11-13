import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import LandingHomePage from '@/pages/LandingHomePage.vue'
import IndexPage from '@/pages/index.vue'

function createTestRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: IndexPage },
      { path: '/drive', component: { template: '<div>Drive</div>' } },
      { path: '/download', component: { template: '<div>Download</div>' } },
      { path: '/architecture', component: { template: '<div>Architecture</div>' } },
    ],
  })
}

describe('Landing Home Page', () => {
  it('renders minimalist hero, fare estimator, rides, steps, and driver callout', async () => {
    const router = createTestRouter()
    await router.push('/')
    await router.isReady()

    const wrapper = mount(LandingHomePage, {
      global: {
        plugins: [router],
      },
    })

    expect(wrapper.find('h1').text()).toBe('Rides around Pagadian, made easy.')
    expect(wrapper.text()).toContain('Fare Estimate')
    expect(wrapper.text()).toContain('Our Rides')
    expect(wrapper.text()).toContain('How It Works')
    expect(wrapper.text()).toContain('Drive EasyRide')
  })

  it('selects Uphill tier in calculator when clicking Check rate on Uphill card', async () => {
    const router = createTestRouter()
    await router.push('/')
    await router.isReady()

    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router],
      },
    })

    const rideButtons = wrapper.findAll('#rides button')
    const uphillButton = rideButtons[1]
    expect(uphillButton).toBeDefined()
    if (uphillButton) {
      await uphillButton.trigger('click')
      const tierRadios = wrapper.findAll('[role="radio"]')
      expect(tierRadios[1]?.attributes('aria-checked')).toBe('true')
    }
  })
})
