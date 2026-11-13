<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface RevenueSummaryRow {
  period: string
  zoneKey: string
  zoneLabel: string
  grossVolumePhp: number
  platformCommissionPhp: number
  driverTakeHomePhp: number
  effectiveCutPercent: string
}

const financialSummaries = ref<RevenueSummaryRow[]>([
  {
    period: 'November 2026 (MTD)',
    zoneKey: 'poblacion',
    zoneLabel: 'Poblacion & Agora Market',
    grossVolumePhp: 1124500,
    platformCommissionPhp: 168675,
    driverTakeHomePhp: 955825,
    effectiveCutPercent: '15.0%',
  },
  {
    period: 'October 2026',
    zoneKey: 'terminal',
    zoneLabel: 'Integrated Bus Terminal',
    grossVolumePhp: 1480200,
    platformCommissionPhp: 222030,
    driverTakeHomePhp: 1258170,
    effectiveCutPercent: '15.0%',
  },
  {
    period: 'October 2026',
    zoneKey: 'dao-capitol',
    zoneLabel: 'Dao Capitol & Gaisano',
    grossVolumePhp: 1360000,
    platformCommissionPhp: 204000,
    driverTakeHomePhp: 1156000,
    effectiveCutPercent: '15.0%',
  },
  {
    period: 'September 2026',
    zoneKey: 'santiago-port',
    zoneLabel: 'Santiago Port & Coastal',
    grossVolumePhp: 790400,
    platformCommissionPhp: 102752,
    driverTakeHomePhp: 687648,
    effectiveCutPercent: '13.0%',
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredSummaries = computed(() =>
  financialSummaries.value.filter(
    (row) =>
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone,
  ),
)

const handleExport = () => {
  exportToCsv(
    'pagadian-revenue-commission-report.csv',
    [
      'Period',
      'Corridor',
      'Gross Bookings (PHP)',
      'Platform Commission (PHP)',
      'Driver Cash Take-Home (PHP)',
      'Effective Cut',
    ],
    filteredSummaries.value.map((r) => [
      r.period,
      r.zoneLabel,
      r.grossVolumePhp.toFixed(2),
      r.platformCommissionPhp.toFixed(2),
      r.driverTakeHomePhp.toFixed(2),
      r.effectiveCutPercent,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Platform Revenue &amp; Commission Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Gross cash booking volume, prepaid wallet commission deductions (1500 bps baseline), and net
        Pagadian taxicle driver take-home totals.
      </p>
    </div>

    <ReportFilterBar
      report-title="Revenue & Commission Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Financial Settlement Summary by Corridor</h2>
        <span class="text-xs text-neutral-400">Prepaid credit wallet deduction model</span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Accounting Period</th>
              <th class="py-3 px-4">Corridor Zone</th>
              <th class="py-3 px-4">Gross Cash Bookings</th>
              <th class="py-3 px-4">Platform Commission</th>
              <th class="py-3 px-4">Driver Net Take-Home</th>
              <th class="py-3 px-4 text-right">Effective Cut</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="f in filteredSummaries"
              :key="`${f.period}-${f.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ f.period }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ f.zoneLabel }}</td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                {{ formatPhp(f.grossVolumePhp) }}
              </td>
              <td class="py-3 px-4 font-mono font-bold text-emerald-700 tabular-nums">
                {{ formatPhp(f.platformCommissionPhp) }}
              </td>
              <td class="py-3 px-4 font-mono text-neutral-700 tabular-nums">
                {{ formatPhp(f.driverTakeHomePhp) }}
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
                {{ f.effectiveCutPercent }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
