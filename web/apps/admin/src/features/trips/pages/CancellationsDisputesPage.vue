<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const cancellations = ref([
  {
    id: 'CAN-301',
    tripId: 'TRP-1089',
    cancelledBy: 'Rider (Sarah Jenkins)',
    reason: 'Driver too far away / ETA increased',
    cancellationFee: '$5.00',
    feeChargedTo: 'Rider',
    disputeStatus: 'Under Admin Review',
    timestamp: '2 hours ago',
  },
  {
    id: 'CAN-302',
    tripId: 'TRP-1077',
    cancelledBy: 'Driver (Javier Santos)',
    reason: 'Rider did not show up at pickup location after 5 mins',
    cancellationFee: '$5.00',
    feeChargedTo: 'Rider (Compensated Driver)',
    disputeStatus: 'Resolved (Fee Upheld)',
    timestamp: '5 hours ago',
  },
  {
    id: 'CAN-303',
    tripId: 'TRP-1065',
    cancelledBy: 'System Timeout',
    reason: 'No driver accepted dispatch request within 90s',
    cancellationFee: '$0.00',
    feeChargedTo: 'None (System Waived)',
    disputeStatus: 'Closed',
    timestamp: 'Yesterday',
  },
])

const actionToast = ref<string | null>(null)

function waiveFee(can: (typeof cancellations.value)[0]) {
  can.disputeStatus = 'Fee Waived & Refunded'
  actionToast.value = `Cancellation fee for ${can.tripId} waived. Rider credited.`
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
          Cancellations & Dispute Audits
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review ride cancellations, assess cancellation fee policies, and resolve contested
          charges.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span class="px-3 py-1.5 rounded-lg bg-neutral-100 text-neutral-800 text-xs font-semibold">
          Cancellation Rate: 3.6%
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
        <h2 class="font-bold text-sm text-neutral-900">Recent Cancelled Trips</h2>
        <span class="text-xs text-neutral-400"
          >Automatic grace period: 2 minutes after dispatch</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Dispute ID</th>
            <th class="py-3 px-4">Trip ID</th>
            <th class="py-3 px-4">Initiated By</th>
            <th class="py-3 px-4">Cancellation Reason</th>
            <th class="py-3 px-4">Fee Policy</th>
            <th class="py-3 px-4">Dispute Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="c in cancellations"
            :key="c.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ c.id }}</td>
            <td class="py-3 px-4 font-mono font-semibold text-neutral-700">{{ c.tripId }}</td>
            <td class="py-3 px-4 font-medium text-neutral-900">{{ c.cancelledBy }}</td>
            <td class="py-3 px-4 text-neutral-600 max-w-xs">{{ c.reason }}</td>
            <td class="py-3 px-4">
              <span class="font-bold text-neutral-900">{{ c.cancellationFee }}</span>
              <div class="text-[10px] text-neutral-400">{{ c.feeChargedTo }}</div>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  c.disputeStatus.includes('Waived')
                    ? 'bg-blue-100 text-blue-800'
                    : c.disputeStatus.includes('Review')
                      ? 'bg-amber-100 text-amber-800'
                      : 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ c.disputeStatus }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                v-if="c.disputeStatus.includes('Review')"
                type="button"
                class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors"
                @click="waiveFee(c)"
              >
                Waive Fee
              </button>
              <span v-else class="text-neutral-400 text-xs">Resolved</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
