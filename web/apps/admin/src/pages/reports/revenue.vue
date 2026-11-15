<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useRevenueReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader, formatCentavos } from '@/shared'

const { filterRevenueRows, exportRevenueRows } = useRevenueReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredSummaries = computed(() => filterRevenueRows(activeFilters.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportRevenueRows(filteredSummaries.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Revenue"
      description="Track platform commission, cash volume, and driver net earnings."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Revenue & Commission Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
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
              v-for="summary in filteredSummaries"
              :key="`${summary.period}-${summary.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ summary.period }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ summary.zoneLabel }}</td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                {{ formatCentavos(summary.grossVolumeCentavos) }}
              </td>
              <td class="py-3 px-4 font-mono font-bold text-emerald-700 tabular-nums">
                {{ formatCentavos(summary.platformCommissionCentavos) }}
              </td>
              <td class="py-3 px-4 font-mono text-neutral-700 tabular-nums">
                {{ formatCentavos(summary.driverTakeHomeCentavos) }}
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
                {{ summary.effectiveCutPercent }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredSummaries.length === 0"
              :colspan="6"
              title="No revenue summaries match your current filters"
              description="Adjust the corridor zone or report filters to review settlement totals."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
