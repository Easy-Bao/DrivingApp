<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import { MotionConfig, motion } from 'motion-v'
import {
  FleetDistributionCard,
  TripVolumeChart,
  useOverviewMetrics,
  type DashboardKpiKey,
  type DashboardTimeframe,
} from '@/features/dashboard'
import { TripDetailsModal, useTrips, type TripRecord, type TripStatus } from '@/features/trips'
import {
  BaseSelect,
  BookingIdCell,
  EmptyTableRow,
  PageHeader,
  SegmentedToggle,
  StatusBadge,
  TablePagination,
  formatCentavos,
  useDataTable,
} from '@/shared'

const timeframe = ref<DashboardTimeframe>('today')
const { activeDataset, totalTrips, totalRevenuePhp, kpis } = useOverviewMetrics(timeframe)

const KPI_ICONS: Record<DashboardKpiKey, string> = {
  rides: 'lucide:navigation',
  drivers: 'lucide:users',
  revenue: 'lucide:banknote',
  completion: 'lucide:check-circle-2',
}

const timeframeOptions = [
  { label: 'Today', value: 'today' },
  { label: '7 Days', value: '7d' },
  { label: '30 Days', value: '30d' },
] as const

const { trips, tripStatusTone } = useTrips()
const statusFilter = ref<'all' | TripStatus>('all')
const selectedTrip = ref<TripRecord | null>(null)

const filteredTrips = computed(() => {
  if (statusFilter.value === 'all') return trips.value
  return trips.value.filter((trip) => trip.status === statusFilter.value)
})

const {
  currentPage,
  itemsPerPage,
  paginatedItems: paginatedTrips,
} = useDataTable(filteredTrips, {
  initialPageSize: 5,
  resetDeps: [statusFilter],
})
</script>

<template>
  <MotionConfig reducedMotion="user">
    <div class="space-y-6">
      <PageHeader
        title="Overview"
        description="Monitor dispatch volume, fleet activity, and trip fare performance."
      >
        <template #actions>
          <SegmentedToggle
            v-model="timeframe"
            aria-label="Dashboard timeframe"
            :options="timeframeOptions"
          />
        </template>
      </PageHeader>

      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 sm:gap-4">
        <div
          v-for="kpi in kpis"
          :key="kpi.label"
          class="p-5 bg-white rounded-none border border-neutral-200 border-t-2 border-t-neutral-900 flex flex-col gap-1.5"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-[11px] font-semibold text-neutral-500 uppercase tracking-wider">
              {{ kpi.label }}
            </span>
            <Icon
              :icon="KPI_ICONS[kpi.key]"
              class="h-4 w-4 text-neutral-400 shrink-0"
              aria-hidden="true"
            />
          </div>
          <motion.div
            :key="`${timeframe}-${kpi.value}`"
            :initial="{ opacity: 0, y: 4 }"
            :animate="{ opacity: 1, y: 0 }"
            :transition="{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }"
            class="space-y-1.5"
          >
            <div class="text-2xl sm:text-3xl font-bold text-neutral-900 tabular-nums">
              {{ kpi.value }}
            </div>
            <div class="text-xs font-medium text-neutral-500">
              <span class="font-semibold text-emerald-700">{{ kpi.change }}</span>
              {{ kpi.comparisonLabel }}
            </div>
          </motion.div>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <TripVolumeChart
          :series="activeDataset.series"
          :total-trips="totalTrips"
          :total-revenue-php="totalRevenuePhp"
        />
        <FleetDistributionCard
          :total-trips="totalTrips"
          :booking-mix="activeDataset.bookingMix"
          :status-mix="activeDataset.statusMix"
        />
      </div>

      <div class="bg-white rounded-none border border-neutral-200 overflow-hidden">
        <div
          class="p-4 sm:p-5 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
        >
          <div class="flex items-center gap-2">
            <h2 class="font-semibold text-sm text-neutral-900">Recent Trip Dispatches</h2>
            <span class="text-xs font-mono text-neutral-400 tabular-nums">
              ({{ filteredTrips.length }})
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <BaseSelect
              v-model="statusFilter"
              aria-label="Filter recent dispatches by status"
              :options="[
                { label: 'All Statuses', value: 'all' },
                { label: 'In Progress', value: 'In Progress' },
                { label: 'Dispatching', value: 'Dispatching' },
                { label: 'Completed', value: 'Completed' },
                { label: 'Cancelled', value: 'Cancelled' },
              ]"
            />
            <RouterLink
              to="/trips/all"
              class="text-xs font-semibold text-neutral-900 hover:underline shrink-0"
            >
              View All Trips →
            </RouterLink>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[780px] text-left text-xs">
            <thead
              class="bg-neutral-50 text-neutral-500 border-b border-neutral-100 uppercase font-semibold"
            >
              <tr>
                <th class="py-3 px-4">Booking ID</th>
                <th class="py-3 px-4">Passenger</th>
                <th class="py-3 px-4">Driver</th>
                <th class="py-3 px-4">Route</th>
                <th class="py-3 px-4">Trip Fare</th>
                <th class="py-3 px-4">Status</th>
                <th class="py-3 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-neutral-100 text-neutral-700">
              <tr
                v-for="trip in paginatedTrips"
                :key="trip.id"
                class="hover:bg-neutral-50/60 transition-colors"
              >
                <td class="py-3.5 px-4 whitespace-nowrap">
                  <BookingIdCell :booking-id="trip.id" />
                </td>
                <td class="py-3.5 px-4 font-medium text-neutral-900">{{ trip.rider }}</td>
                <td class="py-3.5 px-4">{{ trip.driver ?? 'Unassigned' }}</td>
                <td class="py-3.5 px-4 text-neutral-500 max-w-xs truncate">
                  {{ trip.pickup }} → {{ trip.dropoff }}
                </td>
                <td class="py-3.5 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                  {{ formatCentavos(trip.fareCentavos) }}
                </td>
                <td class="py-3.5 px-4">
                  <StatusBadge :label="trip.status" :tone="tripStatusTone(trip.status)" />
                </td>
                <td class="py-3.5 px-4 text-right whitespace-nowrap">
                  <button
                    type="button"
                    class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                    @click="selectedTrip = trip"
                  >
                    View Details
                  </button>
                </td>
              </tr>
              <EmptyTableRow
                v-if="paginatedTrips.length === 0"
                :colspan="7"
                title="No dispatches match the selected status"
                :show-reset="statusFilter !== 'all'"
                @reset="statusFilter = 'all'"
              />
            </tbody>
          </table>
        </div>

        <TablePagination
          v-model:current-page="currentPage"
          :total-items="filteredTrips.length"
          :items-per-page="itemsPerPage"
        />
      </div>

      <TripDetailsModal :trip="selectedTrip" @close="selectedTrip = null" />
    </div>
  </MotionConfig>
</template>
