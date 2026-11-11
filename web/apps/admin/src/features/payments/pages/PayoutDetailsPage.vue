<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { usePayoutRequests } from '@/features/payments/composables/usePayoutRequests'

const route = useRoute()
const router = useRouter()
const { getPayoutById, approvePayout, rejectPayout } = usePayoutRequests()

const payoutId = computed(() => (route.params.id as string) || '')
const payout = computed(() => getPayoutById(payoutId.value))

const actionToast = ref<string | null>(null)

function handleApprove() {
  if (!payout.value) return
  approvePayout(payout.value)
  actionToast.value = `Payout ${payout.value.id} for ${payout.value.driver} (₱${payout.value.amount.toFixed(2)}) approved for ACH wire batch.`
}

function handleReject() {
  if (!payout.value) return
  rejectPayout(payout.value)
  actionToast.value = `Payout ${payout.value.id} has been marked as Rejected.`
}

function goBack() {
  if (window.history.state && window.history.state.back) {
    router.back()
  } else {
    void router.push('/payments/payout-requests')
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
        <span>Back to Payout Requests</span>
      </button>
    </div>

    <!-- Alert / Toast Banner -->
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

    <!-- Payout Request Details Card if found -->
    <div v-if="payout" class="space-y-6">
      <!-- Title & Status Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Payout Withdrawal {{ payout.id }}
            </h1>
            <span
              class="px-2.5 py-0.5 rounded-full text-xs font-bold"
              :class="{
                'bg-emerald-100 text-emerald-800':
                  payout.status === 'Approved' || payout.status === 'Paid',
                'bg-rose-100 text-rose-800': payout.status === 'Rejected',
                'bg-amber-100 text-amber-800': payout.status === 'Pending Batch',
              }"
            >
              {{ payout.status }}
            </span>
          </div>
          <p class="text-sm text-neutral-500 mt-1">
            Requested {{ payout.requestedAt }} by {{ payout.driver }}.
          </p>
        </div>

        <div class="text-right">
          <div class="text-xs text-neutral-400 uppercase font-semibold">Net Payout Amount</div>
          <div class="text-3xl font-extrabold text-neutral-900 mt-0.5 font-mono">
            ₱{{ payout.netPayoutAmount.toFixed(2) }}
          </div>
        </div>
      </div>

      <!-- Driver Information -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm"
            >
              {{ payout.driver.charAt(0) }}
            </div>
            <div>
              <h2 class="font-bold text-sm text-neutral-900">{{ payout.driver }}</h2>
              <p class="text-xs text-neutral-500">{{ payout.phone }}</p>
            </div>
          </div>
          <span
            class="px-2.5 py-1 text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200"
          >
            {{ payout.tripsCount }} Completed Trips this Cycle
          </span>
        </div>

        <!-- Financial Breakdown -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Gross Fare Earnings</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              ₱{{ payout.weeklyGrossEarnings.toFixed(2) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Platform Commission (20%)</div>
            <div class="font-mono font-semibold text-rose-600 mt-0.5">
              -₱{{ payout.platformCommissionDeducted.toFixed(2) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Disbursable Amount</div>
            <div class="font-mono font-extrabold text-emerald-600 mt-0.5">
              ₱{{ payout.netPayoutAmount.toFixed(2) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Destination Bank Account Details -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center space-x-2 pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">
            Destination Bank Account for Settlement
          </h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Bank Institution</div>
            <div class="font-semibold text-neutral-900 mt-0.5">{{ payout.bankName }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Account Number</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ payout.accountNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">ACH Routing Number</div>
            <div class="font-mono text-neutral-700 mt-0.5">{{ payout.routingNumber }}</div>
          </div>
        </div>

        <div
          class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between text-xs"
        >
          <div class="flex items-center space-x-2">
            <span class="font-medium text-neutral-700">Bank Routing & Ownership Verified</span>
          </div>
          <span class="text-[11px] text-neutral-400 font-mono">Direct ACH Settlement</span>
        </div>
      </div>

      <!-- Action Footer -->
      <div
        class="bg-white border border-neutral-200 p-4 flex items-center justify-between"
      >
        <div class="text-xs text-neutral-500">
          <span v-if="payout.status === 'Pending Batch'">
            Review earnings and destination bank details before authorizing batch disbursement.
          </span>
          <span v-else-if="payout.status === 'Approved'" class="text-emerald-600 font-semibold">
            ✓ Scheduled for next banking ACH batch transfer.
          </span>
          <span v-else class="text-rose-600 font-semibold">
            ✕ Payout withdrawal request was rejected.
          </span>
        </div>

        <div v-if="payout.status === 'Pending Batch'" class="flex items-center space-x-3">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors cursor-pointer"
            @click="handleReject"
          >
            Reject Payout
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="handleApprove"
          >
            Approve Payout (₱{{ payout.netPayoutAmount.toFixed(2) }})
          </button>
        </div>
      </div>
    </div>

    <!-- Payout Not Found Fallback -->
    <div
      v-else
      class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500"
    >
      <p class="font-semibold text-neutral-900">Payout Request Not Found</p>
      <p class="mt-1">No payout request matches ID {{ payoutId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
        @click="goBack"
      >
        Back to Payout Requests
      </button>
    </div>
  </div>
</template>
