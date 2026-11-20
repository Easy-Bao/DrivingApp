import { resetDispatchForTesting } from '@/features/trips/composables/use-dispatch'
import { resetSafetyForTesting } from '@/features/trips/composables/use-safety'
import { resetTripRecordsForTesting } from '@/features/trips/composables/use-trips'

export type {
  BidOffer,
  BidOfferStatus,
  BidSession,
  BidSessionStatus,
  CancellationCase,
  CancellationResponsibility,
  DispatchZone,
  DisputeStatus,
  LiveDispatchItem,
  ReportCategory,
  ReportSeverity,
  ReportStatus,
  ReporterRole,
  SafetyReportRecord,
  SosIncident,
  SosSeverity,
  SosStatus,
  TripActionResult,
  TripRecord,
  TripStatus,
} from '@/features/trips/types'

export { SAFETY_CATEGORY_LABELS } from '@/features/trips/data/trips.seed'
export { tripStatusTone, useTrips } from '@/features/trips/composables/use-trips'
export {
  bidSessionStatusTone,
  useBiddingSessions,
  useDispatch,
} from '@/features/trips/composables/use-dispatch'
export {
  formatSafetyStatusLabel,
  safetySeverityTone,
  safetyStatusTone,
  useCancellationDisputes,
  useSafetyReports,
  useSosAlerts,
  type ModerateReportInput,
  type ResolveDisputeInput,
} from '@/features/trips/composables/use-safety'

export { default as SosLocationModal } from '@/features/trips/components/SosLocationModal.vue'
export { default as TripDetailsModal } from '@/features/trips/components/TripDetailsModal.vue'

export function resetTripsForTesting(): void {
  resetTripRecordsForTesting()
  resetDispatchForTesting()
  resetSafetyForTesting()
}
