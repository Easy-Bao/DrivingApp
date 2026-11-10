<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/pages/reports/ReportFilterBar.vue'

const hourlyDemand = ref([
  {
    timeWindow: '07:00 - 09:30',
    period: 'Morning Rush Hour',
    avgSurge: '1.45x',
    rideRequests: 1840,
    driverUtilization: '96.2%',
  },
  {
    timeWindow: '09:30 - 12:00',
    period: 'Mid-Morning Commerce',
    avgSurge: '1.05x',
    rideRequests: 920,
    driverUtilization: '72.0%',
  },
  {
    timeWindow: '12:00 - 14:00',
    period: 'Lunch Hour Mobility',
    avgSurge: '1.15x',
    rideRequests: 1140,
    driverUtilization: '79.5%',
  },
  {
    timeWindow: '17:00 - 19:30',
    period: 'Evening Commute Peak',
    avgSurge: '1.60x',
    rideRequests: 2190,
    driverUtilization: '98.8%',
  },
  {
    timeWindow: '21:00 - 02:00',
    period: 'Nightlife & Weekend Surge',
    avgSurge: '1.50x',
    rideRequests: 1650,
    driverUtilization: '94.0%',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Peak Hours & Mobility Demand Heatmap
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Hourly passenger ride request volume, dynamic surge pricing activations, and fleet
        utilization rates.
      </p>
    </div>

    <ReportFilterBar report-title="Peak Hours Demand Heatmap" />

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Demand Curves by Operational Window</h2>
        <span class="text-xs text-neutral-400">Peak demand triggers dynamic incentive routing</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Time Window</th>
            <th class="py-3 px-4">Mobility Classification</th>
            <th class="py-3 px-4">Average Surge Factor</th>
            <th class="py-3 px-4">Hourly Requests</th>
            <th class="py-3 px-4 text-right">Fleet Driver Utilization</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="h in hourlyDemand"
            :key="h.timeWindow"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ h.timeWindow }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">{{ h.period }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  h.avgSurge !== '1.05x'
                    ? 'bg-amber-100 text-amber-800'
                    : 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ h.avgSurge }}
              </span>
            </td>
            <td class="py-3 px-4 font-semibold text-neutral-800">
              {{ h.rideRequests.toLocaleString() }} rides
            </td>
            <td class="py-3 px-4 text-right font-mono font-bold text-emerald-600">
              {{ h.driverUtilization }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
