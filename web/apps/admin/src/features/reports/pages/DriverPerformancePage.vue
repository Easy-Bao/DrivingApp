<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import { exportToCsv } from '@/shared/utils/format'

interface DriverPerformanceRow {
  driver: string
  plateNumber: string
  zoneKey: string
  tierKey: string
  trips: number
  rating: number
  acceptanceRate: string
  cancellationRate: string
  onTimeRate: string
}

const performanceList = ref<DriverPerformanceRow[]>([
  {
    driver: 'Rodelio Cruz',
    plateNumber: 'ZDS-4821 · TODA-0412',
    zoneKey: 'poblacion',
    tierKey: 'solo-standard',
    trips: 642,
    rating: 4.92,
    acceptanceRate: '98.2%',
    cancellationRate: '0.8%',
    onTimeRate: '99.1%',
  },
  {
    driver: 'Danilo Mendoza',
    plateNumber: 'ZDS-3019 · TODA-0194',
    zoneKey: 'terminal',
    tierKey: 'solo-express',
    trips: 814,
    rating: 4.95,
    acceptanceRate: '99.0%',
    cancellationRate: '0.5%',
    onTimeRate: '99.5%',
  },
  {
    driver: 'Reynaldo Bautista',
    plateNumber: 'ZDS-1944 · TODA-0277',
    zoneKey: 'dao-capitol',
    tierKey: 'solo-express',
    trips: 528,
    rating: 4.88,
    acceptanceRate: '95.4%',
    cancellationRate: '1.4%',
    onTimeRate: '97.8%',
  },
  {
    driver: 'Ernesto Villafuerte',
    plateNumber: 'ZDS-6120 · TODA-0318',
    zoneKey: 'santiago-port',
    tierKey: 'etrike',
    trips: 390,
    rating: 4.65,
    acceptanceRate: '89.1%',
    cancellationRate: '3.6%',
    onTimeRate: '93.2%',
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredList = computed(() =>
  performanceList.value.filter((row) => {
    const matchesZone =
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone
    const matchesTier =
      activeFilters.value.vehicleTier === 'all-tiers' ||
      row.tierKey === activeFilters.value.vehicleTier
    return matchesZone && matchesTier
  }),
)

const handleExport = () => {
  exportToCsv(
    'pagadian-driver-performance.csv',
    ['Driver', 'Plate', 'Trips', 'Rating', 'Acceptance', 'Cancellation', 'Punctuality'],
    filteredList.value.map((p) => [
      p.driver,
      p.plateNumber,
      String(p.trips),
      String(p.rating),
      p.acceptanceRate,
      p.cancellationRate,
      p.onTimeRate,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Driver Performance &amp; QA Metrics
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Pagadian fleet reliability scores, 4.5★ incentive eligibility, and bid response compliance.
      </p>
    </div>

    <ReportFilterBar
      report-title="Driver Performance Audit"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Taxicle Service Quality Benchmarks</h2>
        <span class="text-xs text-neutral-400">Bonus threshold: &gt;= 4.5★ rating</span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Driver &amp; TODA Unit</th>
              <th class="py-3 px-4">Trips Completed</th>
              <th class="py-3 px-4">Star Rating</th>
              <th class="py-3 px-4">Acceptance Rate</th>
              <th class="py-3 px-4">Cancellation Rate</th>
              <th class="py-3 px-4 text-right">Punctuality Score</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="p in filteredList"
              :key="p.driver"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ p.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ p.plateNumber }}</div>
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ p.trips.toLocaleString() }}
              </td>
              <td class="py-3 px-4 font-bold text-amber-600">★ {{ p.rating }}</td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">{{ p.acceptanceRate }}</td>
              <td class="py-3 px-4 text-rose-600 font-medium">{{ p.cancellationRate }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
                {{ p.onTimeRate }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
