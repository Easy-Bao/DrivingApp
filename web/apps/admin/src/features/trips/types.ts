export type TripStatus = 'Completed' | 'In Progress' | 'Dispatching' | 'Cancelled'

export interface TripRecord {
  id: string
  rider: string
  riderPhone: string
  driver: string | null
  driverPhone: string | null
  plateNumber: string | null
  vehicleModel: string
  pickup: string
  dropoff: string
  fareCentavos: number
  distanceKm: number
  duration: string | null
  status: TripStatus
  timestamp: string
}

export type BidSessionStatus = 'open' | 'accepted' | 'cancelled' | 'expired' | 'declined'
export type BidOfferStatus = 'pending' | 'accepted' | 'declined' | 'expired'

export interface BidOffer {
  id: string
  driverName: string
  plate: string
  bodyUnit: string
  driverRating: number
  etaMinutes: number
  status: BidOfferStatus
}

export interface BidSession {
  id: string
  bookingRef: string
  passenger: string
  passengerPhone: string
  pickup: string
  dropoff: string
  systemEstimateCentavos: number
  passengerOfferCentavos: number
  tipAmountCentavos: number
  requestMode: 'Broadcast' | 'Targeted Driver'
  status: BidSessionStatus
  expiresIn: string
  createdAt: string
  note: string
  offers: BidOffer[]
}

export interface DispatchZone {
  name: string
  activeDrivers: number
  pendingRequests: number
  avgWait: string
  surge: string
}

export interface LiveDispatchItem {
  id: string
  rider: string
  driver: string | null
  eta: string
  status: string
  zone: string
}

export type CancellationResponsibility =
  | 'passenger_fault'
  | 'driver_fault'
  | 'system_fault'
  | 'no_fault'
  | 'safety_related'
  | 'pending_review'
  | 'operator_override'

export type DisputeStatus =
  | 'Under Review'
  | 'Resolved (Fee Upheld)'
  | 'Fee Waived & Overridden'
  | 'Closed'

export interface CancellationCase {
  id: string
  tripId: string
  cancelledBy: string
  route: string
  reason: string
  responsibility: CancellationResponsibility
  cancellationFeeCentavos: number
  feeChargedTo: string
  disputeStatus: DisputeStatus
  timestamp: string
}

export type ReporterRole = 'passenger' | 'driver'
export type ReportCategory =
  | 'unsafe_driving'
  | 'fare_dispute'
  | 'driver_identity_mismatch'
  | 'vehicle_mismatch'
  | 'harassment'
  | 'threat_or_violence'
  | 'route_issue'
  | 'fraud'
  | 'accident'
  | 'other'
export type ReportSeverity = 'standard' | 'high' | 'critical'
export type ReportStatus = 'submitted' | 'under_review' | 'resolved' | 'dismissed'

export interface SafetyReportRecord {
  id: string
  tripId: string
  reporterRole: ReporterRole
  reporterName: string
  reporterPhone: string
  reportedParty: string
  corridor: string
  category: ReportCategory
  severity: ReportSeverity
  status: ReportStatus
  narrative: string
  moderationNote?: string
  submittedAt: string
}

export type SosSeverity = 'Critical' | 'High'
export type SosStatus = 'Active' | 'Resolved'

export interface SosIncident {
  id: string
  tripId: string
  triggeredBy: string
  driverName: string
  driverPhone: string
  driverPlate: string
  riderName: string
  riderPhone: string
  corridor: string
  coords: string
  latitude: number
  longitude: number
  timeTriggered: string
  severity: SosSeverity
  status: SosStatus
  responderNotified: boolean
  resolutionSummary?: string
}

export type TripActionResult = { ok: true } | { ok: false; error: string }
