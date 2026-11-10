<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { usePayoutRequests } from '@/features/payments/composables/usePayoutRequests'

const router = useRouter()
const { payoutRequests } = usePayoutRequests()

function navigateToDetails(id: string) {
  void router.push(`/payments/payout-requests/${id}`)
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
          {{ payoutRequests.filter((p) => p.status === 'Pending Batch').length }} Pending Payouts
        </span>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Payout Withdrawal Queue</h2>
        <span class="text-xs text-neutral-400">Processed via direct company bank settlement</span>
      </div>

      <div class="overflow-x-auto">
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
              <th class="py-3 px-4">Status</th>
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
              <td class="py-3 px-4 font-bold text-base text-neutral-900 font-mono">
                ${{ req.amount.toFixed(2) }}
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-800">{{ req.bankName }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ req.accountNumber }}</div>
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-700">{{ req.tripsCount }} rides</td>
              <td class="py-3 px-4 text-neutral-500">{{ req.requestedAt }}</td>
              <td class="py-3 px-4">
                <span
                  class="px-2.5 py-0.5 rounded-full text-[10px] font-bold"
                  :class="{
                    'bg-amber-100 text-amber-800': req.status === 'Pending Batch',
                    'bg-emerald-100 text-emerald-800':
                      req.status === 'Approved' || req.status === 'Paid',
                    'bg-rose-100 text-rose-800': req.status === 'Rejected',
                  }"
                >
                  {{ req.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1.5 rounded-lg bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs transition-colors shadow-2xs inline-flex items-center space-x-1 cursor-pointer"
                  @click="navigateToDetails(req.id)"
                >
                  <span>View Details</span>
                  <Icon icon="lucide:arrow-right" class="text-xs" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
