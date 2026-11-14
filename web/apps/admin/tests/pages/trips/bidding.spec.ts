import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting } from '@/features/settings'
import { resetTripsForTesting } from '@/features/trips'
import BiddingPage from '@/pages/trips/bidding.vue'

describe('BiddingPage', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  it('filters bidding sessions, inspects driver offers, and requires reason to close an open bid', async () => {
    const wrapper = mount(BiddingPage)

    expect(wrapper.text()).toContain('BID-3041')
    expect(wrapper.text()).toContain('Clarisse Abella')
    expect(wrapper.text()).toContain('Open: 1')

    const inspectBtn = wrapper.findAll('button').find((b) => b.text().includes('Inspect Offers'))
    expect(inspectBtn).toBeDefined()
    await inspectBtn!.trigger('click')
    expect(wrapper.text()).toContain('Bid Session BID-3041')
    expect(wrapper.text()).toContain('Danilo Mendoza')
    expect(wrapper.text()).toContain('4912-NC')

    const closeModalBtn = wrapper
      .findAll('button')
      .find(
        (b) =>
          b.text().trim() === 'Close' || b.attributes('aria-label') === 'Close offer inspector',
      )
    await closeModalBtn?.trigger('click')

    const closeBidBtn = wrapper.findAll('button').find((b) => b.text().includes('Close Bid'))
    expect(closeBidBtn).toBeDefined()
    await closeBidBtn!.trigger('click')
    expect(wrapper.text()).toContain('Close Open Bid Session?')

    const findExpireConfirmBtn = () =>
      wrapper.findAll('button').find((b) => b.text().includes('Expire Session'))
    expect(findExpireConfirmBtn()).toBeDefined()
    expect(findExpireConfirmBtn()!.attributes('disabled')).toBeDefined()

    await wrapper.find('textarea').setValue('Passenger boarded another vehicle')
    expect(findExpireConfirmBtn()!.attributes('disabled')).toBeUndefined()

    await findExpireConfirmBtn()!.trigger('click')

    expect(wrapper.text()).toContain('BID-3041')
    expect(wrapper.text()).toContain('Open: 0')
  })
})
