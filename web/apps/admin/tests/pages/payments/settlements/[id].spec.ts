import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetPaymentsForTesting, useSettlements } from '@/features/payments'
import SettlementDetailPage from '@/pages/payments/settlements/[id].vue'

let routeId = 'STL-9401'

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { id: routeId },
  }),
  useRouter: () => ({
    back: vi.fn(),
    push: vi.fn(),
  }),
}))

describe('payments/settlements/[id] page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
    routeId = 'STL-9401'
  })

  it('reconciles a pending cash settlement and records an audit entry', async () => {
    const wrapper = mount(SettlementDetailPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('Settlement STL-9401')
    expect(wrapper.text()).toContain('₱20.00')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Mark Full Fare Settled'))!
      .trigger('click')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Confirm Paid & Reconcile'))!
      .trigger('click')

    expect(wrapper.text()).toContain('STL-9401 marked paid and commission ledger reconciled')
    expect(useSettlements().getSettlementById('STL-9401')?.resolutionState).toBe('reconciled')
    expect(logs.value[0]?.action).toBe('SETTLEMENT_RECONCILED')
  })

  it('shows safe not-found state for invalid route identifiers', () => {
    routeId = '../bad'
    const wrapper = mount(SettlementDetailPage)
    expect(wrapper.text()).toContain('Settlement Record Not Found')
  })
})
