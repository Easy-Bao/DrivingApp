<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useCancellationReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader, StatusBadge, formatCentavos } from '@/shared'

const { filterCauseRows, sharePercent, exportCauseRows } = useCancellationReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredCauses = computed(() => filterCauseRows(activeFilters.value))
const totalCancellations = computed(() =>
  filteredCauses.value.reduce((sum, item) => sum + item.count, 0),
)

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportCauseRows(filteredCauses.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Cancellations"
      description="Inspect trip cancellation causes, responsibility, and fee rules."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Cancellation Analysis Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Cancellation Reasons Breakdown</h2>
        <span class="text-xs text-neutral-400">
          Filtered cancellations: {{ totalCancellations.toLocaleString() }} incidents
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Primary Root Cause</th>
              <th class="py-3 px-4">Incidents</th>
              <th class="py-3 px-4">Share</th>
              <th class="py-3 px-4">Responsibility Enum</th>
              <th class="py-3 px-4 text-right">Fee Rule (PHP)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="cause in filteredCauses"
              :key="`${cause.zoneKey}-${cause.reason}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ cause.reason }}</td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-800">{{ cause.count }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">
                {{ sharePercent(cause.count, totalCancellations) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="cause.responsibility"
                  :tone="
                    cause.responsibility === 'passenger_fault'
                      ? 'warning'
                      : cause.responsibility === 'driver_fault'
                        ? 'danger'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right font-mono font-medium text-neutral-700">
                {{ formatCentavos(cause.feeCentavos) }} · {{ cause.feeNote }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredCauses.length === 0"
              :colspan="5"
              title="No cancellation root causes match your current filters"
              description="Adjust the corridor zone or report filters to review cancellation breakdowns."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
