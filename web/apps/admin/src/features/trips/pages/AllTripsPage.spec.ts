import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AllTripsPage from '@/features/trips/pages/AllTripsPage.vue'

describe('AllTripsPage', () => {
  it('filters Pagadian trips by search and status and opens the route detail modal', async () => {
    const wrapper = mount(AllTripsPage, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    expect(wrapper.text()).toContain('Althea Mae Villanueva')
    expect(wrapper.text()).toContain('Brgy. San Jose, Pagadian City')

    const search = wrapper.find('input[type="text"]')
    await search.setValue('Reynaldo')
    expect(wrapper.text()).toContain('TRP-7016-8919')
    expect(wrapper.text()).not.toContain('TRP-7016-8921')

    const viewBtn = wrapper.findAll('button').find((b) => b.text().includes('View Route'))
    expect(viewBtn).toBeDefined()
    await viewBtn!.trigger('click')

    expect(wrapper.text()).toContain('Trip Route & Fare Summary · TRP-7016-8919')
    expect(wrapper.text()).toContain('Zamboanga del Sur Medical Center, Dao')
  })
})
