<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import { exportToCsv } from '@/shared/utils/format'

interface ExpiryForecastRow {
  month: string
  zoneKey: string
  ltoLicensesExpiring: number
  todaMtopExpiring: number
  orCrExpiring: number
  insuranceExpiring: number
  complianceRate: string
}

const expiryForecast = ref<ExpiryForecastRow[]>([
  {
    month: 'November 2026',
    zoneKey: 'poblacion',
    ltoLicensesExpiring: 6,
    todaMtopExpiring: 9,
    orCrExpiring: 11,
    insuranceExpiring: 8,
    complianceRate: '98.1%',
  },
  {
    month: 'December 2026',
    zoneKey: 'terminal',
    ltoLicensesExpiring: 9,
    todaMtopExpiring: 14,
    orCrExpiring: 15,
    insuranceExpiring: 12,
    complianceRate: '97.5%',
  },
  {
    month: 'January 2027',
    zoneKey: 'dao-capitol',
    ltoLicensesExpiring: 5,
    todaMtopExpiring: 7,
    orCrExpiring: 8,
    insuranceExpiring: 6,
    complianceRate: '98.8%',
  },
  {
    month: 'February 2027',
    zoneKey: 'santiago-port',
    ltoLicensesExpiring: 4,
    todaMtopExpiring: 6,
    orCrExpiring: 7,
    insuranceExpiring: 5,
    complianceRate: '99.2%',
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredForecast = computed(() =>
  expiryForecast.value.filter(
    (row) =>
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone,
  ),
)

const totalAudits = (row: ExpiryForecastRow) =>
  row.ltoLicensesExpiring + row.todaMtopExpiring + row.orCrExpiring + row.insuranceExpiring

const handleExport = () => {
  exportToCsv(
    'pagadian-document-expiry-forecast.csv',
    ['Month', 'LTO Licenses', 'TODA MTOP Franchises', 'LTO OR/CR', 'Insurance', 'Compliance Rate'],
    filteredForecast.value.map((f) => [
      f.month,
      String(f.ltoLicensesExpiring),
      String(f.todaMtopExpiring),
      String(f.orCrExpiring),
      String(f.insuranceExpiring),
      f.complianceRate,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Fleet Document Expiry &amp; Compliance Forecast
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Quarterly projection of upcoming LTO Professional Driver License, Pagadian TODA MTOP
          franchise, LTO OR/CR, and insurance renewals.
        </p>
      </div>
      <RouterLink
        to="/documents/expiring"
        class="self-start sm:self-auto px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
      >
        Open Renewal Queue
      </RouterLink>
    </div>

    <ReportFilterBar
      report-title="Document Expiry & Compliance Forecast"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Document Renewal Projections</h2>
        <span class="text-xs text-neutral-400">
          Automated driver reminders trigger 30 days prior to expiry
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[800px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Forecast Month</th>
              <th class="py-3 px-4">LTO Prof. Licenses</th>
              <th class="py-3 px-4">TODA MTOP Permits</th>
              <th class="py-3 px-4">LTO OR/CR Units</th>
              <th class="py-3 px-4">Insurance Policies</th>
              <th class="py-3 px-4">Total Audits</th>
              <th class="py-3 px-4 text-right">Projected Compliance</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="f in filteredForecast"
              :key="f.month"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ f.month }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ f.ltoLicensesExpiring }} licenses
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ f.todaMtopExpiring }} franchises
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">{{ f.orCrExpiring }} units</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ f.insuranceExpiring }} policies
              </td>
              <td class="py-3 px-4 font-bold text-amber-700">{{ totalAudits(f) }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                {{ f.complianceRate }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
