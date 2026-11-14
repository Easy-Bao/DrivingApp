<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import {
  ConfirmDialog,
  formatBpsAsPercent,
  formatCentavos,
  StatusBadge,
  ToastBanner,
  useSafeBack,
  useSafeRouteParam,
} from '@/shared'
import type { ToastTone } from '@/shared'
import { useSettlements } from '@/features/payments'

definePage({
  meta: { isDetail: true },
})

const settlementId = useSafeRouteParam('id')
const goBack = useSafeBack('/payments/settlements')
const {
  getSettlementById,
  getPlatformFeeCentavos,
  getShortfallCentavos,
  reconcileSettlement,
  waiveShortfall,
} = useSettlements()

const record = computed(() =>
  settlementId.value ? getSettlementById(settlementId.value) : undefined,
)

const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')
const showReconcileConfirm = ref(false)
const showWaiveConfirm = ref(false)
const reconcileNote = ref('')
const waiveNote = ref('')

function showToast(message: string, tone: ToastTone = 'success') {
  toastMessage.value = message
  toastTone.value = tone
}

function submitReconcile() {
  if (!record.value) return
  const ok = reconcileSettlement(record.value.id, reconcileNote.value)
  if (!ok) {
    showToast(`${record.value.id} has already been resolved.`, 'warning')
    return
  }
  showReconcileConfirm.value = false
  reconcileNote.value = ''
  showToast(`${record.value.id} marked paid and commission ledger reconciled.`)
}

function submitWaive() {
  if (!record.value) return
  const ok = waiveShortfall(record.value.id, waiveNote.value)
  if (!ok) {
    showToast('Provide a mandatory fee waiver justification note.', 'warning')
    return
  }
  showWaiveConfirm.value = false
  waiveNote.value = ''
  showToast(`Waived platform fee shortfall for ${record.value.id}.`, 'warning')
}
</script>

<template>
  <div class="space-y-6">
    <div v-if="!record" class="bg-white border border-neutral-200 p-8 text-center space-y-3">
      <h1 class="text-lg font-bold text-neutral-900">Settlement Record Not Found</h1>
      <p class="text-xs text-neutral-500">
        The requested settlement reference does not exist or has an invalid route identifier.
      </p>
      <button
        type="button"
        class="px-4 py-2 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
        @click="goBack"
      >
        Back to Cash Settlements
      </button>
    </div>

    <template v-else>
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <button
            type="button"
            class="inline-flex items-center space-x-1.5 text-xs font-medium text-neutral-500 hover:text-neutral-900 mb-2 cursor-pointer"
            @click="goBack"
          >
            <Icon icon="lucide:arrow-left" class="text-sm" aria-hidden="true" />
            <span>Back</span>
          </button>
          <div class="flex flex-wrap items-center gap-3">
            <h1 class="text-2xl font-bold tracking-tight text-neutral-900">
              Settlement {{ record.id }}
            </h1>
            <StatusBadge
              :label="record.resolutionState.replace('_', ' ')"
              :tone="
                record.resolutionState === 'reconciled'
                  ? 'success'
                  : record.resolutionState === 'pending_review'
                    ? 'warning'
                    : 'neutral'
              "
            />
          </div>
          <p class="text-sm text-neutral-500 mt-1">
            Ride {{ record.rideId }} · {{ record.routeSummary }} · Reported {{ record.reportedAt }}
          </p>
        </div>

        <div class="text-left sm:text-right">
          <div class="text-[11px] font-semibold uppercase tracking-wider text-neutral-500">
            Gross Trip Fare
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
          <h2 class="text-sm font-semibold text-neutral-900">
            Cash Outcome &amp; Commission Split
          </h2>
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
                :class="getShortfallCentavos(record) > 0 ? 'text-neutral-900' : 'text-neutral-600'"
              >
                {{ formatCentavos(getShortfallCentavos(record)) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4 text-xs">
        <div>
          <h2 class="text-sm font-semibold text-neutral-900">Incident &amp; Field Notes</h2>
          <p class="text-neutral-600 mt-1 leading-relaxed">{{ record.notes }}</p>
        </div>

        <div
          v-if="record.resolutionNotes"
          class="p-3 bg-neutral-50 border border-neutral-200 text-neutral-700"
        >
          <span class="font-semibold text-neutral-900">Resolution Log:</span>
          {{ record.resolutionNotes }}
        </div>

        <div
          v-if="record.resolutionState === 'pending_review'"
          class="pt-3 border-t border-neutral-100 flex flex-wrap items-center justify-end gap-2"
        >
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 bg-white text-neutral-800 font-semibold hover:bg-neutral-50 cursor-pointer"
            @click="showWaiveConfirm = true"
          >
            Waive Platform Fee
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 text-white font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="showReconcileConfirm = true"
          >
            Mark Full Fare Settled
          </button>
        </div>
      </div>

      <ConfirmDialog
        v-model:open="showReconcileConfirm"
        v-model:reason="reconcileNote"
        :title="`Reconcile ${record.id}`"
        description="Confirm that full cash payment was received from the passenger and lock the driver commission entry."
        confirm-label="Confirm Paid & Reconcile"
        reason-label="Verification Note (Optional)"
        reason-placeholder="e.g., Confirmed cash balance at TODA booth."
        @confirm="submitReconcile"
      />

      <ConfirmDialog
        v-model:open="showWaiveConfirm"
        v-model:reason="waiveNote"
        :title="`Waive Fee Shortfall · ${record.id}`"
        description="Rebate the platform commission charge on this dispute with an immutable audit justification."
        confirm-label="Confirm Fee Waiver"
        tone="rose"
        :require-reason="true"
        reason-label="Audit Justification (Required)"
        reason-placeholder="e.g., Passenger refused fare at barangay drop-off."
        @confirm="submitWaive"
      />
    </template>
  </div>
</template>
