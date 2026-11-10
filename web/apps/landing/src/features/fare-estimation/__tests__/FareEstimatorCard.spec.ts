import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FareEstimatorCard from '@/features/fare-estimation/components/FareEstimatorCard.vue'

describe('FareEstimatorCard', () => {
  it('renders fare estimator title and form', () => {
    const wrapper = mount(FareEstimatorCard)
    expect(wrapper.find('h3').text()).toBe('Estimate Your Trip')
    expect(wrapper.find('button').text()).toBe('Get Fare Estimate')
  })
})
