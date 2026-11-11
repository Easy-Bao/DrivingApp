<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const performanceList = ref([
  {
    driver: 'Marcus Miller',
    trips: 1420,
    rating: 4.92,
    acceptanceRate: '98.2%',
    cancellationRate: '0.8%',
    onTimeRate: '99.1%',
  },
  {
    driver: 'David Kim',
    trips: 2150,
    rating: 4.95,
    acceptanceRate: '99.0%',
    cancellationRate: '0.5%',
    onTimeRate: '99.5%',
  },
  {
    driver: 'Elena Rostova',
    trips: 890,
    rating: 4.88,
    acceptanceRate: '95.4%',
    cancellationRate: '1.4%',
    onTimeRate: '97.8%',
  },
  {
    driver: 'Javier Santos',
    trips: 430,
    rating: 4.65,
    acceptanceRate: '88.1%',
    cancellationRate: '4.2%',
    onTimeRate: '92.3%',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Driver Performance & QA Metrics
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Driver service reliability indices, customer rating distributions, and dispatch compliance
        metrics.
      </p>
    </div>

    <ReportFilterBar report-title="Driver Performance Audit" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Fleet Service Quality Benchmarks</h2>
        <span class="text-xs text-neutral-400">Acceptance target: ≥ 90%</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Trips Completed</th>
            <th class="py-3 px-4">Star Rating</th>
            <th class="py-3 px-4">Acceptance Rate</th>
            <th class="py-3 px-4">Cancellation Rate</th>
            <th class="py-3 px-4 text-right">Punctuality Score</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="p in performanceList"
            :key="p.driver"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ p.driver }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">{{ p.trips.toLocaleString() }}</td>
            <td class="py-3 px-4 font-bold text-amber-600">★ {{ p.rating }}</td>
            <td class="py-3 px-4 text-emerald-600 font-semibold">{{ p.acceptanceRate }}</td>
            <td class="py-3 px-4 text-rose-600 font-medium">{{ p.cancellationRate }}</td>
            <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
              {{ p.onTimeRate }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
