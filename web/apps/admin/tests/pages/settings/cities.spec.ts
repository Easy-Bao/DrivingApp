import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import CitiesPage from '@/pages/config/cities.vue'

describe('settings/cities page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('renders Zamboanga del Sur markets with PHP formatted minimum fares', () => {
    const wrapper = mount(CitiesPage)
    expect(wrapper.text()).toContain('MKT-ZDS-7016')
    expect(wrapper.text()).toContain('Pagadian City')
    expect(wrapper.text()).toContain('₱25.00')
    expect(wrapper.text()).toContain('4 Municipalities')
  })

  it('adds a new municipality and validates blank required inputs', async () => {
    const wrapper = mount(CitiesPage)

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Add Municipality'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').exists()).toBe(true)
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Municipality'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').text()).toContain('municipality name')

    await wrapper.find('#city-name').setValue('Molave')
    await wrapper.find('#city-zip').setValue('7023')
    await wrapper.find('#city-min-fare').setValue('40')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Municipality'))!
      .trigger('click')

    expect(wrapper.text()).toContain('MKT-ZDS-7023')
    expect(wrapper.text()).toContain('Molave')
    expect(wrapper.text()).toContain('₱40.00')
    expect(wrapper.text()).toContain('5 Municipalities')
  })
})
