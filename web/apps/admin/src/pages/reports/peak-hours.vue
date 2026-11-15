<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  usePeakHoursReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader, StatusBadge } from '@/shared'

const { maxSurgeCapLabel, filterDemandRows, exportDemandRows } = usePeakHoursReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredDemand = computed(() => filterDemandRows(activeFilters.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportDemandRows(filteredDemand.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Peak Demand"
      description="Monitor peak booking windows, surge levels, and utilization."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Peak Hours Demand Heatmap"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Demand Curves by Operational Window</h2>
        <span class="text-xs text-neutral-400">
          Hard server surge ceiling: {{ maxSurgeCapLabel }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Time Window</th>
              <th class="py-3 px-4">Corridor</th>
              <th class="py-3 px-4">Classification</th>
              <th class="py-3 px-4">Avg Surge Multiplier</th>
              <th class="py-3 px-4">Requests</th>
              <th class="py-3 px-4 text-right">Fleet Utilization</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="demand in filteredDemand"
              :key="`${demand.timeWindow}-${demand.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">
                {{ demand.timeWindow }}
              </td>
              <td class="py-3 px-4 text-neutral-700">{{ demand.corridorLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">{{ demand.period }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="`${demand.avgSurge.toFixed(2)}x`"
                  :tone="demand.avgSurge >= 1.5 ? 'warning' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ demand.rideRequests.toLocaleString() }} bids
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                {{ demand.driverUtilization }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredDemand.length === 0"
              :colspan="6"
              title="No demand windows match your current filters"
              description="Adjust the corridor zone or report filters to inspect hourly demand curves."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
