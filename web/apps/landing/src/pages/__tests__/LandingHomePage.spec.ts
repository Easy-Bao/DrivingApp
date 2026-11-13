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
      { path: '/safety', component: { template: '<div>Safety</div>' } },
      { path: '/download', component: { template: '<div>Download</div>' } },
      { path: '/architecture', component: { template: '<div>Architecture</div>' } },
    ],
  })
}

describe('Landing Home Page', () => {
  it('renders Pagadian hero headline, upfront fare estimator, and showcase bands', async () => {
    const router = createTestRouter()
    await router.push('/')
    await router.isReady()

    const wrapper = mount(LandingHomePage, {
      global: {
        plugins: [router],
      },
    })

    expect(wrapper.find('h1').text()).toBe('Pagadian Taxicles, priced upfront before you step in.')
    expect(wrapper.text()).toContain('Check your upfront fare floor')
    expect(wrapper.text()).toContain('Four three-wheel tiers matched to Pagadian terrain')
    expect(wrapper.text()).toContain('No curbside haggling. Choose your driver in 90 seconds.')
  })

  it('switches bidding walkthrough steps when clicked', async () => {
    const router = createTestRouter()
    await router.push('/')
    await router.isReady()

    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router],
      },
    })

    const stepButtons = wrapper.findAll('#bidding-flow [role="tab"]')
    expect(stepButtons.length).toBe(3)

    const thirdTab = stepButtons[2]
    expect(thirdTab).toBeDefined()
    if (thirdTab) {
      await thirdTab.trigger('click')
      expect(wrapper.text()).toContain('Driver En Route')
    }
  })

  it('prefills hero fare estimator when selecting a coverage corridor route', async () => {
    const router = createTestRouter()
    await router.push('/')
    await router.isReady()

    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router],
      },
    })

    const coverageTabs = wrapper.findAll('#coverage [role="tab"]')
    const airportTab = coverageTabs[3]
    expect(airportTab).toBeDefined()
    if (airportTab) {
      await airportTab.trigger('click')
    }

    const prefillButton = wrapper
      .findAll('#coverage button')
      .find((button) => button.text().includes('Prefill this corridor in calculator'))
    expect(prefillButton).toBeDefined()
    if (prefillButton) {
      await prefillButton.trigger('click')
      const destinationInput = wrapper.find('#landing-destination-input')
      expect((destinationInput.element as HTMLInputElement).value).toBe('Pagadian City Airport')
    }
  })
})
