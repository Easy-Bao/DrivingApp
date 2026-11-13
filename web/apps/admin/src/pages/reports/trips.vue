<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface TripReportRow {
  date: string
  zoneKey: string
  zoneLabel: string
  tierKey: string
  totalRides: number
  completed: number
  cancelled: number
  totalKm: number
  grossVolumePhp: number
}

const tripReportData = ref<TripReportRow[]>([
  {
    date: '2026-11-12',
    zoneKey: 'poblacion',
    zoneLabel: 'Poblacion & Agora Market',
    tierKey: 'tuktuk-standard',
    totalRides: 1480,
    completed: 1412,
    cancelled: 68,
    totalKm: 4120,
    grossVolumePhp: 88940,
  },
  {
    date: '2026-11-12',
    zoneKey: 'terminal',
    zoneLabel: 'Integrated Bus Terminal',
    tierKey: 'tuktuk-express',
    totalRides: 960,
    completed: 918,
    cancelled: 42,
    totalKm: 3840,
    grossVolumePhp: 94550,
  },
  {
    date: '2026-11-11',
    zoneKey: 'dao-capitol',
    zoneLabel: 'Dao Capitol & Gaisano',
    tierKey: 'tuktuk-express',
    totalRides: 1120,
    completed: 1068,
    cancelled: 52,
    totalKm: 3910,
    grossVolumePhp: 92800,
  },
  {
    date: '2026-11-10',
    zoneKey: 'santiago-port',
    zoneLabel: 'Santiago Port & Coastal',
    tierKey: 'ebao-pioneer',
    totalRides: 690,
    completed: 662,
    cancelled: 28,
    totalKm: 1950,
    grossVolumePhp: 38240,
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredRows = computed(() => {
  return tripReportData.value.filter((row) => {
    const matchesZone =
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone
    const matchesTier =
      activeFilters.value.vehicleTier === 'all-tiers' ||
      row.tierKey === activeFilters.value.vehicleTier
    const matchesDate = activeFilters.value.dateRange !== 'today' || row.date === '2026-11-12'
    return matchesZone && matchesTier && matchesDate
  })
})

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
    'pagadian-trip-volume-report.csv',
    ['Date', 'Zone', 'Requested', 'Completed', 'Cancelled', 'Distance (km)', 'Gross (PHP)'],
    filteredRows.value.map((row) => [
      row.date,
      row.zoneLabel,
      String(row.totalRides),
      String(row.completed),
      String(row.cancelled),
      String(row.totalKm),
      row.grossVolumePhp.toFixed(2),
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Trip Volume &amp; Mobility Reports"
      description="Aggregated Pagadian City taxicle trip completions, corridor distances, and PHP booking volume."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Pagadian Trip Volume Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Trip Aggregations by Day &amp; Corridor</h2>
        <span class="text-xs text-neutral-400">
          Showing {{ filteredRows.length }} matching ledger groups
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Date</th>
              <th class="py-3 px-4">Pagadian Corridor</th>
              <th class="py-3 px-4">Total Requested</th>
              <th class="py-3 px-4">Completed Rides</th>
              <th class="py-3 px-4">Cancelled Rides</th>
              <th class="py-3 px-4">Fleet Distance</th>
              <th class="py-3 px-4 text-right">Gross Bookings (PHP)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="row in filteredRows"
              :key="`${row.date}-${row.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ row.date }}</td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ row.zoneLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ row.totalRides.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">
                {{ row.completed.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-rose-600 font-medium">{{ row.cancelled }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">
                {{ row.totalKm.toLocaleString() }} km
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(row.grossVolumePhp) }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredRows.length === 0"
              :colspan="7"
              title="No trip volume rows match your current filters"
              description="Adjust the corridor zone, taxicle tier, or date window to view trip aggregations."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
