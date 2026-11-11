<script setup lang="ts">
import { ref } from 'vue'

const earnings = ref([
  {
    driver: 'David Kim',
    period: 'Oct 28 – Nov 03',
    completedTrips: 64,
    gross: '₱1,840.00',
    commission: '-₱331.20',
    net: '₱1,508.80',
    status: 'Disbursed',
  },
  {
    driver: 'Marcus Miller',
    period: 'Oct 28 – Nov 03',
    completedTrips: 52,
    gross: '₱1,420.00',
    commission: '-₱255.60',
    net: '₱1,164.40',
    status: 'Disbursed',
  },
  {
    driver: 'Elena Rostova',
    period: 'Oct 28 – Nov 03',
    completedTrips: 48,
    gross: '₱1,290.00',
    commission: '-₱232.20',
    net: '₱1,057.80',
    status: 'Pending Payout',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Driver Earnings & Settlement Cycles
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Periodic earnings summaries, platform commission retentions, and net take-home calculation.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <table class="w-full text-left text-xs">
        <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
          <tr>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Pay Period</th>
            <th class="py-3 px-4">Trips</th>
            <th class="py-3 px-4">Gross Fares</th>
            <th class="py-3 px-4">Platform Fee (18%)</th>
            <th class="py-3 px-4">Net Take-Home</th>
            <th class="py-3 px-4">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100 text-neutral-700">
          <tr v-for="e in earnings" :key="e.driver" class="hover:bg-neutral-50/50">
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ e.driver }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ e.period }}</td>
            <td class="py-3 px-4">{{ e.completedTrips }}</td>
            <td class="py-3 px-4 font-medium">{{ e.gross }}</td>
            <td class="py-3 px-4 text-rose-600 font-medium">{{ e.commission }}</td>
            <td class="py-3 px-4 font-bold text-emerald-700">{{ e.net }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  e.status === 'Disbursed'
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-amber-100 text-amber-800'
                "
              >
                {{ e.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
