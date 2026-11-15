import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import { resetReportsForTesting } from '@/features/reports'
import TripsReportPage from '@/pages/reports/trips.vue'
import RevenueReportPage from '@/pages/reports/revenue.vue'
import CancellationsReportPage from '@/pages/reports/cancellations.vue'
import PeakHoursReportPage from '@/pages/reports/peak-hours.vue'
import ExportCenterPage from '@/pages/reports/export-center.vue'

describe('reports pages', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetReportsForTesting()
  })

  it('renders integer centavo revenue and trip totals and triggers CSV downloads', async () => {
    const tripsWrapper = mount(TripsReportPage)
    expect(tripsWrapper.text()).toContain('₱88,940.00')

    const exportBtn = tripsWrapper
      .findAll('button')
      .find((button) => button.text().includes('Download CSV'))
    expect(exportBtn).toBeDefined()
    await exportBtn!.trigger('click')
    expect(HTMLAnchorElement.prototype.click).toHaveBeenCalledTimes(1)

    const revenueWrapper = mount(RevenueReportPage)
    expect(revenueWrapper.text()).toContain('₱1,124,500.00')
    expect(revenueWrapper.text()).toContain('₱168,675.00')
    expect(revenueWrapper.text()).toContain('₱955,825.00')
  })

  it('reflects live cancellation fee and surge cap settings across analytical reports', () => {
    const { config, commitConfig } = usePlatformConfig()
    const committed = commitConfig(
      {
        ...config.value,
        cancellationFeeCentavos: 3000,
        maxBiddingSurgeCap: 2.15,
      },
      'Test custom policy bounds in reports.',
    )
    expect(committed.ok).toBe(true)

    const cancellationsWrapper = mount(CancellationsReportPage)
    expect(cancellationsWrapper.text()).toContain('₱30.00')

    const peakWrapper = mount(PeakHoursReportPage)
    expect(peakWrapper.text()).toContain('2.15x')
  })

  it('validates and creates scheduled exports in ExportCenterPage with audit log emission', async () => {
    const wrapper = mount(ExportCenterPage)
    const { logs } = useAuditLogs()

    const openModalBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('+ Schedule Report'))
    expect(openModalBtn).toBeDefined()
    await openModalBtn!.trigger('click')

    const saveBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Save Schedule'))
    expect(saveBtn).toBeDefined()
    await saveBtn!.trigger('click')
    expect(wrapper.text()).toContain('Enter a schedule title and valid recipient email.')

    const titleInput = wrapper.find('input[placeholder*="Weekly Toda"]')
    await titleInput.setValue('Morning Dispatch Briefing')

    const freshSaveBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Save Schedule'))
    await freshSaveBtn!.trigger('click')

    expect(wrapper.text()).toContain('Morning Dispatch Briefing')
    expect(logs.value[0]!.action).toBe('REPORT_SCHEDULE_CREATED')
  })
})
