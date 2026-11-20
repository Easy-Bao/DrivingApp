<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import {
  ConfirmDialog,
  formatCentavos,
  getInitials,
  ModalDialog,
  StatusBadge,
  ToastBanner,
  useSafeBack,
  useSafeRouteParam,
} from '@/shared'
import type { ToastTone } from '@/shared'
import { useTopups } from '@/features/payments'

definePage({
  meta: { isDetail: true },
})

const requestId = useSafeRouteParam('id')
const goBack = useSafeBack('/payments/topups')
const { getRequestById, minDispatchBalanceCentavos, verifyAndCredit, rejectRequest } = useTopups()

const request = computed(() => (requestId.value ? getRequestById(requestId.value) : undefined))

const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')
const showProofModal = ref(false)
const showRejectConfirm = ref(false)
const rejectReason = ref('')

function showToast(message: string, tone: ToastTone = 'success') {
  toastMessage.value = message
  toastTone.value = tone
}

function statusTone(status: 'Pending' | 'Verified' | 'Rejected') {
  if (status === 'Verified') return 'success'
  if (status === 'Pending') return 'warning'
  return 'danger'
}

function approveAndCredit() {
  if (!request.value) return
  const ok = verifyAndCredit(request.value.id)
  if (!ok) {
    showToast(`${request.value.id} was already processed.`, 'warning')
    return
  }
  showToast(
    `Successfully verified ${request.value.id} and credited ${formatCentavos(request.value.amountCentavos)} to ${request.value.driverName}'s wallet.`,
  )
}

function submitRejection() {
  if (!request.value) return
  const ok = rejectRequest(request.value.id, rejectReason.value)
  if (!ok) {
    showToast('Provide a clear rejection reason before declining proof.', 'warning')
    return
  }
  showRejectConfirm.value = false
  rejectReason.value = ''
  showToast(`Rejected ${request.value.id} and notified ${request.value.driverName}.`, 'warning')
}
</script>

<template>
  <div class="space-y-6">
    <div v-if="!request" class="bg-white border border-neutral-200 p-8 text-center space-y-3">
      <h1 class="text-lg font-bold text-neutral-900">Top-Up Request Not Found</h1>
      <p class="text-xs text-neutral-500">
        The requested top-up verification record does not exist or has a malformed reference.
      </p>
      <button
        type="button"
        class="px-4 py-2 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
        @click="goBack"
      >
        Back to Top-Up Queue
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
              Top-Up Request {{ request.id }}
            </h1>
            <StatusBadge :label="request.status" :tone="statusTone(request.status)" />
          </div>
          <p class="text-xs text-neutral-500 mt-1">
            Submitted {{ request.submittedAt }} · Reference {{ request.referenceCode }}
          </p>
        </div>

        <div class="text-left sm:text-right">
          <div class="text-[11px] font-semibold uppercase tracking-wider text-neutral-500">
            Requested Credit
          </div>
          <div class="text-3xl font-extrabold text-neutral-900 mt-0.5 font-mono tabular-nums">
            {{ formatCentavos(request.amountCentavos) }}
          </div>
        </div>
      </div>

      <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div
          class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-neutral-100"
        >
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm shrink-0"
            >
              {{ getInitials(request.driverName, 'DR') }}
            </div>
            <div>
              <h2 class="font-bold text-sm text-neutral-900">{{ request.driverName }}</h2>
              <p class="text-xs font-mono text-neutral-500">{{ request.driverPhone }}</p>
            </div>
          </div>
          <span
            class="px-2.5 py-1 text-xs font-semibold w-fit"
            :class="
              request.currentBalanceCentavos < minDispatchBalanceCentavos
                ? 'bg-neutral-100 text-neutral-900 border border-neutral-300'
                : 'bg-neutral-50 text-neutral-700 border border-neutral-200'
            "
          >
            {{
              request.currentBalanceCentavos < minDispatchBalanceCentavos
                ? `Below Dispatch Threshold (< ${formatCentavos(minDispatchBalanceCentavos)} min)`
                : 'Dispatch Eligible'
            }}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Assigned Vehicle</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              Plate: {{ request.vehiclePlate }}
            </div>
            <div class="text-[11px] text-neutral-500">{{ request.bodyUnit }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Current Wallet Balance</div>
            <div class="font-mono font-bold mt-0.5 tabular-nums text-neutral-900">
              {{ formatCentavos(request.currentBalanceCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Balance After Approval</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5 tabular-nums">
              {{
                formatCentavos(
                  request.currentBalanceCentavos +
                    (request.status === 'Pending' ? request.amountCentavos : 0),
                )
              }}
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 bg-white border border-neutral-200 p-5 space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">
              Company Payment Method &amp; Reference
            </h2>
            <span class="text-xs font-mono text-neutral-500">{{
              request.transactionTimestamp
            }}</span>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Transfer Mechanism</div>
              <div class="font-semibold text-neutral-900 mt-0.5 flex items-center space-x-1.5">
                <Icon
                  :icon="
                    request.paymentMethod.includes('QR') ? 'lucide:qr-code' : 'lucide:building-2'
                  "
                  class="text-neutral-500"
                  aria-hidden="true"
                />
                <span>{{ request.paymentMethod }} ({{ request.channelProvider }})</span>
              </div>
            </div>

            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Company Account Paid</div>
              <div class="font-mono font-semibold text-neutral-800 mt-0.5">
                {{ request.companyAccountPaid }}
              </div>
            </div>

            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Reference Code</div>
              <div class="font-mono font-bold text-neutral-900 mt-0.5">
                {{ request.referenceCode }}
              </div>
            </div>

            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Sender Account Used</div>
              <div class="font-mono text-neutral-700 mt-0.5">
                {{ request.senderAccount }}
              </div>
            </div>
          </div>

          <div class="p-4 bg-neutral-50 border border-neutral-200 space-y-1.5 text-xs">
            <div class="flex items-center justify-between">
              <span class="font-bold text-neutral-900">Statement Reconciliation Note</span>
              <span class="font-mono text-[11px] text-neutral-500">
                File: {{ request.receiptFileName }}
              </span>
            </div>
            <p class="text-neutral-600 leading-relaxed">{{ request.proofNote }}</p>
            <p
              v-if="request.rejectionReason"
              class="pt-2 border-t border-neutral-200 text-neutral-800 font-semibold"
            >
              Rejection Reason: {{ request.rejectionReason }}
            </p>
          </div>

          <div
            v-if="request.status === 'Pending'"
            class="pt-4 border-t border-neutral-100 flex flex-wrap items-center justify-end gap-3"
          >
            <button
              type="button"
              class="px-4 py-2 border border-neutral-300 bg-white text-neutral-800 text-xs font-semibold hover:bg-neutral-50 cursor-pointer"
              @click="showRejectConfirm = true"
            >
              Reject Proof
            </button>
            <button
              type="button"
              class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
              @click="approveAndCredit"
            >
              Approve &amp; Credit Wallet
            </button>
          </div>
        </div>

        <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Receipt</h2>
            <button
              type="button"
              class="text-xs font-semibold text-neutral-900 hover:underline inline-flex items-center gap-1 cursor-pointer"
              @click="showProofModal = true"
            >
              <Icon icon="lucide:maximize-2" class="text-xs" aria-hidden="true" />
              <span>Enlarge</span>
            </button>
          </div>

          <div class="border border-neutral-200 bg-neutral-50 p-2">
            <img
              :src="request.receiptPreviewUrl"
              :alt="`Payment proof receipt ${request.referenceCode} uploaded by ${request.driverName}`"
              class="w-full h-56 object-contain bg-white"
            />
          </div>
        </div>
      </div>

      <ModalDialog
        v-model:open="showProofModal"
        :title="`Proof of Transfer · ${request.referenceCode}`"
        :subtitle="`${request.channelProvider} · Uploaded by ${request.driverName}`"
        size="lg"
      >
        <div class="bg-neutral-50 border border-neutral-200 p-4 flex justify-center">
          <img
            :src="request.receiptPreviewUrl"
            :alt="`Full receipt preview ${request.referenceCode}`"
            class="max-h-[460px] w-auto object-contain bg-white"
          />
        </div>
        <template #footer>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="showProofModal = false"
          >
            Close
          </button>
        </template>
      </ModalDialog>

      <ConfirmDialog
        v-model:open="showRejectConfirm"
        v-model:reason="rejectReason"
        :title="`Reject Top-Up ${request.id}`"
        description="Provide the exact reason why this deposit slip cannot be reconciled so the driver can re-upload valid proof."
        confirm-label="Confirm Rejection"
        tone="rose"
        :require-reason="true"
        reason-label="Rejection Reason (Required)"
        reason-placeholder="e.g., Transaction reference not found on GCash merchant statement."
        @confirm="submitRejection"
      />
    </template>
  </div>
</template>
