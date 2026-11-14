import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetUsersForTesting } from '@/features/users'
import DriverApplicationDetailsPage from '@/pages/users/driver-applications/[id].vue'

const routeState = { params: { id: 'APP-901' } }

vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  useRouter: () => ({
    back: vi.fn(),
    push: vi.fn(),
  }),
  RouterLink: true,
}))

describe('DriverApplicationDetailsPage', () => {
  beforeEach(() => {
    routeState.params.id = 'APP-901'
    resetSettingsForTesting()
    resetUsersForTesting()
  })

  it('renders driver application details, back button, vehicle info, and allows approval via modal', async () => {
    const wrapper = mount(DriverApplicationDetailsPage)
    const { logs } = useAuditLogs()

    expect(wrapper.text()).toContain('Back')
    expect(wrapper.text()).toContain('Application APP-901')
    expect(wrapper.text()).toContain('Brandon Lee')
    expect(wrapper.text()).toContain('+63 917 111 2233')
    expect(wrapper.text()).toContain('6184-ND')
    expect(wrapper.text()).toContain('Bajaj')
    expect(wrapper.text()).toContain('Bao-Bao')
    expect(wrapper.text()).toContain('A1')
    expect(wrapper.text()).toContain('View License')
    expect(wrapper.text()).toContain('NBI')

    const approveBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Approve & Activate Driver'))
    expect(approveBtn).toBeDefined()
    await approveBtn!.trigger('click')
    expect(wrapper.text()).toContain('Approve Driver Application')

    const confirmBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Confirm & Activate Driver'))
    expect(confirmBtn).toBeDefined()
    await confirmBtn!.trigger('click')

    expect(wrapper.text()).toContain(
      'Application approved. Driver credentials and dispatch access active.',
    )
    expect(logs.value[0]?.action).toBe('DRIVER_APPLICATION_APPROVED')
  })

  it('opens front/back license viewer, rejects application with reason, and handles unknown IDs', async () => {
    const wrapper = mount(DriverApplicationDetailsPage)
    const { logs } = useAuditLogs()

    const viewLicenseBtn = wrapper.findAll('button').find((b) => b.text().includes('View License'))
    expect(viewLicenseBtn).toBeDefined()
    await viewLicenseBtn!.trigger('click')
    expect(wrapper.text()).toContain('Front Side')

    const backSideBtn = wrapper.findAll('button').find((b) => b.text().includes('Back Side'))
    expect(backSideBtn).toBeDefined()
    await backSideBtn!.trigger('click')
    expect(wrapper.text()).toContain('lto_license_back_brandon_lee.png')

    const closeModalBtn = wrapper
      .findAll('button')
      .find((b) => b.attributes('aria-label') === 'Close modal')
    await closeModalBtn?.trigger('click')

    const rejectBtn = wrapper.findAll('button').find((b) => b.text().includes('Reject Application'))
    expect(rejectBtn).toBeDefined()
    await rejectBtn!.trigger('click')

    const confirmRejectBtn = wrapper
      .findAll('button')
      .find((b) => b.text().includes('Confirm Rejection'))
    expect(confirmRejectBtn).toBeDefined()
    await confirmRejectBtn!.trigger('click')

    expect(wrapper.text()).toContain('Application rejected:')
    expect(logs.value[0]?.action).toBe('DRIVER_APPLICATION_REJECTED')

    routeState.params.id = 'APP-DOES-NOT-EXIST'
    const missingWrapper = mount(DriverApplicationDetailsPage)
    expect(missingWrapper.text()).toContain('Application Not Found')
  })
})
