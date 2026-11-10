<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const financialSummaries = ref([
  {
    period: 'October 2026',
    grossVolume: '$2,840,190',
    platformCommission: '$426,028',
    driverPayouts: '$2,414,162',
    netMargin: '15.0%',
  },
  {
    period: 'September 2026',
    grossVolume: '$2,610,400',
    platformCommission: '$391,560',
    driverPayouts: '$2,218,840',
    netMargin: '15.0%',
  },
  {
    period: 'August 2026',
    grossVolume: '$2,450,800',
    platformCommission: '$367,620',
    driverPayouts: '$2,083,180',
    netMargin: '15.0%',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Platform Revenue & Financial Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Gross merchandise volume (GMV), platform commission deductions, and net driver settlement
        balances.
      </p>
    </div>

    <!-- Universal Report Filter Bar with CSV/PDF/Excel export -->
    <ReportFilterBar report-title="Revenue & Commission Report" />

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Monthly Financial Settlement Summary</h2>
        <span class="text-xs text-neutral-400">Prepaid wallet deduction model</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Accounting Period</th>
            <th class="py-3 px-4">Gross Ride Bookings</th>
            <th class="py-3 px-4">Platform Commission (Revenue)</th>
            <th class="py-3 px-4">Driver Take-Home Earnings</th>
            <th class="py-3 px-4 text-right">Effective Platform Cut</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="f in financialSummaries"
            :key="f.period"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ f.period }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ f.grossVolume }}</td>
            <td class="py-3 px-4 font-bold text-emerald-600">{{ f.platformCommission }}</td>
            <td class="py-3 px-4 text-neutral-700">{{ f.driverPayouts }}</td>
            <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
              {{ f.netMargin }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
