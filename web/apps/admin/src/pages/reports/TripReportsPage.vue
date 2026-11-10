<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/pages/reports/ReportFilterBar.vue'

const tripReportData = ref([
  {
    date: '2026-11-09',
    totalRides: 4120,
    completed: 3980,
    cancelled: 140,
    totalDistance: '48,200 km',
    grossVolume: '$89,450',
  },
  {
    date: '2026-11-08',
    totalRides: 4450,
    completed: 4310,
    cancelled: 140,
    totalDistance: '52,100 km',
    grossVolume: '$96,800',
  },
  {
    date: '2026-11-07',
    totalRides: 5120,
    completed: 4920,
    cancelled: 200,
    totalDistance: '61,300 km',
    grossVolume: '$114,200',
  },
  {
    date: '2026-11-06',
    totalRides: 5380,
    completed: 5190,
    cancelled: 190,
    totalDistance: '64,900 km',
    grossVolume: '$121,500',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Trip Volume & Mobility Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Aggregated trip completions, total fleet kilometers, passenger ride durations, and
        operational velocity.
      </p>
    </div>

    <!-- Universal Report Filter Bar with CSV/PDF/Excel export -->
    <ReportFilterBar report-title="Trip Volume Report" />

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Trip Aggregations by Day</h2>
        <span class="text-xs text-neutral-400">All data synced from primary dispatch ledger</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Date</th>
            <th class="py-3 px-4">Total Requested</th>
            <th class="py-3 px-4">Completed Rides</th>
            <th class="py-3 px-4">Cancelled Rides</th>
            <th class="py-3 px-4">Fleet Distance</th>
            <th class="py-3 px-4 text-right">Gross Bookings</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="r in tripReportData"
            :key="r.date"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ r.date }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">
              {{ r.totalRides.toLocaleString() }}
            </td>
            <td class="py-3 px-4 text-emerald-600 font-semibold">
              {{ r.completed.toLocaleString() }}
            </td>
            <td class="py-3 px-4 text-rose-600 font-medium">{{ r.cancelled }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ r.totalDistance }}</td>
            <td class="py-3 px-4 text-right font-bold text-neutral-900">{{ r.grossVolume }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
