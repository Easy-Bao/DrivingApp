<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { formatBpsAsPercent, formatCentavos } from '@/shared/utils/format'
import {
  getPlatformFeeCentavos,
  getShortfallCentavos,
  useSettlements,
} from '@/features/payments/composables/useSettlements'

definePage({
  meta: { isDetail: true },
})

const route = useRoute()
const router = useRouter()
const { getSettlementById, reconcileSettlement, waiveShortfall } = useSettlements()

const settlementId = computed(() => String(route.params.id ?? ''))
const record = computed(() => getSettlementById(settlementId.value))

const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'info'>('success')
const activeAction = ref<'reconcile' | 'waive' | null>(null)
const actionReason = ref('')

const confirmReconcile = () => {
  if (!record.value) return
  if (reconcileSettlement(record.value.id, actionReason.value)) {
    toastTone.value = 'success'
    toastMessage.value = `${record.value.id} marked paid and commission ledger reconciled.`
  }
  activeAction.value = null
  actionReason.value = ''
}

const confirmWaive = () => {
  if (!record.value) return
  if (!actionReason.value.trim()) return
  if (waiveShortfall(record.value.id, actionReason.value)) {
    toastTone.value = 'warning'
    toastMessage.value = `Commission shortfall waived for ${record.value.id} (${record.value.driverName}).`
  }
  activeAction.value = null
  actionReason.value = ''
}

const outcomeBadgeTone = computed(() => {
  const outcome = record.value?.cashOutcome
  if (outcome === 'paid') return 'success'
  if (outcome === 'partial') return 'warning'
  if (outcome === 'disputed' || outcome === 'refused') return 'danger'
  return 'neutral'
})

const resolutionBadgeLabel = computed(() => {
  const state = record.value?.resolutionState
  if (state === 'reconciled') return 'Reconciled'
  if (state === 'waived') return 'Fee Waived'
  return 'Needs Review'
})
</script>

<template>
  <div v-if="record" class="space-y-6 w-full pb-12">
    <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
      <div>
        <button
          type="button"
          @click="router.push('/payments/settlements')"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-white border border-neutral-200 text-neutral-700 text-xs font-medium hover:bg-neutral-50 transition-colors mb-3 cursor-pointer"
        >
          <Icon icon="lucide:arrow-left" class="w-3.5 h-3.5" />
          <span>Back to Cash Settlements</span>
        </button>
        <div class="flex flex-wrap items-center gap-2.5">
          <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
            Settlement {{ record.id }}
          </h1>
          <StatusBadge :label="record.cashOutcome.toUpperCase()" :tone="outcomeBadgeTone" />
          <StatusBadge
            :label="resolutionBadgeLabel"
            :tone="
              record.resolutionState === 'reconciled'
                ? 'success'
                : record.resolutionState === 'waived'
                  ? 'info'
                  : 'warning'
            "
          />
        </div>
        <p class="text-sm text-neutral-500 mt-1">
          Ride {{ record.rideId }} · {{ record.routeSummary }} · Reported {{ record.reportedAt }}
        </p>
      </div>

      <div class="text-left sm:text-right">
        <div class="text-[11px] font-semibold uppercase tracking-wider text-neutral-500">
          Gross Agreed Fare
        </div>
        <div class="text-2xl font-bold font-mono tabular-nums text-neutral-900">
          {{ formatCentavos(record.grossFareCentavos) }}
        </div>
      </div>
    </div>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="bg-white border border-neutral-200 p-5 space-y-3">
        <h2 class="text-sm font-semibold text-neutral-900">Driver &amp; Vehicle Details</h2>
        <div class="text-xs space-y-1.5">
          <div class="font-bold text-neutral-900 text-sm">{{ record.driverName }}</div>
          <div class="text-neutral-500 font-mono">
            {{ record.driverId }} · {{ record.driverPhone }} · Plate {{ record.plateNumber }}
          </div>
          <div class="pt-2 border-t border-neutral-100 text-neutral-600">
            <span class="font-semibold text-neutral-800">Passenger:</span>
            {{ record.passengerName }} ({{ record.passengerPhone }})
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-3">
        <h2 class="text-sm font-semibold text-neutral-900">Cash Outcome &amp; Commission Split</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
          <div>
            <div class="text-neutral-500">Cash Collected</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ formatCentavos(record.cashReceivedCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Change Returned</div>
            <div class="font-mono font-semibold text-neutral-700 mt-0.5">
              {{ formatCentavos(record.cashChangeCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">
              Platform Fee ({{ formatBpsAsPercent(record.commissionBps) }})
            </div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ formatCentavos(getPlatformFeeCentavos(record)) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Uncollected Shortfall</div>
            <div
              class="font-mono font-bold mt-0.5"
              :class="
                getShortfallCentavos(record) > 0 ? 'text-neutral-900 font-bold' : 'text-neutral-600'
              "
            >
              {{ formatCentavos(getShortfallCentavos(record)) }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 p-5 space-y-3">
      <h2 class="text-sm font-semibold text-neutral-900">
        Driver Incident Note &amp; Audit History
      </h2>
      <p
        class="text-xs text-neutral-700 leading-relaxed bg-neutral-50 border border-neutral-100 p-3"
      >
        {{ record.notes }}
      </p>
      <div
        v-if="record.resolutionNotes"
        class="text-xs text-neutral-800 bg-neutral-50 border border-neutral-200 p-3"
      >
        <div class="font-semibold">Resolution ({{ record.resolvedAt || 'Updated' }}):</div>
        <p class="mt-0.5">{{ record.resolutionNotes }}</p>
      </div>
    </div>

    <div
      v-if="record.resolutionState === 'pending_review'"
      class="bg-white border border-neutral-200 p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
    >
      <div class="text-xs text-neutral-600">
        Confirm whether full cash was subsequently settled or waive the platform commission
        deduction on the driver prepaid wallet.
      </div>
      <div class="flex flex-wrap items-center gap-2 shrink-0">
        <button
          type="button"
          @click="((actionReason = ''), (activeAction = 'waive'))"
          class="px-4 py-2 bg-white border border-neutral-200 text-neutral-700 text-xs font-semibold hover:bg-neutral-50 transition-colors cursor-pointer"
        >
          Waive Driver Commission Fee
        </button>
        <button
          type="button"
          @click="((actionReason = ''), (activeAction = 'reconcile'))"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
        >
          Mark Full Fare Settled
        </button>
      </div>
    </div>

    <ConfirmDialog
      :open="activeAction === 'reconcile'"
      title="Mark Cash Settlement Reconciled"
      :description="`Confirm that ${record.passengerName} settled the full ${formatCentavos(record.grossFareCentavos)} fare with ${record.driverName}.`"
      confirm-label="Confirm Paid & Reconcile"
      tone="emerald"
      @cancel="activeAction = null"
      @confirm="confirmReconcile"
    />

    <ConfirmDialog
      :open="activeAction === 'waive'"
      v-model:reason="actionReason"
      title="Waive Driver Commission Fee"
      :description="`Rebate the ${formatCentavos(getPlatformFeeCentavos(record))} platform commission deduction back to ${record.driverName}'s prepaid wallet.`"
      confirm-label="Confirm Fee Waiver"
      tone="rose"
      require-reason
      reason-label="Audit justification"
      reason-placeholder="Specify verification details for waiving platform commission..."
      @cancel="activeAction = null"
      @confirm="confirmWaive"
    />
  </div>

  <div v-else class="bg-white border border-neutral-200 p-12 text-center space-y-3">
    <Icon icon="lucide:file-search" class="w-8 h-8 text-neutral-400 mx-auto" />
    <h2 class="text-base font-semibold text-neutral-900">Settlement Record Not Found</h2>
    <p class="text-xs text-neutral-500">
      No cash settlement matches identifier "{{ settlementId }}".
    </p>
    <RouterLink
      to="/payments/settlements"
      class="inline-flex items-center px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800"
    >
      Return to Cash Settlements
    </RouterLink>
  </div>
</template>
