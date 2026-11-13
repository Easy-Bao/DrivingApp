import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import BookingIdCell from '@/shared/display/BookingIdCell.vue'
import RouteTimeline from '@/shared/display/RouteTimeline.vue'

describe('display shared primitives', () => {
  it('renders pickup and dropoff labels cleanly on RouteTimeline', () => {
    const wrapper = mount(RouteTimeline, {
      props: {
        pickup: 'Brgy. San Jose, Pagadian City',
        dropoff: 'Agora Public Market, Poblacion',
      },
    })

    expect(wrapper.text()).toContain('Pick Up')
    expect(wrapper.text()).toContain('Brgy. San Jose, Pagadian City')
    expect(wrapper.text()).toContain('Drop Off')
    expect(wrapper.text()).toContain('Agora Public Market, Poblacion')
    expect(wrapper.findAll('svg')).toHaveLength(2)
  })

  it('copies the full booking reference on click without rendering toast overlay when idle', async () => {
    const wrapper = mount(BookingIdCell, {
      props: {
        bookingId: '701629644618921',
      },
    })

    expect(wrapper.find('[role="status"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('7016…18921')

    await wrapper.find('button[aria-label="Copy Booking ID 701629644618921"]').trigger('click')
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('701629644618921')
    expect(wrapper.find('[role="status"]').text()).toContain('Copied Booking ID')
  })
})
