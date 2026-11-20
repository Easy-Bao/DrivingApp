import { computed, ref } from 'vue'
import {
  SEED_CANCELLATION_CAUSES,
  SEED_DEMAND_WINDOWS,
  SEED_DRIVER_PERFORMANCE,
  SEED_EXPIRY_FORECAST,
  SEED_RECENT_EXPORTS,
  SEED_REVENUE_SUMMARIES,
  SEED_RIDER_COHORTS,
  SEED_SCHEDULED_REPORTS,
  SEED_TRIP_REPORTS,
} from '@/features/reports/data/reports.seed'
import type {
  CancellationCauseRow,
  CreateScheduleInput,
  DemandWindowRow,
  DriverPerformanceRow,
  ExpiryForecastRow,
  GeneratedExportRecord,
  ReportActionResult,
  ReportFilterValues,
  RevenueSummaryRow,
  RiderCohortRow,
  ScheduledReport,
  TripReportRow,
} from '@/features/reports/types'
import { useAuditLogs, usePlatformConfig } from '@/features/settings'
import { exportToCsv, formatCentavos } from '@/shared'

export const DEFAULT_REPORT_FILTERS: ReportFilterValues = {
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  dispatchMode: 'all-modes',
}

export function createDefaultReportFilters(): ReportFilterValues {
  return { ...DEFAULT_REPORT_FILTERS }
}

export function hasCustomReportFilters(filters: ReportFilterValues): boolean {
  return (
    filters.dateRange !== DEFAULT_REPORT_FILTERS.dateRange ||
    filters.cityZone !== DEFAULT_REPORT_FILTERS.cityZone ||
    filters.dispatchMode !== DEFAULT_REPORT_FILTERS.dispatchMode
  )
}

function cloneScheduledReports(source: readonly ScheduledReport[]): ScheduledReport[] {
  return source.map((item) => ({ ...item }))
}

function cloneRecentExports(source: readonly GeneratedExportRecord[]): GeneratedExportRecord[] {
  return source.map((item) => ({ ...item }))
}

const tripRowsRef = ref<TripReportRow[]>(SEED_TRIP_REPORTS.map((row) => ({ ...row })))
const revenueRowsRef = ref<RevenueSummaryRow[]>(SEED_REVENUE_SUMMARIES.map((row) => ({ ...row })))
const driverPerformanceRef = ref<DriverPerformanceRow[]>(
  SEED_DRIVER_PERFORMANCE.map((row) => ({ ...row })),
)
const riderCohortsRef = ref<RiderCohortRow[]>(SEED_RIDER_COHORTS.map((row) => ({ ...row })))
const demandWindowsRef = ref<DemandWindowRow[]>(SEED_DEMAND_WINDOWS.map((row) => ({ ...row })))
const expiryForecastRef = ref<ExpiryForecastRow[]>(SEED_EXPIRY_FORECAST.map((row) => ({ ...row })))
const scheduledReportsRef = ref<ScheduledReport[]>(cloneScheduledReports(SEED_SCHEDULED_REPORTS))
const recentExportsRef = ref<GeneratedExportRecord[]>(cloneRecentExports(SEED_RECENT_EXPORTS))
let nextScheduleSequence = SEED_SCHEDULED_REPORTS.length + 1

const EMAIL_SEGMENT_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function hasValidEmailList(raw: string): boolean {
  const parts = raw
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)
  return parts.length > 0 && parts.every((part) => EMAIL_SEGMENT_RE.test(part))
}

function centavosToCsvPhp(centavos: number): string {
  return (centavos / 100).toFixed(2)
}

export function resetReportsForTesting(): void {
  tripRowsRef.value = SEED_TRIP_REPORTS.map((row) => ({ ...row }))
  revenueRowsRef.value = SEED_REVENUE_SUMMARIES.map((row) => ({ ...row }))
  driverPerformanceRef.value = SEED_DRIVER_PERFORMANCE.map((row) => ({ ...row }))
  riderCohortsRef.value = SEED_RIDER_COHORTS.map((row) => ({ ...row }))
  demandWindowsRef.value = SEED_DEMAND_WINDOWS.map((row) => ({ ...row }))
  expiryForecastRef.value = SEED_EXPIRY_FORECAST.map((row) => ({ ...row }))
  scheduledReportsRef.value = cloneScheduledReports(SEED_SCHEDULED_REPORTS)
  recentExportsRef.value = cloneRecentExports(SEED_RECENT_EXPORTS)
  nextScheduleSequence = SEED_SCHEDULED_REPORTS.length + 1
}

export function useTripReports() {
  function filterTripRows(filters: ReportFilterValues): TripReportRow[] {
    return tripRowsRef.value.filter((row) => {
      const matchesZone = filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone
      const matchesMode =
        filters.dispatchMode === 'all-modes' || row.dispatchMode === filters.dispatchMode
      const matchesDate = filters.dateRange !== 'today' || row.date === '2026-11-12'
      return matchesZone && matchesMode && matchesDate
    })
  }

  function exportTripRows(rowsToExport: readonly TripReportRow[]): void {
    exportToCsv(
      'trip-volume-report.csv',
      ['Date', 'Zone', 'Requested', 'Completed', 'Cancelled', 'Distance (km)', 'Gross (PHP)'],
      rowsToExport.map((row) => [
        row.date,
        row.zoneLabel,
        String(row.totalRides),
        String(row.completed),
        String(row.cancelled),
        String(row.totalKm),
        centavosToCsvPhp(row.grossVolumeCentavos),
      ]),
    )
  }

  return { rows: tripRowsRef, filterTripRows, exportTripRows }
}

export function useRevenueReports() {
  function filterRevenueRows(filters: ReportFilterValues): RevenueSummaryRow[] {
    return revenueRowsRef.value.filter(
      (row) => filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone,
    )
  }

  function exportRevenueRows(rowsToExport: readonly RevenueSummaryRow[]): void {
    exportToCsv(
      'revenue-commission-report.csv',
      [
        'Period',
        'Corridor',
        'Gross Bookings (PHP)',
        'Platform Commission (PHP)',
        'Driver Cash Take-Home (PHP)',
        'Effective Cut',
      ],
      rowsToExport.map((summary) => [
        summary.period,
        summary.zoneLabel,
        centavosToCsvPhp(summary.grossVolumeCentavos),
        centavosToCsvPhp(summary.platformCommissionCentavos),
        centavosToCsvPhp(summary.driverTakeHomeCentavos),
        summary.effectiveCutPercent,
      ]),
    )
  }

  return { summaries: revenueRowsRef, filterRevenueRows, exportRevenueRows }
}

export function useDriverPerformanceReports() {
  function filterPerformanceRows(filters: ReportFilterValues): DriverPerformanceRow[] {
    return driverPerformanceRef.value.filter((row) => {
      const matchesZone = filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone
      const matchesMode =
        filters.dispatchMode === 'all-modes' || row.dispatchMode === filters.dispatchMode
      return matchesZone && matchesMode
    })
  }

  function exportPerformanceRows(rowsToExport: readonly DriverPerformanceRow[]): void {
    exportToCsv(
      'driver-performance.csv',
      ['Driver', 'Plate', 'Trips', 'Rating', 'Acceptance', 'Cancellation', 'Punctuality'],
      rowsToExport.map((metric) => [
        metric.driver,
        metric.plateNumber,
        String(metric.trips),
        String(metric.rating),
        metric.acceptanceRate,
        metric.cancellationRate,
        metric.onTimeRate,
      ]),
    )
  }

  return { performanceList: driverPerformanceRef, filterPerformanceRows, exportPerformanceRows }
}

export function useRiderCohortReports() {
  function filterCohortRows(filters: ReportFilterValues): RiderCohortRow[] {
    return riderCohortsRef.value.filter(
      (row) => filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone,
    )
  }

  function totalCohortRiders(cohorts: readonly RiderCohortRow[]): number {
    return cohorts.reduce((sum, row) => sum + row.ridersCount, 0)
  }

  function exportCohortRows(rowsToExport: readonly RiderCohortRow[]): void {
    exportToCsv(
      'passenger-cohorts.csv',
      [
        'Cohort Segment',
        'Primary Zone',
        'Active Passengers',
        '30-Day Retention',
        'Avg Spend (PHP)',
      ],
      rowsToExport.map((cohort) => [
        cohort.cohort,
        cohort.corridorFocus,
        String(cohort.ridersCount),
        cohort.retentionRate,
        centavosToCsvPhp(cohort.avgMonthlySpendCentavos),
      ]),
    )
  }

  return {
    cohorts: riderCohortsRef,
    filterCohortRows,
    totalCohortRiders,
    exportCohortRows,
  }
}

export function useCancellationReports() {
  const { config } = usePlatformConfig()

  const causes = computed<CancellationCauseRow[]>(() =>
    SEED_CANCELLATION_CAUSES.map((seed) => {
      const feeCentavos = seed.usesPlatformCancellationFee
        ? config.value.cancellationFeeCentavos
        : 0
      const feeNote = seed.usesPlatformCancellationFee
        ? `Standard ${formatCentavos(feeCentavos)} Fee Applied`
        : seed.feeNote
      return {
        reason: seed.reason,
        zoneKey: seed.zoneKey,
        count: seed.count,
        responsibility: seed.responsibility,
        feeCentavos,
        feeNote,
      }
    }),
  )

  function filterCauseRows(filters: ReportFilterValues): CancellationCauseRow[] {
    return causes.value.filter(
      (row) => filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone,
    )
  }

  function sharePercent(count: number, totalCount: number): string {
    if (totalCount === 0) return '0.0%'
    return `${((count / totalCount) * 100).toFixed(1)}%`
  }

  function exportCauseRows(rowsToExport: readonly CancellationCauseRow[]): void {
    const total = rowsToExport.reduce((sum, row) => sum + row.count, 0)
    exportToCsv(
      'cancellation-analysis.csv',
      ['Root Cause', 'Incidents', 'Share', 'Responsibility', 'Fee Rule'],
      rowsToExport.map((cause) => [
        cause.reason,
        String(cause.count),
        sharePercent(cause.count, total),
        cause.responsibility,
        `${formatCentavos(cause.feeCentavos)} (${cause.feeNote})`,
      ]),
    )
  }

  return { causes, filterCauseRows, sharePercent, exportCauseRows }
}

export function usePeakHoursReports() {
  const { config } = usePlatformConfig()

  const maxSurgeCapLabel = computed(() => `${config.value.maxBiddingSurgeCap.toFixed(2)}x`)

  function filterDemandRows(filters: ReportFilterValues): DemandWindowRow[] {
    return demandWindowsRef.value.filter(
      (row) => filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone,
    )
  }

  function exportDemandRows(rowsToExport: readonly DemandWindowRow[]): void {
    exportToCsv(
      'peak-hours-demand.csv',
      ['Time Window', 'Corridor', 'Classification', 'Surge Multiplier', 'Requests', 'Utilization'],
      rowsToExport.map((demand) => [
        demand.timeWindow,
        demand.corridorLabel,
        demand.period,
        `${demand.avgSurge.toFixed(2)}x`,
        String(demand.rideRequests),
        demand.driverUtilization,
      ]),
    )
  }

  return {
    demandWindows: demandWindowsRef,
    maxSurgeCapLabel,
    filterDemandRows,
    exportDemandRows,
  }
}

export function useDocumentExpiryReports() {
  function filterForecastRows(filters: ReportFilterValues): ExpiryForecastRow[] {
    return expiryForecastRef.value.filter(
      (row) => filters.cityZone === 'all-zones' || row.zoneKey === filters.cityZone,
    )
  }

  function totalAudits(row: ExpiryForecastRow): number {
    return row.ltoLicensesExpiring + row.todaMtopExpiring + row.orCrExpiring + row.insuranceExpiring
  }

  function exportForecastRows(rowsToExport: readonly ExpiryForecastRow[]): void {
    exportToCsv(
      'document-expiry-forecast.csv',
      [
        'Month',
        'LTO Licenses',
        'TODA MTOP Franchises',
        'LTO OR/CR',
        'Insurance',
        'Compliance Rate',
      ],
      rowsToExport.map((forecast) => [
        forecast.month,
        String(forecast.ltoLicensesExpiring),
        String(forecast.todaMtopExpiring),
        String(forecast.orCrExpiring),
        String(forecast.insuranceExpiring),
        forecast.complianceRate,
      ]),
    )
  }

  return {
    forecasts: expiryForecastRef,
    filterForecastRows,
    totalAudits,
    exportForecastRows,
  }
}

export function useExportCenter() {
  const { appendAuditLog } = useAuditLogs()

  const activeScheduleCount = computed(
    () => scheduledReportsRef.value.filter((schedule) => schedule.isActive).length,
  )

  function toggleSchedule(scheduleId: string): ReportActionResult {
    const target = scheduledReportsRef.value.find((item) => item.id === scheduleId)
    if (!target) {
      return { ok: false, error: `Schedule ${scheduleId} not found.` }
    }
    target.isActive = !target.isActive
    appendAuditLog({
      action: 'REPORT_SCHEDULE_TOGGLED',
      targetEntity: target.id,
      severity: 'Info',
      payload: { name: target.name, isActive: target.isActive },
    })
    return { ok: true }
  }

  function createSchedule(input: CreateScheduleInput): ReportActionResult {
    const name = input.name.trim()
    const recipients = input.recipients.trim()
    if (!name || !hasValidEmailList(recipients)) {
      return { ok: false, error: 'Enter a schedule title and valid recipient email.' }
    }

    const id = `SCH-${String(nextScheduleSequence).padStart(2, '0')}`
    nextScheduleSequence += 1

    scheduledReportsRef.value.unshift({
      id,
      name,
      frequency: input.frequency,
      format: input.format,
      recipients,
      timeSchedule: input.timeSchedule?.trim() || 'Daily at 08:00 AM PHT',
      isActive: true,
    })

    appendAuditLog({
      action: 'REPORT_SCHEDULE_CREATED',
      targetEntity: id,
      severity: 'Info',
      payload: { name, frequency: input.frequency, format: input.format, recipients },
    })

    return { ok: true }
  }

  function downloadGeneratedExport(record: GeneratedExportRecord): void {
    exportToCsv(
      record.filename,
      ['Filename', 'Report Category', 'Generated Region', 'Currency'],
      [[record.filename, record.reportCategory, 'Pagadian City, Zamboanga del Sur', 'PHP']],
    )
    appendAuditLog({
      action: 'REPORT_EXPORT_DOWNLOADED',
      targetEntity: record.id,
      severity: 'Info',
      payload: { filename: record.filename, reportCategory: record.reportCategory },
    })
  }

  return {
    scheduledReports: scheduledReportsRef,
    recentExports: recentExportsRef,
    activeScheduleCount,
    toggleSchedule,
    createSchedule,
    downloadGeneratedExport,
  }
}
