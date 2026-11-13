<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import TripDetailsModal from '@/features/trips/components/TripDetailsModal.vue'
import { useTrips, type TripRecord, type TripStatus } from '@/features/trips/composables/use-trips'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import BookingIdCell from '@/shared/display/BookingIdCell.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

const { trips, tripStatusTone } = useTrips()

const searchQuery = ref('')
const filterStatus = ref<'all' | TripStatus>('all')
const currentPage = ref(1)
const itemsPerPage = 8
const selectedTrip = ref<TripRecord | null>(null)
const toastMessage = ref<string | null>(null)

const hasActiveFilters = computed(() => searchQuery.value !== '' || filterStatus.value !== 'all')

function resetFilters() {
  searchQuery.value = ''
  filterStatus.value = 'all'
  currentPage.value = 1
}

const filteredTrips = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return trips.value.filter((trip) => {
    if (filterStatus.value !== 'all' && trip.status !== filterStatus.value) {
      return false
    }
    if (!query) return true
    return (
      trip.id.toLowerCase().includes(query) ||
      trip.rider.toLowerCase().includes(query) ||
      trip.driver.toLowerCase().includes(query) ||
      trip.pickup.toLowerCase().includes(query) ||
      trip.dropoff.toLowerCase().includes(query) ||
      trip.plateNumber.toLowerCase().includes(query)
    )
  })
})

watch([searchQuery, filterStatus], () => {
  currentPage.value = 1
})

const paginatedTrips = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredTrips.value.slice(start, start + itemsPerPage)
})

const averageFare = computed(() => {
  if (trips.value.length === 0) return 0
  return trips.value.reduce((sum, trip) => sum + trip.fare, 0) / trips.value.length
})

const handleExport = () => {
  const ok = exportToCsv(
    'easyride-trips.csv',
    ['Booking ID', 'Passenger', 'Driver', 'Plate', 'Pick Up', 'Drop Off', 'Trip Fare', 'Status'],
    filteredTrips.value.map((trip) => [
      trip.id,
      trip.rider,
      trip.driver,
      trip.plateNumber,
      trip.pickup,
      trip.dropoff,
      formatPhp(trip.fare),
      trip.status,
    ]),
  )
  toastMessage.value = ok ? 'Trip history exported.' : 'No matching trips to export.'
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="All Trips"
      description="Monitor trip records, bidding fares, and completion status."
    />

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Completed</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ trips.filter((trip) => trip.status === 'Completed').length }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Active</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{
            trips.filter((trip) => trip.status === 'In Progress' || trip.status === 'Dispatching')
              .length
          }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Avg Fare</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatPhp(averageFare) }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Completion Rate</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">96.4%</div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="w-full sm:w-72">
          <SearchField
            v-model="searchQuery"
            placeholder="Search booking ID, rider, driver, route..."
            aria-label="Search trips"
          />
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="filterStatus"
            aria-label="Filter trips by status"
            :options="[
              { label: 'All Statuses', value: 'all' },
              { label: 'Completed', value: 'Completed' },
              { label: 'In Progress', value: 'In Progress' },
              { label: 'Dispatching', value: 'Dispatching' },
              { label: 'Cancelled', value: 'Cancelled' },
            ]"
          />
          <button
            type="button"
            class="inline-flex items-center justify-center space-x-1.5 px-3 py-1.5 bg-white border border-neutral-300 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 transition-colors cursor-pointer"
            @click="handleExport"
          >
            <Icon icon="lucide:download" class="w-3.5 h-3.5" aria-hidden="true" />
            <span>Export</span>
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Booking ID</th>
              <th class="py-3 px-4">Passenger</th>
              <th class="py-3 px-4">Driver &amp; Unit</th>
              <th class="py-3 px-4">Route</th>
              <th class="py-3 px-4">Trip Fare</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="trip in paginatedTrips"
              :key="trip.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 whitespace-nowrap">
                <BookingIdCell :booking-id="trip.id" />
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ trip.rider }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ trip.riderPhone }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-800">{{ trip.driver }}</div>
                <div class="text-[11px] text-neutral-400">
                  {{ trip.vehicleModel }} ({{ trip.plateNumber }})
                </div>
              </td>
              <td class="py-3 px-4 max-w-xs truncate">
                <div class="truncate text-neutral-800 font-medium">{{ trip.pickup }}</div>
                <div class="truncate text-[11px] text-neutral-400">→ {{ trip.dropoff }}</div>
              </td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(trip.fare) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="trip.status" :tone="tripStatusTone(trip.status)" />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
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
              title="No trip records match the active filter criteria"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
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
</template>
