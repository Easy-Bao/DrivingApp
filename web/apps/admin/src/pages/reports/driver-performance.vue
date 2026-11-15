<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useDriverPerformanceReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader } from '@/shared'

const { filterPerformanceRows, exportPerformanceRows } = useDriverPerformanceReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredList = computed(() => filterPerformanceRows(activeFilters.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportPerformanceRows(filteredList.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Driver Stats"
      description="Review driver completion rates, ratings, and punctuality."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Driver Performance Audit"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Service Quality Benchmarks</h2>
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
              v-for="metric in filteredList"
              :key="metric.driver"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ metric.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ metric.plateNumber }}</div>
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ metric.trips.toLocaleString() }}
              </td>
              <td class="py-3 px-4 font-bold text-amber-600">★ {{ metric.rating }}</td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">{{ metric.acceptanceRate }}</td>
              <td class="py-3 px-4 text-rose-600 font-medium">{{ metric.cancellationRate }}</td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900">
                {{ metric.onTimeRate }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredList.length === 0"
              :colspan="6"
              title="No driver performance rows match your current filters"
              description="Adjust the corridor zone, dispatch mode, or date window to review quality metrics."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
