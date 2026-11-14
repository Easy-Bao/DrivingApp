import { computed, ref } from 'vue'
import { useAuditLogs, usePlatformConfig } from '@/features/settings'
import {
  RESPONSIBILITY_LABELS,
  SEED_CANCELLATION_CASES,
  SEED_SAFETY_REPORTS,
  SEED_SOS_INCIDENTS,
} from '@/features/trips/data/trips.seed'
import type {
  CancellationCase,
  CancellationResponsibility,
  ReportSeverity,
  ReportStatus,
  SafetyReportRecord,
  SosIncident,
  TripActionResult,
} from '@/features/trips/types'
import type { BadgeTone } from '@/shared'

function cloneDisputes(source: readonly CancellationCase[]): CancellationCase[] {
  return source.map((item) => ({ ...item }))
}

function cloneReports(source: readonly SafetyReportRecord[]): SafetyReportRecord[] {
  return source.map((item) => ({ ...item }))
}

function cloneAlerts(source: readonly SosIncident[]): SosIncident[] {
  return source.map((item) => ({ ...item }))
}

const disputesRef = ref<CancellationCase[]>(cloneDisputes(SEED_CANCELLATION_CASES))
const reportsRef = ref<SafetyReportRecord[]>(cloneReports(SEED_SAFETY_REPORTS))
const alertsRef = ref<SosIncident[]>(cloneAlerts(SEED_SOS_INCIDENTS))

export function safetySeverityTone(severity: ReportSeverity): BadgeTone {
  if (severity === 'critical') return 'danger'
  if (severity === 'high') return 'warning'
  return 'neutral'
}

export function safetyStatusTone(status: ReportStatus): BadgeTone {
  if (status === 'resolved') return 'success'
  if (status === 'under_review') return 'warning'
  if (status === 'submitted') return 'danger'
  return 'neutral'
}

export function formatSafetyStatusLabel(status: ReportStatus): string {
  switch (status) {
    case 'submitted':
      return 'Submitted'
    case 'under_review':
      return 'Under Review'
    case 'resolved':
      return 'Resolved'
    case 'dismissed':
      return 'Dismissed'
  }
}

export function resetSafetyForTesting() {
  disputesRef.value = cloneDisputes(SEED_CANCELLATION_CASES)
  reportsRef.value = cloneReports(SEED_SAFETY_REPORTS)
  alertsRef.value = cloneAlerts(SEED_SOS_INCIDENTS)
}

export interface ResolveDisputeInput {
  responsibility: CancellationResponsibility
  waiveFee: boolean
  auditNote: string
}

export function useCancellationDisputes() {
  const { appendAuditLog } = useAuditLogs()
  const { config } = usePlatformConfig()

  const defaultCancellationFeeCentavos = computed(() => config.value.cancellationFeeCentavos)

  function resolveDispute(caseId: string, input: ResolveDisputeInput): TripActionResult {
    const trimmedNote = input.auditNote.trim()
    if (!trimmedNote) {
      return { ok: false, error: 'Enter verification evidence or an operator reason.' }
    }
    const target = disputesRef.value.find((item) => item.id === caseId)
    if (!target) {
      return { ok: false, error: `Dispute ${caseId} not found.` }
    }

    target.responsibility = input.responsibility
    if (input.waiveFee) {
      target.cancellationFeeCentavos = 0
      target.feeChargedTo = `Waived (${trimmedNote})`
      target.disputeStatus = 'Fee Waived & Overridden'
    } else {
      if (target.cancellationFeeCentavos === 0 && defaultCancellationFeeCentavos.value > 0) {
        target.cancellationFeeCentavos = defaultCancellationFeeCentavos.value
      }
      target.disputeStatus = 'Resolved (Fee Upheld)'
    }

    appendAuditLog({
      action: 'DISPUTE_RESOLVED',
      targetEntity: `${target.id} (${target.tripId})`,
      severity: input.waiveFee ? 'Warning' : 'Info',
      payload: {
        responsibility: target.responsibility,
        waiveFee: input.waiveFee,
        reason: trimmedNote,
      },
    })

    return { ok: true }
  }

  return {
    disputes: disputesRef,
    responsibilityLabels: RESPONSIBILITY_LABELS,
    resolveDispute,
  }
}

export interface ModerateReportInput {
  status: ReportStatus
  moderationNote: string
}

export function useSafetyReports() {
  const { appendAuditLog } = useAuditLogs()

  const openReportCount = computed(
    () => reportsRef.value.filter((item) => item.status === 'submitted').length,
  )

  const criticalOpenCount = computed(
    () =>
      reportsRef.value.filter(
        (item) =>
          item.severity === 'critical' &&
          (item.status === 'submitted' || item.status === 'under_review'),
      ).length,
  )

  function moderateReport(reportId: string, input: ModerateReportInput): TripActionResult {
    const trimmedNote = input.moderationNote.trim()
    if (!trimmedNote) {
      return { ok: false, error: 'Enter an internal safety investigation note before saving.' }
    }
    const target = reportsRef.value.find((item) => item.id === reportId)
    if (!target) {
      return { ok: false, error: `Safety report ${reportId} not found.` }
    }

    target.status = input.status
    target.moderationNote = trimmedNote

    appendAuditLog({
      action: 'SAFETY_REPORT_MODERATED',
      targetEntity: `${target.id} (${target.tripId})`,
      severity: target.severity === 'critical' ? 'Critical' : 'Warning',
      payload: { status: input.status, moderationNote: trimmedNote },
    })
    return { ok: true }
  }

  return {
    reports: reportsRef,
    openReportCount,
    criticalOpenCount,
    safetySeverityTone,
    safetyStatusTone,
    formatSafetyStatusLabel,
    moderateReport,
  }
}

export function useSosAlerts() {
  const { appendAuditLog } = useAuditLogs()

  const activeAlertsCount = computed(
    () => alertsRef.value.filter((alert) => alert.status === 'Active').length,
  )

  const resolvedAlertsCount = computed(
    () => alertsRef.value.filter((alert) => alert.status === 'Resolved').length,
  )

  function notifyResponders(alertId: string): TripActionResult {
    const target = alertsRef.value.find((alert) => alert.id === alertId)
    if (!target) {
      return { ok: false, error: `SOS alert ${alertId} not found.` }
    }
    if (!target.responderNotified) {
      target.responderNotified = true
      appendAuditLog({
        action: 'SOS_RESPONDERS_NOTIFIED',
        targetEntity: `${target.id} (${target.tripId})`,
        severity: 'Critical',
        payload: { corridor: target.corridor, coords: target.coords },
      })
    }
    return { ok: true }
  }

  function resolveAlert(alertId: string, summary: string): TripActionResult {
    const trimmedSummary = summary.trim()
    if (!trimmedSummary) {
      return { ok: false, error: 'Confirm safety and provide a brief resolution note.' }
    }
    const target = alertsRef.value.find((alert) => alert.id === alertId)
    if (!target) {
      return { ok: false, error: `SOS alert ${alertId} not found.` }
    }
    if (target.status !== 'Active') {
      return { ok: false, error: `SOS alert ${alertId} is already resolved.` }
    }

    target.status = 'Resolved'
    target.resolutionSummary = trimmedSummary

    appendAuditLog({
      action: 'SOS_ALERT_RESOLVED',
      targetEntity: `${target.id} (${target.tripId})`,
      severity: 'Warning',
      payload: { summary: trimmedSummary },
    })
    return { ok: true }
  }

  return {
    alerts: alertsRef,
    activeAlertsCount,
    resolvedAlertsCount,
    notifyResponders,
    resolveAlert,
  }
}
