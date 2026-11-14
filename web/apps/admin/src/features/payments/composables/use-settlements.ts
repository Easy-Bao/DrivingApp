import { computed, ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import { INITIAL_SETTLEMENTS } from '@/features/payments/data/payments.seed'
import {
  getPlatformFeeCentavos,
  getShortfallCentavos,
} from '@/features/payments/domain/calculations'
import type { RideSettlementRecord } from '@/features/payments/types'

const settlements = ref<RideSettlementRecord[]>(INITIAL_SETTLEMENTS.map((item) => ({ ...item })))

export function resetSettlementsForTesting() {
  settlements.value = INITIAL_SETTLEMENTS.map((item) => ({ ...item }))
}

export function useSettlements() {
  const { appendAuditLog } = useAuditLogs()

  const pendingSettlements = computed(() =>
    settlements.value.filter((record) => record.resolutionState === 'pending_review'),
  )

  function getSettlementById(id: string): RideSettlementRecord | undefined {
    return settlements.value.find((record) => record.id === id)
  }

  function reconcileSettlement(id: string, note: string): boolean {
    const record = getSettlementById(id)
    if (!record || record.resolutionState !== 'pending_review') return false

    const resolutionNotes =
      note.trim() ||
      'Operator verified full cash receipt with passenger and reconciled 15% driver commission deduction.'

    record.cashOutcome = 'paid'
    record.cashReceivedCentavos = record.grossFareCentavos + record.tipCentavos
    record.cashChangeCentavos = 0
    record.resolutionState = 'reconciled'
    record.resolutionNotes = resolutionNotes
    record.resolvedAt = 'Just now'

    appendAuditLog({
      action: 'SETTLEMENT_RECONCILED',
      targetEntity: `${record.id} (${record.rideId})`,
      severity: 'Info',
      payload: {
        driverId: record.driverId,
        grossFareCentavos: record.grossFareCentavos,
        resolutionNotes,
      },
    })
    return true
  }

  function waiveShortfall(id: string, note: string): boolean {
    const record = getSettlementById(id)
    const trimmedNote = note.trim()
    if (!record || record.resolutionState !== 'pending_review' || !trimmedNote) return false

    record.resolutionState = 'waived'
    record.resolutionNotes = trimmedNote
    record.resolvedAt = 'Just now'

    appendAuditLog({
      action: 'SETTLEMENT_FEE_WAIVED',
      targetEntity: `${record.id} (${record.rideId})`,
      severity: 'Warning',
      payload: {
        driverId: record.driverId,
        shortfallCentavos: getShortfallCentavos(record),
        reason: trimmedNote,
      },
    })
    return true
  }

  return {
    settlements: computed(() => settlements.value),
    pendingSettlements,
    getSettlementById,
    getPlatformFeeCentavos,
    getShortfallCentavos,
    reconcileSettlement,
    waiveShortfall,
  }
}
