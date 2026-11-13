<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
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

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(
  () =>
    activeFilters.value.dateRange !== 'last-30-days' ||
    activeFilters.value.cityZone !== 'all-zones' ||
    activeFilters.value.vehicleTier !== 'all-tiers',
)
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportToCsv(
    'pagadian-peak-hours-demand.csv',
    ['Time Window', 'Corridor', 'Classification', 'Surge Multiplier', 'Requests', 'Utilization'],
    filteredDemand.value.map((demand) => [
      demand.timeWindow,
      demand.corridorLabel,
      demand.period,
      `${demand.avgSurge.toFixed(2)}x`,
      String(demand.rideRequests),
      demand.driverUtilization,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Peak Hours &amp; Pagadian Demand Heatmap"
      description="Hourly passenger bidding request windows, surge multiplier averages (capped at 2.5x), and TODA utilization."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Peak Hours Demand Heatmap"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
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
              v-for="demand in filteredDemand"
              :key="demand.timeWindow"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">
                {{ demand.timeWindow }}
              </td>
              <td class="py-3 px-4 text-neutral-700">{{ demand.corridorLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">{{ demand.period }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="`${demand.avgSurge.toFixed(2)}x`"
                  :tone="demand.avgSurge >= 1.5 ? 'warning' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ demand.rideRequests.toLocaleString() }} bids
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                {{ demand.driverUtilization }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredDemand.length === 0"
              :colspan="6"
              title="No demand windows match your current filters"
              description="Adjust the corridor zone or report filters to inspect hourly demand curves."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
