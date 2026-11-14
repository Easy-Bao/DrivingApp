import { computed, ref } from 'vue'
import { formatCentavos } from '@/shared'
import { useAuditLogs, usePlatformConfig } from '@/features/settings'
import { INITIAL_TOPUP_REQUESTS } from '@/features/payments/data/payments.seed'
import { syncTopupCreditToLedger } from '@/features/payments/composables/use-payments-ledger'
import type { TopUpRequest } from '@/features/payments/types'

const topUpRequests = ref<TopUpRequest[]>(INITIAL_TOPUP_REQUESTS.map((item) => ({ ...item })))

export function resetTopupsForTesting() {
  topUpRequests.value = INITIAL_TOPUP_REQUESTS.map((item) => ({ ...item }))
}

export function useTopups() {
  const { config } = usePlatformConfig()
  const { appendAuditLog } = useAuditLogs()

  const minDispatchBalanceCentavos = computed(() => config.value.minWalletBalanceCentavos)

  const pendingTopups = computed(() =>
    topUpRequests.value.filter((item) => item.status === 'Pending'),
  )

  function getRequestById(id: string): TopUpRequest | undefined {
    return topUpRequests.value.find((item) => item.id === id)
  }

  function verifyAndCredit(id: string): boolean {
    const req = getRequestById(id)
    if (!req || req.status !== 'Pending') return false

    req.status = 'Verified'
    req.currentBalanceCentavos += req.amountCentavos
    syncTopupCreditToLedger(req)

    appendAuditLog({
      action: 'WALLET_TOPUP_VERIFIED',
      targetEntity: `${req.id} (${req.driverName})`,
      severity: 'Info',
      payload: {
        amountCentavos: req.amountCentavos,
        amountFormatted: formatCentavos(req.amountCentavos),
        referenceCode: req.referenceCode,
      },
    })
    return true
  }

  function rejectRequest(id: string, reason: string): boolean {
    const req = getRequestById(id)
    const trimmedReason = reason.trim()
    if (!req || req.status !== 'Pending' || !trimmedReason) return false

    req.status = 'Rejected'
    req.rejectionReason = trimmedReason

    appendAuditLog({
      action: 'WALLET_TOPUP_REJECTED',
      targetEntity: `${req.id} (${req.driverName})`,
      severity: 'Warning',
      payload: {
        amountCentavos: req.amountCentavos,
        referenceCode: req.referenceCode,
        reason: trimmedReason,
      },
    })
    return true
  }

  return {
    topUpRequests: computed(() => topUpRequests.value),
    pendingTopups,
    minDispatchBalanceCentavos,
    getRequestById,
    verifyAndCredit,
    rejectRequest,
  }
}
