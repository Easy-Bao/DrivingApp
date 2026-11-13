import { RouterLinkStub, mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import FareEstimatorCard from '@/features/fare-estimation/components/FareEstimatorCard.vue'

describe('FareEstimatorCard', () => {
  it('renders upfront Pagadian fare floor, presets, and action controls', async () => {
    const wrapper = mount(FareEstimatorCard, {
      global: {
        stubs: {
          RouterLink: RouterLinkStub,
        },
      },
    })

    expect(wrapper.find('h2').text()).toBe('Check your upfront fare floor')
    const pickupInput = wrapper.find('#landing-pickup-input')
    expect((pickupInput.element as HTMLInputElement).value).toBe('Agora Public Market, Poblacion')
    expect(wrapper.find('button[type="submit"]').text()).toBe('Estimate Fare')
    expect(wrapper.text()).toContain('Book in EasyRide App')

    const tierRadios = wrapper.findAll('[role="radio"]')
    expect(tierRadios.length).toBe(3)
    const uphillRadio = tierRadios[1]
    expect(uphillRadio).toBeDefined()
    if (uphillRadio) {
      await uphillRadio.trigger('click')
      expect(wrapper.text()).toContain('TVS King Deluxe')
    }
  })
})
