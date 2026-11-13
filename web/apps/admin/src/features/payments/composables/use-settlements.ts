import { computed, ref } from 'vue'

export type CashOutcome = 'paid' | 'partial' | 'refused' | 'unpaid' | 'disputed'
export type SettlementResolutionState = 'reconciled' | 'pending_review' | 'waived'

export interface RideSettlementRecord {
  id: string
  rideId: string
  driverId: string
  driverName: string
  driverPhone: string
  plateNumber: string
  passengerName: string
  passengerPhone: string
  routeSummary: string
  grossFareCentavos: number
  commissionBps: number
  tipCentavos: number
  cashReceivedCentavos: number
  cashChangeCentavos: number
  cashOutcome: CashOutcome
  resolutionState: SettlementResolutionState
  reportedAt: string
  notes: string
  resolutionNotes: string
  resolvedAt?: string
}

export function getPlatformFeeCentavos(record: RideSettlementRecord): number {
  return Math.round((record.grossFareCentavos * record.commissionBps) / 10000)
}

export function getShortfallCentavos(record: RideSettlementRecord): number {
  return Math.max(0, record.grossFareCentavos - record.cashReceivedCentavos)
}

const initialSettlements: RideSettlementRecord[] = [
  {
    id: 'STL-9401',
    rideId: 'TRP-7016-8841',
    driverId: 'DRV-104',
    driverName: 'Javier Santos',
    driverPhone: '+63 917 987 6543',
    plateNumber: '5519-NB',
    passengerName: 'Althea Mae Villanueva',
    passengerPhone: '+63 935 812 4091',
    routeSummary: 'Brgy. San Pedro -> Agora Public Market',
    grossFareCentavos: 6000,
    commissionBps: 1500,
    tipCentavos: 0,
    cashReceivedCentavos: 4000,
    cashChangeCentavos: 0,
    cashOutcome: 'partial',
    resolutionState: 'pending_review',
    reportedAt: '12 mins ago',
    notes: 'Passenger handed PHP 40 due to missing small bills after drop-off.',
    resolutionNotes: '',
  },
  {
    id: 'STL-9400',
    rideId: 'TRP-7016-8835',
    driverId: 'DRV-102',
    driverName: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    plateNumber: '4912-NC',
    passengerName: 'Carlo Magno Ocampo',
    passengerPhone: '+63 917 650 3182',
    routeSummary: 'Pagadian Integrated Terminal -> Brgy. Gatas',
    grossFareCentavos: 8500,
    commissionBps: 1500,
    tipCentavos: 0,
    cashReceivedCentavos: 0,
    cashChangeCentavos: 0,
    cashOutcome: 'disputed',
    resolutionState: 'pending_review',
    reportedAt: '38 mins ago',
    notes: 'Driver reported passenger disputed final agreed bidding fare at destination.',
    resolutionNotes: '',
  },
  {
    id: 'STL-9399',
    rideId: 'TRP-7016-8819',
    driverId: 'DRV-103',
    driverName: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    plateNumber: '9021-ND',
    passengerName: 'Jessa Mae Lim',
    passengerPhone: '+63 926 301 7742',
    routeSummary: 'Brgy. Balangasan -> Provincial Capitol Complex',
    grossFareCentavos: 7000,
    commissionBps: 1500,
    tipCentavos: 0,
    cashReceivedCentavos: 0,
    cashChangeCentavos: 0,
    cashOutcome: 'refused',
    resolutionState: 'pending_review',
    reportedAt: '1 hour ago',
    notes: 'Passenger exited near rotunda before handing over trip fare.',
    resolutionNotes: '',
  },
  {
    id: 'STL-9398',
    rideId: 'TRP-7016-8790',
    driverId: 'DRV-101',
    driverName: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    plateNumber: '1284-ND',
    passengerName: 'Mark Anthony Reyes',
    passengerPhone: '+63 945 204 8810',
    routeSummary: 'Santiago District -> ZDS Medical Center',
    grossFareCentavos: 5500,
    commissionBps: 1500,
    tipCentavos: 1000,
    cashReceivedCentavos: 10000,
    cashChangeCentavos: 3500,
    cashOutcome: 'paid',
    resolutionState: 'reconciled',
    reportedAt: '2 hours ago',
    notes: 'Exact PHP 55 fare plus PHP 10 driver tip collected from PHP 100 bill.',
    resolutionNotes: 'Matched commission deduction against prepaid driver wallet ledger.',
    resolvedAt: 'Today, 09:40 AM',
  },
  {
    id: 'STL-9397',
    rideId: 'TRP-7016-8762',
    driverId: 'DRV-106',
    driverName: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    plateNumber: '3391-ND',
    passengerName: 'Kristine Joy Navarro',
    passengerPhone: '+63 998 411 6620',
    routeSummary: 'Brgy. Santa Lucia -> Dao Commercial District',
    grossFareCentavos: 4500,
    commissionBps: 1500,
    tipCentavos: 0,
    cashReceivedCentavos: 0,
    cashChangeCentavos: 0,
    cashOutcome: 'unpaid',
    resolutionState: 'waived',
    reportedAt: 'Yesterday, 05:15 PM',
    notes: 'Passenger phone battery died while arranging cash withdrawal; trip flagged.',
    resolutionNotes: 'Platform fee rebated to driver after passenger confirmed late transfer.',
    resolvedAt: 'Yesterday, 06:05 PM',
  },
]

const settlementRecords = ref<RideSettlementRecord[]>(initialSettlements)

export function useSettlements() {
  const pendingReviewCount = computed(
    () =>
      settlementRecords.value.filter((item) => item.resolutionState === 'pending_review').length,
  )

  const getSettlementById = (id: string) => settlementRecords.value.find((item) => item.id === id)

  const reconcileSettlement = (id: string, resolutionNotes: string): boolean => {
    const target = settlementRecords.value.find((item) => item.id === id)
    if (!target || target.resolutionState !== 'pending_review') return false

    target.cashOutcome = 'paid'
    target.cashReceivedCentavos = target.grossFareCentavos + target.tipCentavos
    target.cashChangeCentavos = 0
    target.resolutionState = 'reconciled'
    target.resolutionNotes =
      resolutionNotes.trim() || 'Cash fare verified paid and commission ledger reconciled.'
    target.resolvedAt = 'Just now'
    return true
  }

  const waiveShortfall = (id: string, reason: string): boolean => {
    const target = settlementRecords.value.find((item) => item.id === id)
    if (!target || target.resolutionState !== 'pending_review' || !reason.trim()) return false

    target.resolutionState = 'waived'
    target.resolutionNotes = reason.trim()
    target.resolvedAt = 'Just now'
    return true
  }

  return {
    settlementRecords,
    pendingReviewCount,
    getSettlementById,
    reconcileSettlement,
    waiveShortfall,
  }
}
