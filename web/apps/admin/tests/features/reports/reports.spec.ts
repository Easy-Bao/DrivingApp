import { beforeEach, describe, expect, it } from 'vitest'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import {
  resetReportsForTesting,
  useCancellationReports,
  useExportCenter,
  usePeakHoursReports,
  useRevenueReports,
  useRiderCohortReports,
  useTripReports,
} from '@/features/reports'

describe('reports feature stores', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetReportsForTesting()
  })

  it('stores trip, revenue, and rider cohort financials as integer centavos', () => {
    const { rows } = useTripReports()
    const { summaries } = useRevenueReports()
    const { cohorts } = useRiderCohortReports()

    expect(rows.value[0]!.grossVolumeCentavos).toBe(8894000)

    const firstRevenue = summaries.value[0]!
    expect(firstRevenue.grossVolumeCentavos).toBe(112450000)
    expect(firstRevenue.platformCommissionCentavos).toBe(16867500)
    expect(firstRevenue.driverTakeHomeCentavos).toBe(95582500)
    expect(firstRevenue.platformCommissionCentavos + firstRevenue.driverTakeHomeCentavos).toBe(
      firstRevenue.grossVolumeCentavos,
    )

    expect(cohorts.value[0]!.avgMonthlySpendCentavos).toBe(78000)
  })

  it('tracks live cancellation fee and surge ceiling from platform configuration', () => {
    const { config, commitConfig } = usePlatformConfig()
    const committed = commitConfig(
      {
        ...config.value,
        cancellationFeeCentavos: 2500,
        maxBiddingSurgeCap: 2.0,
      },
      'Adjust cancellation penalty and valid surge cap for demand window test.',
    )
    expect(committed.ok).toBe(true)

    const { causes } = useCancellationReports()
    const { maxSurgeCapLabel } = usePeakHoursReports()

    const passengerFaultCause = causes.value.find(
      (item) => item.responsibility === 'passenger_fault',
    )
    expect(passengerFaultCause).toBeDefined()
    expect(passengerFaultCause!.feeCentavos).toBe(2500)
    expect(passengerFaultCause!.feeNote).toContain('₱25.00')
    expect(maxSurgeCapLabel.value).toBe('2.00x')
  })

  it('validates export schedules, keeps generated CSV metadata honest, and writes audit logs', () => {
    const { scheduledReports, recentExports, activeScheduleCount, createSchedule, toggleSchedule } =
      useExportCenter()
    const { logs } = useAuditLogs()

    expect(recentExports.value.every((item) => item.format === 'CSV')).toBe(true)

    const initialCount = scheduledReports.value.length
    const badTitle = createSchedule({
      name: ' ',
      frequency: 'Weekly',
      format: 'CSV',
      recipients: 'ops@easyride.ph',
    })
    expect(badTitle.ok).toBe(false)

    const badEmail = createSchedule({
      name: 'Daily Audit',
      frequency: 'Daily',
      format: 'CSV',
      recipients: 'not-an-email',
    })
    expect(badEmail.ok).toBe(false)
    expect(scheduledReports.value.length).toBe(initialCount)

    const created = createSchedule({
      name: 'Weekly TODA Payout Reconciliation',
      frequency: 'Weekly',
      format: 'CSV',
      recipients: 'finance@easyride.ph',
      timeSchedule: 'Every Monday at 09:00 AM PHT',
    })
    expect(created.ok).toBe(true)
    expect(scheduledReports.value[0]!.id).toBe('SCH-05')
    expect(activeScheduleCount.value).toBe(4)
    expect(logs.value[0]!.action).toBe('REPORT_SCHEDULE_CREATED')

    const toggled = toggleSchedule('SCH-05')
    expect(toggled.ok).toBe(true)
    expect(scheduledReports.value[0]!.isActive).toBe(false)
    expect(logs.value[0]!.action).toBe('REPORT_SCHEDULE_TOGGLED')
  })
})
