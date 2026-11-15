<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useRiderCohortReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader, formatCentavos } from '@/shared'

const { filterCohortRows, totalCohortRiders, exportCohortRows } = useRiderCohortReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredCohorts = computed(() => filterCohortRows(activeFilters.value))
const totalActiveRiders = computed(() => totalCohortRiders(filteredCohorts.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportCohortRows(filteredCohorts.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Rider Stats"
      description="Analyze passenger cohorts, retention rates, and booking spend."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Passenger Cohort Activity"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Passenger Engagement Cohorts</h2>
        <span class="text-xs text-neutral-400">
          Filtered active population: {{ totalActiveRiders.toLocaleString() }} passengers
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[760px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Cohort Segment</th>
              <th class="py-3 px-4">Primary Corridor</th>
              <th class="py-3 px-4">Active Passenger Population</th>
              <th class="py-3 px-4">30-Day Retention</th>
              <th class="py-3 px-4 text-right">Average Monthly Spend (PHP)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="cohort in filteredCohorts"
              :key="cohort.cohort"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-bold text-neutral-900">{{ cohort.cohort }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ cohort.corridorFocus }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800 tabular-nums">
                {{ cohort.ridersCount.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">{{ cohort.retentionRate }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatCentavos(cohort.avgMonthlySpendCentavos) }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredCohorts.length === 0"
              :colspan="5"
              title="No passenger cohorts match your current filters"
              description="Adjust the corridor zone or report filters to review retention segments."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
