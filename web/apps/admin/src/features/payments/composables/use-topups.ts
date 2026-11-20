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
    const request = getRequestById(id)
    if (!request || request.status !== 'Pending') return false

    request.status = 'Verified'
    request.currentBalanceCentavos += request.amountCentavos
    syncTopupCreditToLedger(request)

    appendAuditLog({
      action: 'WALLET_TOPUP_VERIFIED',
      targetEntity: `${request.id} (${request.driverName})`,
      severity: 'Info',
      payload: {
        amountCentavos: request.amountCentavos,
        amountFormatted: formatCentavos(request.amountCentavos),
        referenceCode: request.referenceCode,
      },
    })
    return true
  }

  function rejectRequest(id: string, reason: string): boolean {
    const request = getRequestById(id)
    const trimmedReason = reason.trim()
    if (!request || request.status !== 'Pending' || !trimmedReason) return false

    request.status = 'Rejected'
    request.rejectionReason = trimmedReason

    appendAuditLog({
      action: 'WALLET_TOPUP_REJECTED',
      targetEntity: `${request.id} (${request.driverName})`,
      severity: 'Warning',
      payload: {
        amountCentavos: request.amountCentavos,
        referenceCode: request.referenceCode,
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
