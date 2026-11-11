<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useTopups } from '@/features/payments/composables/useTopups'

const route = useRoute()
const router = useRouter()
const { getRequestById, verifyAndCredit, rejectRequest } = useTopups()

const requestId = computed(() => (route.params.id as string) || '')
const request = computed(() => getRequestById(requestId.value))

const actionToast = ref<string | null>(null)

function handleApprove() {
  if (!request.value) return
  verifyAndCredit(request.value)
  actionToast.value = `Successfully verified ${request.value.id}! Credited ₱${request.value.amount.toFixed(2)} to ${request.value.driverName}'s wallet. Driver dispatch eligibility restored.`
}

function handleReject() {
  if (!request.value) return
  rejectRequest(request.value)
  actionToast.value = `Request ${request.value.id} for ${request.value.driverName} has been rejected.`
}

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
    <!-- Back Button: Inside the page content area (not in header or breadcrumbs) -->
    <div>
      <button
        type="button"
        class="inline-flex items-center space-x-2 text-xs font-semibold text-neutral-700 hover:text-neutral-900 bg-white border border-neutral-200 hover:bg-neutral-50 px-3 py-1.5 transition-colors group cursor-pointer"
        @click="goBack"
      >
        <Icon
          icon="lucide:arrow-left"
          class="text-sm text-neutral-500 group-hover:text-neutral-900 transition-transform group-hover:-translate-x-0.5"
        />
        <span>Back to Driver Top-Ups</span>
      </button>
    </div>

    <!-- Alert / Toast -->
    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <!-- If request found -->
    <div v-if="request" class="space-y-6">
      <!-- Title & Status Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Top-Up Request {{ request.id }}
            </h1>
            <span
              class="px-2.5 py-0.5 rounded-full text-xs font-bold"
              :class="
                request.status === 'Verified'
                  ? 'bg-emerald-100 text-emerald-800'
                  : request.status === 'Rejected'
                    ? 'bg-rose-100 text-rose-800'
                    : 'bg-amber-100 text-amber-800'
              "
            >
              {{ request.status }}
            </span>
          </div>
          <p class="text-sm text-neutral-500 mt-1">
            Submitted {{ request.submittedAt }} via Driver Mobile App.
          </p>
        </div>

        <div class="text-right">
          <div class="text-xs text-neutral-400 uppercase font-semibold">Requested Amount</div>
          <div class="text-3xl font-extrabold text-neutral-900 mt-0.5 font-mono">
            ₱{{ request.amount.toFixed(2) }}
          </div>
        </div>
      </div>

      <!-- Driver Profile Card -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm"
            >
              {{ request.driverName.charAt(0) }}
            </div>
            <div>
              <h2 class="font-bold text-sm text-neutral-900">{{ request.driverName }}</h2>
              <p class="text-xs text-neutral-500">{{ request.driverPhone }}</p>
            </div>
          </div>
          <span
            class="px-2.5 py-1 text-xs font-semibold"
            :class="
              request.currentBalance < 5
                ? 'bg-rose-50 text-rose-700 border border-rose-200'
                : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
            "
          >
            {{ request.currentBalance < 5 ? 'Dispatch Locked (< ₱5.00 min)' : 'Dispatch Eligible' }}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Assigned Vehicle</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              Plate: {{ request.vehiclePlate }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Prepaid Wallet Balance</div>
            <div
              class="font-mono font-bold mt-0.5"
              :class="request.currentBalance < 5 ? 'text-rose-600' : 'text-neutral-900'"
            >
              ₱{{ request.currentBalance.toFixed(2) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Balance After Approval</div>
            <div class="font-mono font-bold text-emerald-600 mt-0.5">
              ₱{{
                (
                  request.currentBalance + (request.status === 'Pending' ? request.amount : 0)
                ).toFixed(2)
              }}
            </div>
          </div>
        </div>
      </div>

      <!-- Payment & Transaction Details Card -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center space-x-2 pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Company Payment Method & Reference</h2>
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
              />
              <span>{{ request.paymentMethod }}</span>
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
            <div class="text-neutral-400 text-[11px] font-medium">Driver Attached File</div>
            <div class="font-mono text-neutral-700 mt-0.5">
              {{ request.receiptFileName }}
            </div>
          </div>
        </div>

        <!-- Attached Proof Preview Box -->
        <div class="mt-4 p-4 bg-neutral-50 border border-neutral-200 space-y-2">
          <div class="flex items-center justify-between text-xs">
            <span class="font-bold text-neutral-900 flex items-center space-x-1.5">
              <span>Payment Proof Verified Against Company Statement</span>
            </span>
            <span class="font-mono text-[11px] text-neutral-400">Direct Settlement</span>
          </div>
          <p class="text-xs text-neutral-600 leading-relaxed">
            {{ request.proofNote }}
          </p>
        </div>
      </div>

      <!-- Action Footer -->
      <div
        class="bg-white border border-neutral-200 p-4 flex items-center justify-between"
      >
        <div class="text-xs text-neutral-500">
          <span v-if="request.status === 'Pending'">
            Verify transfer reference before confirming credit release.
          </span>
          <span v-else-if="request.status === 'Verified'" class="text-emerald-600 font-semibold">
            ✓ This request has already been verified and credited.
          </span>
          <span v-else class="text-rose-600 font-semibold"> ✕ This request was rejected. </span>
        </div>

        <div v-if="request.status === 'Pending'" class="flex items-center space-x-3">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors"
            @click="handleReject"
          >
            Reject Request
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors"
            @click="handleApprove"
          >
            Approve & Credit Wallet (₱{{ request.amount.toFixed(2) }})
          </button>
        </div>
      </div>
    </div>

    <!-- If request not found -->
    <div
      v-else
      class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500"
    >
      <p class="font-semibold text-neutral-900">Request Not Found</p>
      <p class="mt-1">No top-up request matches ID {{ requestId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold"
        @click="goBack"
      >
        Back to List
      </button>
    </div>
  </div>
</template>
