<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
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
    tierKey: 'solo-standard',
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
    tierKey: 'solo-express',
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
    tierKey: 'solo-express',
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
    tierKey: 'etrike',
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

const handleExport = () => {
  exportToCsv(
    'pagadian-trip-volume-report.csv',
    ['Date', 'Zone', 'Requested', 'Completed', 'Cancelled', 'Distance (km)', 'Gross (PHP)'],
    filteredRows.value.map((r) => [
      r.date,
      r.zoneLabel,
      String(r.totalRides),
      String(r.completed),
      String(r.cancelled),
      String(r.totalKm),
      r.grossVolumePhp.toFixed(2),
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Trip Volume &amp; Mobility Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Aggregated Pagadian City taxicle trip completions, corridor distances, and PHP booking
        volume.
      </p>
    </div>

    <ReportFilterBar
      report-title="Pagadian Trip Volume Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
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
              v-for="r in filteredRows"
              :key="`${r.date}-${r.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ r.date }}</td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ r.zoneLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ r.totalRides.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">
                {{ r.completed.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-rose-600 font-medium">{{ r.cancelled }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">
                {{ r.totalKm.toLocaleString() }} km
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(r.grossVolumePhp) }}
              </td>
            </tr>
            <tr v-if="filteredRows.length === 0">
              <td colspan="7" class="py-10 px-4 text-center text-xs text-neutral-500">
                No trip volume rows match the active zone, tier, or date filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
