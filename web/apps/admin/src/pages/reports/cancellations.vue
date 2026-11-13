<script setup lang="ts">
import { computed, ref } from 'vue'
import ReportFilterBar, {
  type ReportFilterValues,
} from '@/features/reports/components/ReportFilterBar.vue'
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

const handleExport = () => {
  exportToCsv(
    'pagadian-cancellation-analysis.csv',
    ['Root Cause', 'Incidents', 'Share', 'Responsibility Enum', 'Fee Rule'],
    filteredCauses.value.map((c) => [
      c.reason,
      String(c.count),
      sharePercent(c.count),
      c.responsibility,
      `${formatPhp(c.feePhp)} (${c.feeNote})`,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Trip Cancellation Root-Cause Analysis
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Breakdown of Pagadian ride cancellations aligned with backend responsibility
        classifications.
      </p>
    </div>

    <ReportFilterBar
      report-title="Cancellation Analysis Report"
      @change="activeFilters = $event"
      @export="handleExport"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
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
              v-for="c in filteredCauses"
              :key="c.reason"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ c.reason }}</td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-800">{{ c.count }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">{{ sharePercent(c.count) }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="c.responsibility"
                  :tone="
                    c.responsibility === 'passenger_fault'
                      ? 'warning'
                      : c.responsibility === 'driver_fault'
                        ? 'danger'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right font-mono font-medium text-neutral-700">
                {{ formatPhp(c.feePhp) }} · {{ c.feeNote }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
