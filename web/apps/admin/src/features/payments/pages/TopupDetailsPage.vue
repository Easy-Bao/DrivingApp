<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useTopups } from '@/features/payments/composables/useTopups'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import { formatPhp } from '@/shared/utils/format'

const route = useRoute()
const router = useRouter()
const { getRequestById, verifyAndCredit, rejectRequest } = useTopups()

const requestId = computed(() => (route.params.id as string) || '')
const request = computed(() => getRequestById(requestId.value))

const actionToast = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'info'>('info')
const showRejectDialog = ref(false)
const rejectReason = ref('')
const showProofModal = ref(false)

function handleApprove() {
  if (!request.value) return
  verifyAndCredit(request.value)
  toastTone.value = 'success'
  actionToast.value = `Successfully verified ${request.value.id}. Credited ${formatPhp(request.value.amount)} to ${request.value.driverName}'s prepaid wallet.`
}

function handleRejectConfirm() {
  if (!request.value) return
  rejectRequest(request.value, rejectReason.value)
  toastTone.value = 'warning'
  actionToast.value = `Request ${request.value.id} for ${request.value.driverName} rejected: ${rejectReason.value}`
}

function handleEscapeKey(event: KeyboardEvent) {
  if (event.key === 'Escape' && showProofModal.value) {
    showProofModal.value = false
  }
}

watch(showProofModal, (isOpen) => {
  if (typeof window === 'undefined') return
  if (isOpen) {
    window.addEventListener('keydown', handleEscapeKey)
  } else {
    window.removeEventListener('keydown', handleEscapeKey)
  }
})

onBeforeUnmount(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('keydown', handleEscapeKey)
  }
})

function goBack() {
  if (window.history.state && window.history.state.back) {
    router.back()
  } else {
    void router.push('/payments/topups')
  }
}
</script>

<template>
  <div class="space-y-6 w-full">
    <div>
      <button
        type="button"
        class="inline-flex items-center space-x-2 text-xs font-semibold text-neutral-700 hover:text-neutral-900 bg-white border border-neutral-200 hover:bg-neutral-50 px-3 py-1.5 transition-colors group cursor-pointer"
        @click="goBack"
      >
        <Icon
          icon="lucide:arrow-left"
          class="text-sm text-neutral-500 group-hover:text-neutral-900 transition-transform group-hover:-translate-x-0.5"
          aria-hidden="true"
        />
        <span>Back</span>
      </button>
    </div>

    <ToastBanner :message="actionToast" :tone="toastTone" @dismiss="actionToast = null" />

    <div v-if="request" class="space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Top-Up Request {{ request.id }}
            </h1>
            <StatusBadge
              :label="request.status"
              :tone="
                request.status === 'Verified'
                  ? 'success'
                  : request.status === 'Rejected'
                    ? 'danger'
                    : 'warning'
              "
            />
          </div>
          <p class="text-sm text-neutral-500 mt-1">
            Submitted {{ request.submittedAt }} via Driver App ({{ request.channelProvider }}).
          </p>
        </div>

        <div class="sm:text-right">
          <div class="text-xs text-neutral-400 uppercase font-semibold">Requested Amount</div>
          <div class="text-3xl font-extrabold text-neutral-900 mt-0.5 font-mono tabular-nums">
            {{ formatPhp(request.amount) }}
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div
          class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-neutral-100"
        >
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm shrink-0"
            >
              {{ request.driverName.charAt(0) }}
            </div>
            <div>
              <h2 class="font-bold text-sm text-neutral-900">{{ request.driverName }}</h2>
              <p class="text-xs font-mono text-neutral-500">{{ request.driverPhone }}</p>
            </div>
          </div>
          <span
            class="px-2.5 py-1 text-xs font-semibold w-fit"
            :class="
              request.currentBalance < 50
                ? 'bg-rose-50 text-rose-700 border border-rose-200'
                : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
            "
          >
            {{
              request.currentBalance < 50
                ? 'Below Dispatch Threshold (< ₱50.00 min)'
                : 'Dispatch Eligible'
            }}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Assigned Taxicle</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              Plate: {{ request.vehiclePlate }}
            </div>
            <div class="text-[11px] text-neutral-500">{{ request.sidecarBody }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Current Wallet Balance</div>
            <div
              class="font-mono font-bold mt-0.5 tabular-nums"
              :class="request.currentBalance < 50 ? 'text-rose-600' : 'text-neutral-900'"
            >
              {{ formatPhp(request.currentBalance) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Balance After Approval</div>
            <div class="font-mono font-bold text-emerald-600 mt-0.5 tabular-nums">
              {{
                formatPhp(
                  request.currentBalance + (request.status === 'Pending' ? request.amount : 0),
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
              <div class="text-neutral-400 text-[11px] font-medium">Proof Reference / TXN Code</div>
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
              class="pt-2 border-t border-rose-200 text-rose-700 font-semibold"
            >
              Rejection Reason: {{ request.rejectionReason }}
            </p>
          </div>
        </div>

        <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Uploaded Proof Receipt</h2>
            <button
              type="button"
              class="text-xs font-semibold text-neutral-900 hover:underline inline-flex items-center gap-1 cursor-pointer"
              @click="showProofModal = true"
            >
              <Icon icon="lucide:maximize-2" class="text-xs" aria-hidden="true" />
              <span>Enlarge</span>
            </button>
          </div>

          <button
            type="button"
            class="group relative border border-neutral-200 bg-neutral-50 p-2 hover:border-neutral-400 transition-colors cursor-pointer text-left"
            @click="showProofModal = true"
          >
            <img
              :src="request.receiptPreviewUrl"
              :alt="`Payment proof receipt ${request.referenceCode} uploaded by ${request.driverName}`"
              class="w-full h-56 object-contain bg-white"
            />
            <span
              class="mt-2 block text-[11px] font-mono text-center text-neutral-500 group-hover:text-neutral-900"
            >
              Click to inspect full-resolution receipt
            </span>
          </button>
        </div>
      </div>

      <div
        class="bg-white border border-neutral-200 p-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4"
      >
        <div class="text-xs text-neutral-500">
          <span v-if="request.status === 'Pending'">
            Verify transfer reference and receipt picture before confirming credit release.
          </span>
          <span v-else-if="request.status === 'Verified'" class="text-emerald-600 font-semibold">
            This request has already been verified and credited.
          </span>
          <span v-else class="text-rose-600 font-semibold">
            This request has been rejected and closed.
          </span>
        </div>

        <div v-if="request.status === 'Pending'" class="flex items-center space-x-3 shrink-0">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors cursor-pointer"
            @click="showRejectDialog = true"
          >
            Reject Request
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="handleApprove"
          >
            Approve &amp; Credit Wallet ({{ formatPhp(request.amount) }})
          </button>
        </div>
      </div>
    </div>

    <div v-else class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500">
      <p class="font-semibold text-neutral-900">Request Not Found</p>
      <p class="mt-1">No top-up request matches ID {{ requestId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
        @click="goBack"
      >
        Back to List
      </button>
    </div>

    <ConfirmDialog
      v-model:open="showRejectDialog"
      v-model:reason="rejectReason"
      title="Reject Top-Up Request"
      description="Provide a clear reason so the driver can re-upload a valid GCash or bank transfer proof."
      confirm-label="Confirm Reject"
      tone="rose"
      :require-reason="true"
      reason-label="Rejection Reason"
      reason-placeholder="e.g., Reference code not found in BDO statement or blurry amount"
      @confirm="handleRejectConfirm"
    />

    <Teleport to="body">
      <div
        v-if="showProofModal && request"
        role="dialog"
        aria-modal="true"
        aria-labelledby="receipt-viewer-title"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
        @click.self="showProofModal = false"
      >
        <div class="bg-white border border-neutral-300 max-w-lg w-full p-5 space-y-4 shadow-2xl">
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <div>
              <h3 id="receipt-viewer-title" class="text-sm font-bold text-neutral-900">
                Proof of Transfer · {{ request.referenceCode }}
              </h3>
              <p class="text-[11px] font-mono text-neutral-500">{{ request.receiptFileName }}</p>
            </div>
            <button
              type="button"
              aria-label="Close receipt viewer"
              class="p-1 text-neutral-400 hover:text-neutral-700 cursor-pointer"
              @click="showProofModal = false"
            >
              <Icon icon="lucide:x" class="text-base" aria-hidden="true" />
            </button>
          </div>

          <div class="bg-neutral-50 border border-neutral-200 p-3 flex justify-center">
            <img
              :src="request.receiptPreviewUrl"
              :alt="`Full resolution receipt ${request.referenceCode}`"
              class="max-h-[70vh] w-auto object-contain"
            />
          </div>

          <div class="flex justify-end">
            <button
              type="button"
              class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
              @click="showProofModal = false"
            >
              Close Viewer
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
