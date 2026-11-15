export type ReportDateRange = 'today' | 'last-7-days' | 'last-30-days' | 'this-quarter'

export type ReportDispatchModeFilter = 'all-modes' | 'open-broadcast' | 'chosen-driver'

export interface ReportFilterValues {
  dateRange: ReportDateRange
  cityZone: string
  dispatchMode: ReportDispatchModeFilter
}

export type ReportDispatchMode = 'open-broadcast' | 'chosen-driver'

export type ScheduledExportFormat = 'CSV' | 'PDF' | 'Excel'

export interface TripReportRow {
  date: string
  zoneKey: string
  zoneLabel: string
  dispatchMode: ReportDispatchMode
  totalRides: number
  completed: number
  cancelled: number
  totalKm: number
  grossVolumeCentavos: number
}

export interface RevenueSummaryRow {
  period: string
  zoneKey: string
  zoneLabel: string
  grossVolumeCentavos: number
  platformCommissionCentavos: number
  driverTakeHomeCentavos: number
  effectiveCutPercent: string
}

export interface DriverPerformanceRow {
  driver: string
  plateNumber: string
  zoneKey: string
  dispatchMode: ReportDispatchMode
  trips: number
  rating: number
  acceptanceRate: string
  cancellationRate: string
  onTimeRate: string
}

export interface RiderCohortRow {
  cohort: string
  zoneKey: string
  corridorFocus: string
  ridersCount: number
  retentionRate: string
  avgMonthlySpendCentavos: number
}

export type CancellationCauseResponsibility =
  | 'driver_fault'
  | 'passenger_fault'
  | 'system_fault'
  | 'no_fault'

export interface CancellationCauseSeedRow {
  reason: string
  zoneKey: string
  count: number
  responsibility: CancellationCauseResponsibility
  usesPlatformCancellationFee: boolean
  feeNote: string
}

export interface CancellationCauseRow {
  reason: string
  zoneKey: string
  count: number
  responsibility: CancellationCauseResponsibility
  feeCentavos: number
  feeNote: string
}

export interface DemandWindowRow {
  timeWindow: string
  zoneKey: string
  corridorLabel: string
  period: string
  avgSurge: number
  rideRequests: number
  driverUtilization: string
}

export interface ExpiryForecastRow {
  month: string
  zoneKey: string
  ltoLicensesExpiring: number
  todaMtopExpiring: number
  orCrExpiring: number
  insuranceExpiring: number
  complianceRate: string
}

export interface ScheduledReport {
  id: string
  name: string
  frequency: 'Daily' | 'Weekly' | 'Monthly'
  format: ScheduledExportFormat
  recipients: string
  timeSchedule: string
  isActive: boolean
}

export interface GeneratedExportRecord {
  id: string
  filename: string
  reportCategory: string
  format: 'CSV'
  size: string
  generatedAt: string
}

export interface CreateScheduleInput {
  name: string
  frequency: ScheduledReport['frequency']
  format: ScheduledExportFormat
  recipients: string
  timeSchedule?: string
}

export type ReportActionResult = { ok: true } | { ok: false; error: string }
