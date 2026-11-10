<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const refunds = ref([
  {
    id: 'REF-201',
    tripId: 'TRP-1082',
    rider: 'Alexander Wright',
    driver: 'Marcus Miller',
    amount: 15.5,
    reason: 'Driver took significantly inefficient route without passenger consent',
    status: 'Processed & Credited',
    requestedAt: 'Yesterday',
  },
  {
    id: 'REF-202',
    tripId: 'TRP-1064',
    rider: 'Jessica Patel',
    driver: 'Elena Rostova',
    amount: 5.0,
    reason: 'Incorrect cancellation fee charged after driver cancellation',
    status: 'Pending Approval',
    requestedAt: '3 hours ago',
  },
  {
    id: 'REF-203',
    tripId: 'TRP-1051',
    rider: 'Carlos Mendez',
    driver: 'David Kim',
    amount: 8.0,
    reason: 'Duplicate toll bridge charge in final fare calculation',
    status: 'Processed & Credited',
    requestedAt: '3 days ago',
  },
])

const actionToast = ref<string | null>(null)

function approveRefund(refItem: (typeof refunds.value)[0]) {
  refItem.status = 'Processed & Credited'
  actionToast.value = `Refund ${refItem.id} for $${refItem.amount.toFixed(2)} approved and credited to rider.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Rider Refunds & Adjustments
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review customer fare disputes, toll fee adjustments, and issue platform balance refunds.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span class="px-3 py-1.5 rounded-lg bg-neutral-100 text-neutral-800 text-xs font-semibold">
          Total Refunds This Month: $284.50
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
        <h2 class="font-bold text-sm text-neutral-900">Fare Dispute Refund History</h2>
        <span class="text-xs text-neutral-400"
          >Refunds returned directly to rider original payment</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Refund ID</th>
            <th class="py-3 px-4">Trip ID</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Refund Amount</th>
            <th class="py-3 px-4">Dispute Reason</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="r in refunds" :key="r.id" class="hover:bg-neutral-50/70 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ r.id }}</td>
            <td class="py-3 px-4 font-mono font-semibold text-neutral-700">{{ r.tripId }}</td>
            <td class="py-3 px-4 font-medium text-neutral-900">{{ r.rider }}</td>
            <td class="py-3 px-4 font-bold text-base text-neutral-900">
              ${{ r.amount.toFixed(2) }}
            </td>
            <td class="py-3 px-4 text-neutral-600 max-w-xs">{{ r.reason }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  r.status.includes('Processed')
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-amber-100 text-amber-800'
                "
              >
                {{ r.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                v-if="r.status === 'Pending Approval'"
                type="button"
                class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors"
                @click="approveRefund(r)"
              >
                Approve Refund
              </button>
              <span v-else class="text-neutral-400 text-xs">Completed</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
