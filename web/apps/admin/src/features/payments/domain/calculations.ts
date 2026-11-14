import type { DriverEarningSummary, RideSettlementRecord } from '@/features/payments/types'

export function getPlatformFeeCentavos(
  record: Pick<RideSettlementRecord, 'grossFareCentavos' | 'commissionBps'>,
): number {
  return Math.round((record.grossFareCentavos * record.commissionBps) / 10000)
}

export function getShortfallCentavos(
  record: Pick<
    RideSettlementRecord,
    'grossFareCentavos' | 'tipCentavos' | 'cashReceivedCentavos' | 'cashChangeCentavos'
  >,
): number {
  const totalDue = Math.max(0, record.grossFareCentavos + record.tipCentavos)
  const netCollected = Math.max(0, record.cashReceivedCentavos - record.cashChangeCentavos)
  return Math.max(0, totalDue - netCollected)
}

export function computePlatformCommissionCentavos(
  row: Pick<DriverEarningSummary, 'cashGrossCentavos' | 'commissionBps'>,
): number {
  return Math.round((row.cashGrossCentavos * row.commissionBps) / 10000)
}

export function computeDriverTakeHomeCentavos(
  row: Pick<DriverEarningSummary, 'cashGrossCentavos' | 'commissionBps'>,
): number {
  return row.cashGrossCentavos - computePlatformCommissionCentavos(row)
}
