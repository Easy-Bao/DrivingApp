<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface RiderCohortRow {
  cohort: string
  zoneKey: string
  corridorFocus: string
  ridersCount: number
  retentionRate: string
  avgMonthlySpendPhp: number
}

const cohortActivity = ref<RiderCohortRow[]>([
  {
    cohort: 'Daily Poblacion & Office Commuters (12+ rides/mo)',
    zoneKey: 'poblacion',
    corridorFocus: 'Poblacion & Agora Market',
    ridersCount: 1840,
    retentionRate: '94.2%',
    avgMonthlySpendPhp: 780,
  },
  {
    cohort: 'Integrated Bus Terminal Travelers (5-11 rides/mo)',
    zoneKey: 'terminal',
    corridorFocus: 'Integrated Bus Terminal',
    ridersCount: 2620,
    retentionRate: '86.5%',
    avgMonthlySpendPhp: 540,
  },
  {
    cohort: 'College & Senior High Students (4-10 rides/mo)',
    zoneKey: 'dao-capitol',
    corridorFocus: 'Dao Capitol & Gaisano',
    ridersCount: 3190,
    retentionRate: '88.1%',
    avgMonthlySpendPhp: 365,
  },
  {
    cohort: 'Weekend Coastal & Market Riders (1-3 rides/mo)',
    zoneKey: 'santiago-port',
    corridorFocus: 'Santiago Port & Coastal',
    ridersCount: 1410,
    retentionRate: '64.8%',
    avgMonthlySpendPhp: 195,
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredCohorts = computed(() =>
  cohortActivity.value.filter(
    (row) =>
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone,
  ),
)

const totalActiveRiders = computed(() =>
  filteredCohorts.value.reduce((sum, row) => sum + row.ridersCount, 0),
)

const handleExport = () => {
  exportToCsv(
    'pagadian-passenger-cohorts.csv',
    ['Cohort Segment', 'Primary Zone', 'Active Passengers', '30-Day Retention', 'Avg Spend (PHP)'],
    filteredCohorts.value.map((c) => [
      c.cohort,
      c.corridorFocus,
      String(c.ridersCount),
      c.retentionRate,
      c.avgMonthlySpendPhp.toFixed(2),
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Passenger Activity &amp; Cohort Analytics
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Pagadian City passenger retention segments, corridor booking cadence, and monthly PHP fare
        spend.
      </p>
    </div>

    <ReportFilterBar
      report-title="Passenger Cohort Activity"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Passenger Engagement Cohorts</h2>
        <span class="text-xs text-neutral-400">
          Filtered active population: {{ totalActiveRiders.toLocaleString() }} passengers
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[760px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Cohort Segment</th>
              <th class="py-3 px-4">Primary Corridor</th>
              <th class="py-3 px-4">Active Passenger Population</th>
              <th class="py-3 px-4">30-Day Retention</th>
              <th class="py-3 px-4 text-right">Average Monthly Spend (PHP)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="c in filteredCohorts"
              :key="c.cohort"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ c.cohort }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ c.corridorFocus }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800 tabular-nums">
                {{ c.ridersCount.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">{{ c.retentionRate }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(c.avgMonthlySpendPhp) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
