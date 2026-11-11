<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const payoutBatches = ref([
  {
    batchId: 'BATCH-2026-W45',
    period: 'Nov 02 - Nov 08, 2026',
    totalAmount: '₱482,190.00',
    driversPaid: 1240,
    status: 'Settled via Bank ACH',
    date: '2026-11-09',
  },
  {
    batchId: 'BATCH-2026-W44',
    period: 'Oct 26 - Nov 01, 2026',
    totalAmount: '₱456,800.00',
    driversPaid: 1195,
    status: 'Settled via Bank ACH',
    date: '2026-11-02',
  },
  {
    batchId: 'BATCH-2026-W43',
    period: 'Oct 19 - Oct 25, 2026',
    totalAmount: '₱442,100.00',
    driversPaid: 1180,
    status: 'Settled via Bank ACH',
    date: '2026-10-26',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Driver Payout & Banking Settlement Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Weekly driver earnings settlement batches, gross earnings versus commission withholdings,
        and ACH confirmations.
      </p>
    </div>

    <ReportFilterBar report-title="Driver Payout Settlement Audit" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Weekly Driver Payout Batches</h2>
        <span class="text-xs text-neutral-400">Company direct bank settlement records</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Batch ID</th>
            <th class="py-3 px-4">Pay Period</th>
            <th class="py-3 px-4">Total Settled</th>
            <th class="py-3 px-4">Drivers Credited</th>
            <th class="py-3 px-4">Settlement Status</th>
            <th class="py-3 px-4 text-right">Settlement Date</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="b in payoutBatches"
            :key="b.batchId"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ b.batchId }}</td>
            <td class="py-3 px-4 font-medium text-neutral-800">{{ b.period }}</td>
            <td class="py-3 px-4 font-bold text-base text-neutral-900">{{ b.totalAmount }}</td>
            <td class="py-3 px-4 text-neutral-700 font-semibold">
              {{ b.driversPaid.toLocaleString() }} drivers
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800"
              >
                {{ b.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right font-mono text-neutral-500">{{ b.date }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
