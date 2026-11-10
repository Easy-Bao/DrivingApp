<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/pages/reports/ReportFilterBar.vue'

const cohortActivity = ref([
  {
    cohort: 'Active Frequent Flyers (10+ rides/mo)',
    ridersCount: 14200,
    retentionRate: '94.2%',
    avgSpend: '$284.00',
  },
  {
    cohort: 'Weekend Leisure Riders (4-9 rides/mo)',
    ridersCount: 28400,
    retentionRate: '86.5%',
    avgSpend: '$122.50',
  },
  {
    cohort: 'Occasional Commuters (1-3 rides/mo)',
    ridersCount: 42100,
    retentionRate: '68.0%',
    avgSpend: '$38.20',
  },
  {
    cohort: 'New Signups (First 30 Days)',
    ridersCount: 6800,
    retentionRate: '48.9%',
    avgSpend: '$24.50',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Rider Activity & Cohort Analytics
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Customer engagement retention curves, trip frequency segments, and lifetime value
        indicators.
      </p>
    </div>

    <ReportFilterBar report-title="Rider Cohort Activity" />

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Passenger Engagement Cohorts</h2>
        <span class="text-xs text-neutral-400">Monthly active user benchmark: 91,500 riders</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Cohort Segment</th>
            <th class="py-3 px-4">Active Passenger Population</th>
            <th class="py-3 px-4">30-Day Retention</th>
            <th class="py-3 px-4 text-right">Average Monthly Spend</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="c in cohortActivity"
            :key="c.cohort"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ c.cohort }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">
              {{ c.ridersCount.toLocaleString() }}
            </td>
            <td class="py-3 px-4 text-emerald-600 font-semibold">{{ c.retentionRate }}</td>
            <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
              {{ c.avgSpend }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
