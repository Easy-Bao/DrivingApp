<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import { exportToCsv } from '@/shared/utils/format'

interface DemandWindowRow {
  timeWindow: string
  zoneKey: string
  corridorLabel: string
  period: string
  avgSurge: number
  rideRequests: number
  driverUtilization: string
}

const hourlyDemand = ref<DemandWindowRow[]>([
  {
    timeWindow: '06:30 - 09:00 PHT',
    zoneKey: 'poblacion',
    corridorLabel: 'Poblacion & Agora Market',
    period: 'Morning Market & School Rush',
    avgSurge: 1.4,
    rideRequests: 680,
    driverUtilization: '96.2%',
  },
  {
    timeWindow: '11:30 - 13:30 PHT',
    zoneKey: 'dao-capitol',
    corridorLabel: 'Dao Capitol & Gaisano',
    period: 'Provincial Office & Midday Commerce',
    avgSurge: 1.1,
    rideRequests: 420,
    driverUtilization: '78.4%',
  },
  {
    timeWindow: '16:30 - 19:00 PHT',
    zoneKey: 'terminal',
    corridorLabel: 'Integrated Bus Terminal',
    period: 'Evening Bus Arrival & Commute Peak',
    avgSurge: 1.8,
    rideRequests: 840,
    driverUtilization: '98.5%',
  },
  {
    timeWindow: '19:30 - 22:00 PHT',
    zoneKey: 'santiago-port',
    corridorLabel: 'Santiago Port & Coastal',
    period: 'Coastal Ferry & Boulevard Evening Peak',
    avgSurge: 1.5,
    rideRequests: 390,
    driverUtilization: '91.0%',
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredDemand = computed(() =>
  hourlyDemand.value.filter(
    (row) =>
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone,
  ),
)

const handleExport = () => {
  exportToCsv(
    'pagadian-peak-hours-demand.csv',
    ['Time Window', 'Corridor', 'Classification', 'Surge Multiplier', 'Requests', 'Utilization'],
    filteredDemand.value.map((h) => [
      h.timeWindow,
      h.corridorLabel,
      h.period,
      `${h.avgSurge.toFixed(2)}x`,
      String(h.rideRequests),
      h.driverUtilization,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Peak Hours &amp; Pagadian Demand Heatmap
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Hourly passenger bidding request windows, surge multiplier averages (capped at 2.5x), and
        TODA utilization.
      </p>
    </div>

    <ReportFilterBar
      report-title="Peak Hours Demand Heatmap"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Demand Curves by Operational Window</h2>
        <span class="text-xs text-neutral-400">Hard server surge ceiling: 2.50x</span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Time Window</th>
              <th class="py-3 px-4">Pagadian Corridor</th>
              <th class="py-3 px-4">Classification</th>
              <th class="py-3 px-4">Avg Surge Multiplier</th>
              <th class="py-3 px-4">Requests</th>
              <th class="py-3 px-4 text-right">Taxicle Utilization</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="h in filteredDemand"
              :key="h.timeWindow"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ h.timeWindow }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ h.corridorLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">{{ h.period }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="`${h.avgSurge.toFixed(2)}x`"
                  :tone="h.avgSurge >= 1.5 ? 'warning' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ h.rideRequests.toLocaleString() }} bids
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                {{ h.driverUtilization }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
