<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  ReportFilterBar,
  createDefaultReportFilters,
  hasCustomReportFilters,
  useTripReports,
  type ReportFilterValues,
} from '@/features/reports'
import { EmptyTableRow, PageHeader, formatCentavos } from '@/shared'

const { filterTripRows, exportTripRows } = useTripReports()

const activeFilters = ref<ReportFilterValues>(createDefaultReportFilters())
const filteredRows = computed(() => filterTripRows(activeFilters.value))

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(() => hasCustomReportFilters(activeFilters.value))
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportTripRows(filteredRows.value)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Trips"
      description="Analyze completed trips, routes, and gross fare volume."
    />

    <ReportFilterBar
      ref="filterBarRef"
      report-title="Trip Volume Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <h2 class="font-bold text-sm text-neutral-900">Trip Aggregations by Day &amp; Corridor</h2>
        <span class="text-xs text-neutral-500">
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
              <th class="py-3 px-4">Corridor</th>
              <th class="py-3 px-4">Total Requested</th>
              <th class="py-3 px-4">Completed Rides</th>
              <th class="py-3 px-4">Cancelled Rides</th>
              <th class="py-3 px-4">Fleet Distance</th>
              <th class="py-3 px-4 text-right">Gross Bookings (PHP)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="row in filteredRows"
              :key="`${row.date}-${row.zoneKey}`"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ row.date }}</td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ row.zoneLabel }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-800">
                {{ row.totalRides.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-emerald-700 font-semibold">
                {{ row.completed.toLocaleString() }}
              </td>
              <td class="py-3 px-4 text-rose-600 font-medium">{{ row.cancelled }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">
                {{ row.totalKm.toLocaleString() }} km
              </td>
              <td class="py-3 px-4 text-right font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatCentavos(row.grossVolumeCentavos) }}
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredRows.length === 0"
              :colspan="7"
              title="No trip volume rows match your current filters"
              description="Adjust the corridor zone, dispatch mode, or date window to view trip aggregations."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
