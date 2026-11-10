<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

interface PayoutRequest {
  id: string
  driver: string
  phone: string
  amount: number
  bankName: string
  accountNumber: string
  requestedAt: string
  tripsCount: number
  status: 'Pending Batch' | 'Approved' | 'Paid'
}

const payoutRequests = ref<PayoutRequest[]>([
  {
    id: 'PAY-401',
    driver: 'Marcus Miller',
    phone: '+1 (555) 234-5678',
    amount: 420.5,
    bankName: 'First National Bank',
    accountNumber: '**** **** 8821',
    requestedAt: '3 hours ago',
    tripsCount: 28,
    status: 'Pending Batch',
  },
  {
    id: 'PAY-402',
    driver: 'Elena Rostova',
    phone: '+1 (555) 876-5432',
    amount: 615.0,
    bankName: 'Silicon Valley Metro Bank',
    accountNumber: '**** **** 1142',
    requestedAt: '5 hours ago',
    tripsCount: 42,
    status: 'Pending Batch',
  },
  {
    id: 'PAY-403',
    driver: 'David Kim',
    phone: '+1 (555) 345-6789',
    amount: 310.0,
    bankName: 'Chase Commercial Banking',
    accountNumber: '**** **** 9081',
    requestedAt: 'Yesterday',
    tripsCount: 19,
    status: 'Pending Batch',
  },
])

const actionToast = ref<string | null>(null)

function processPayout(req: PayoutRequest) {
  req.status = 'Approved'
  actionToast.value = `Payout ${req.id} of $${req.amount.toFixed(2)} for ${req.driver} approved for next bank transfer batch.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">Driver Payout Requests</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Approve weekly driver earning withdrawals to verified bank accounts through company batch
          ACH/wire.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 rounded-lg bg-blue-50 border border-blue-200 text-xs font-semibold text-blue-800"
        >
          5 Pending Payouts ($1,845.50 Total)
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Payout Withdrawal Queue</h2>
        <span class="text-xs text-neutral-400">Processed via direct company bank settlement</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Payout ID</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Withdrawal Amount</th>
            <th class="py-3 px-4">Destination Bank Account</th>
            <th class="py-3 px-4">Trips Completed</th>
            <th class="py-3 px-4">Requested At</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="req in payoutRequests"
            :key="req.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ req.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ req.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ req.phone }}</div>
            </td>
            <td class="py-3 px-4 font-bold text-base text-neutral-900">
              ${{ req.amount.toFixed(2) }}
            </td>
            <td class="py-3 px-4">
              <div class="font-medium text-neutral-800">{{ req.bankName }}</div>
              <div class="text-[11px] font-mono text-neutral-400">{{ req.accountNumber }}</div>
            </td>
            <td class="py-3 px-4 font-semibold text-neutral-700">{{ req.tripsCount }} rides</td>
            <td class="py-3 px-4 text-neutral-500">{{ req.requestedAt }}</td>
            <td class="py-3 px-4 text-right">
              <button
                v-if="req.status === 'Pending Batch'"
                type="button"
                class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors"
                @click="processPayout(req)"
              >
                Approve Payout
              </button>
              <span v-else class="text-emerald-600 font-semibold text-xs">Batch Scheduled</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
