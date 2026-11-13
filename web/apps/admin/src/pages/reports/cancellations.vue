<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface CancellationCauseRow {
  reason: string
  zoneKey: string
  count: number
  responsibility: 'driver_fault' | 'passenger_fault' | 'system_fault' | 'no_fault'
  feePhp: number
  feeNote: string
}

const cancellationCauses = ref<CancellationCauseRow[]>([
  {
    reason: 'Driver delayed in Agora market traffic (> 6 min ETA overrun)',
    zoneKey: 'poblacion',
    count: 142,
    responsibility: 'driver_fault',
    feePhp: 0,
    feeNote: 'Fee Waived',
  },
  {
    reason: 'Passenger no-show at Integrated Bus Terminal bay after 5 min grace window',
    zoneKey: 'terminal',
    count: 96,
    responsibility: 'passenger_fault',
    feePhp: 15.0,
    feeNote: 'Standard ₱15 Fee Applied',
  },
  {
    reason: 'Passenger cancelled bidding session within 3-minute grace window',
    zoneKey: 'dao-capitol',
    count: 84,
    responsibility: 'no_fault',
    feePhp: 0,
    feeNote: 'Within Grace Period',
  },
  {
    reason: 'Taxicle mechanical blowout en route to pickup',
    zoneKey: 'santiago-port',
    count: 28,
    responsibility: 'driver_fault',
    feePhp: 0,
    feeNote: 'Auto-Rematched',
  },
  {
    reason: 'No driver bid submitted before 90s session countdown expiry',
    zoneKey: 'terminal',
    count: 34,
    responsibility: 'system_fault',
    feePhp: 0,
    feeNote: 'No Charge',
  },
])

const activeFilters = ref<ReportFilterValues>({
  dateRange: 'last-30-days',
  cityZone: 'all-zones',
  vehicleTier: 'all-tiers',
})

const filteredCauses = computed(() =>
  cancellationCauses.value.filter(
    (row) =>
      activeFilters.value.cityZone === 'all-zones' || row.zoneKey === activeFilters.value.cityZone,
  ),
)

const totalCancellations = computed(() =>
  filteredCauses.value.reduce((sum, item) => sum + item.count, 0),
)

const sharePercent = (count: number) => {
  if (totalCancellations.value === 0) return '0.0%'
  return `${((count / totalCancellations.value) * 100).toFixed(1)}%`
}

const filterBarRef = ref<InstanceType<typeof ReportFilterBar> | null>(null)
const hasActiveFilters = computed(
  () =>
    activeFilters.value.dateRange !== 'last-30-days' ||
    activeFilters.value.cityZone !== 'all-zones' ||
    activeFilters.value.vehicleTier !== 'all-tiers',
)
const resetFilters = () => filterBarRef.value?.resetFilters()

const handleExport = () => {
  exportToCsv(
    'pagadian-cancellation-analysis.csv',
    ['Root Cause', 'Incidents', 'Share', 'Responsibility Enum', 'Fee Rule'],
    filteredCauses.value.map((cause) => [
      cause.reason,
      String(cause.count),
      sharePercent(cause.count),
      cause.responsibility,
      `${formatPhp(cause.feePhp)} (${cause.feeNote})`,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Trip Cancellation Root-Cause Analysis"
      description="Breakdown of Pagadian ride cancellations aligned with backend responsibility classifications."
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
              :key="cause.reason"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ cause.reason }}</td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-800">{{ cause.count }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">{{ sharePercent(cause.count) }}</td>
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
                {{ formatPhp(cause.feePhp) }} · {{ cause.feeNote }}
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
