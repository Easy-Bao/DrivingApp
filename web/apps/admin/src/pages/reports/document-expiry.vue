<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useDocumentExpiryReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader } from '@/shared'

const { filterForecastRows, totalAudits, exportForecastRows } = useDocumentExpiryReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredForecast = computed(() => filterForecastRows(activeFilters.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportForecastRows(filteredForecast.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Expiry Forecast"
      description="Project upcoming driver license, permit, and insurance renewals."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Document Expiry & Compliance Forecast"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <h2 class="font-bold text-sm text-neutral-900">Document Renewal Projections</h2>
          <p class="text-xs text-neutral-400 mt-0.5">
            Automated driver reminders trigger 30 days prior to expiry
          </p>
        </div>
        <RouterLink
          to="/documents/expiring"
          class="self-start sm:self-auto px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 shrink-0"
        >
          Open Renewal Queue
        </RouterLink>
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
              v-for="forecast in filteredForecast"
              :key="`${forecast.month}-${forecast.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ forecast.month }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ forecast.ltoLicensesExpiring }} licenses
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ forecast.todaMtopExpiring }} franchises
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ forecast.orCrExpiring }} units
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ forecast.insuranceExpiring }} policies
              </td>
              <td class="py-3 px-4 font-bold text-neutral-900">{{ totalAudits(forecast) }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
                {{ forecast.complianceRate }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredForecast.length === 0"
              :colspan="7"
              title="No document expiry projections match your current filters"
              description="Adjust the corridor zone or report filters to inspect renewal forecasts."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
