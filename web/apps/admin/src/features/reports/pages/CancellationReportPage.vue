<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const cancellationCauses = ref([
  {
    reason: 'Driver ETA exceeded rider expectation (>10 mins)',
    count: 482,
    share: '38.5%',
    initiatedBy: 'Rider',
    feeApplicable: 'No',
  },
  {
    reason: 'Rider no-show at pickup pin after 5 min wait',
    count: 320,
    share: '25.6%',
    initiatedBy: 'Driver',
    feeApplicable: 'Yes (₱5.00)',
  },
  {
    reason: 'Accidental dispatch / rider changed plans',
    count: 240,
    share: '19.2%',
    initiatedBy: 'Rider',
    feeApplicable: 'Within Grace Period (₱0)',
  },
  {
    reason: 'Driver vehicle mechanical issue / flat tire',
    count: 120,
    share: '9.6%',
    initiatedBy: 'Driver',
    feeApplicable: 'No (Auto-rematched)',
  },
  {
    reason: 'No dispatch driver available within radius',
    count: 88,
    share: '7.1%',
    initiatedBy: 'System Timeout',
    feeApplicable: 'No',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Trip Cancellation Root-Cause Analysis
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Categorical audit of cancellations across passenger, driver, and system dispatch timeouts.
      </p>
    </div>

    <ReportFilterBar report-title="Cancellation Analysis Report" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Cancellation Reasons Breakdown</h2>
        <span class="text-xs text-neutral-400">Total cancellations this period: 1,250</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Primary Root Cause</th>
            <th class="py-3 px-4">Incidents</th>
            <th class="py-3 px-4">Share of Total</th>
            <th class="py-3 px-4">Party Responsible</th>
            <th class="py-3 px-4 text-right">Fee Rule</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="c in cancellationCauses"
            :key="c.reason"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ c.reason }}</td>
            <td class="py-3 px-4 font-mono font-bold text-neutral-800">{{ c.count }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ c.share }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  c.initiatedBy === 'Rider'
                    ? 'bg-blue-100 text-blue-800'
                    : c.initiatedBy === 'Driver'
                      ? 'bg-amber-100 text-amber-800'
                      : 'bg-neutral-100 text-neutral-800'
                "
              >
                {{ c.initiatedBy }}
              </span>
            </td>
            <td class="py-3 px-4 text-right font-medium text-neutral-700">{{ c.feeApplicable }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
