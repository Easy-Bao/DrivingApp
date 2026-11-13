<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

type TripStatus = 'Completed' | 'In Progress' | 'Dispatching' | 'Cancelled'

interface TripRecord {
  id: string
  rider: string
  riderPhone: string
  driver: string
  driverPhone: string
  plateNumber: string
  vehicleModel: string
  pickup: string
  dropoff: string
  fare: number
  distanceKm: number
  duration: string
  paymentMethod: 'Cash' | 'Cash + Tip'
  status: TripStatus
  timestamp: string
}

const searchQuery = ref('')
const filterStatus = ref<'all' | TripStatus>('all')
const currentPage = ref(1)
const itemsPerPage = 10
const selectedTrip = ref<TripRecord | null>(null)
const toastMessage = ref<string | null>(null)

const trips = ref<TripRecord[]>([
  {
    id: 'TRP-7016-8921',
    rider: 'Althea Mae Villanueva',
    riderPhone: '+63 935 812 4091',
    driver: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    plateNumber: '1284-ND',
    vehicleModel: 'Bajaj RE 4S (Solo Taxicle)',
    pickup: 'Brgy. San Jose, Pagadian City',
    dropoff: 'Agora Public Market, Poblacion',
    fare: 55.0,
    distanceKm: 3.4,
    duration: '12 mins',
    paymentMethod: 'Cash',
    status: 'In Progress',
    timestamp: '8 mins ago',
  },
  {
    id: 'TRP-7016-8920',
    rider: 'Carlo Magno Ocampo',
    riderPhone: '+63 917 650 3182',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    plateNumber: '4912-NC',
    vehicleModel: 'Kawasaki Barako II (Solo Taxicle)',
    pickup: 'Brgy. Gatas, Pagadian City',
    dropoff: "Robinson's Place Pagadian, Tiguma",
    fare: 65.0,
    distanceKm: 4.1,
    duration: '15 mins',
    paymentMethod: 'Cash + Tip',
    status: 'Completed',
    timestamp: '19 mins ago',
  },
  {
    id: 'TRP-7016-8919',
    rider: 'Jessa Mae Lim',
    riderPhone: '+63 926 301 7742',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    plateNumber: '9021-ND',
    vehicleModel: 'Honda TMX 125 Alpha (Solo Taxicle)',
    pickup: 'Pagadian Integrated Bus Terminal',
    dropoff: 'Zamboanga del Sur Medical Center, Dao',
    fare: 85.0,
    distanceKm: 5.6,
    duration: '19 mins',
    paymentMethod: 'Cash',
    status: 'Completed',
    timestamp: '42 mins ago',
  },
  {
    id: 'TRP-7016-8918',
    rider: 'Mark Anthony Reyes',
    riderPhone: '+63 945 204 8810',
    driver: 'Unassigned',
    driverPhone: '—',
    plateNumber: 'Pending',
    vehicleModel: 'Solo Taxicle',
    pickup: 'Santiago District, Pagadian City',
    dropoff: 'Provincial Capitol Complex, Balangasan',
    fare: 50.0,
    distanceKm: 2.9,
    duration: '—',
    paymentMethod: 'Cash',
    status: 'Dispatching',
    timestamp: '2 mins ago',
  },
  {
    id: 'TRP-7016-8917',
    rider: 'Kristine Joy Navarro',
    riderPhone: '+63 998 411 6620',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    plateNumber: '3391-ND',
    vehicleModel: 'Bajaj Maxima Z (Solo Taxicle)',
    pickup: 'Brgy. Santa Lucia, Pagadian City',
    dropoff: 'Pagadian City Rotunda',
    fare: 45.0,
    distanceKm: 2.4,
    duration: '—',
    paymentMethod: 'Cash',
    status: 'Cancelled',
    timestamp: '2 hours ago',
  },
])

const filteredTrips = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return trips.value.filter((trip) => {
    if (filterStatus.value !== 'all' && trip.status !== filterStatus.value) {
      return false
    }
    if (!q) return true
    return (
      trip.id.toLowerCase().includes(q) ||
      trip.rider.toLowerCase().includes(q) ||
      trip.driver.toLowerCase().includes(q) ||
      trip.pickup.toLowerCase().includes(q) ||
      trip.dropoff.toLowerCase().includes(q) ||
      trip.plateNumber.toLowerCase().includes(q)
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

const statusTone = (status: TripStatus) => {
  if (status === 'Completed') return 'success'
  if (status === 'In Progress') return 'info'
  if (status === 'Dispatching') return 'warning'
  return 'danger'
}

const handleExport = () => {
  const ok = exportToCsv(
    'easyride-pagadian-trips.csv',
    ['Trip ID', 'Passenger', 'Driver', 'Plate', 'Pickup', 'Dropoff', 'Agreed Fare', 'Status'],
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
  toastMessage.value = ok ? 'Trip history exported to CSV.' : 'No matching trips to export.'
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Trip Registry &amp; History
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Complete log of Pagadian Solo Taxicle rides, bidding fares, routes, and cash settlement
          statuses.
        </p>
      </div>
      <button
        type="button"
        @click="handleExport"
        class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 hover:bg-neutral-50 transition-colors cursor-pointer"
      >
        <Icon icon="lucide:download" class="w-4 h-4" />
        <span>Export CSV</span>
      </button>
    </div>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-white rounded-lg p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Completed Sample</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ trips.filter((t) => t.status === 'Completed').length }}
        </div>
      </div>
      <div class="bg-white rounded-lg p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Active / Dispatching</span>
        <div class="text-xl font-bold tabular-nums text-emerald-600 mt-1">
          {{ trips.filter((t) => t.status === 'In Progress' || t.status === 'Dispatching').length }}
        </div>
      </div>
      <div class="bg-white rounded-lg p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Avg Agreed Fare</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatPhp(averageFare) }}
        </div>
      </div>
      <div class="bg-white rounded-lg p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Platform Completion</span>
        <div class="text-xl font-bold tabular-nums text-blue-600 mt-1">96.4%</div>
      </div>
    </div>

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="relative w-full sm:w-72">
          <Icon
            icon="lucide:search"
            class="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400 text-sm"
          />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search trip ID, rider, driver, barangay..."
            class="w-full pl-9 pr-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
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
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Trip ID</th>
              <th class="py-3 px-4">Passenger</th>
              <th class="py-3 px-4">Driver &amp; Unit</th>
              <th class="py-3 px-4">Pagadian Route</th>
              <th class="py-3 px-4">Agreed Fare</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Details</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="trip in paginatedTrips"
              :key="trip.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ trip.id }}</td>
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
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ formatPhp(trip.fare) }}</div>
                <div class="text-xs text-neutral-400">{{ trip.paymentMethod }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="trip.status" :tone="statusTone(trip.status)" />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  @click="selectedTrip = trip"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                >
                  View Route
                </button>
              </td>
            </tr>
            <tr v-if="paginatedTrips.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No trip records match the active filter criteria.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredTrips.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="selectedTrip"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="selectedTrip = null"
      >
        <div
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-lg p-6 space-y-4"
        >
          <div class="flex items-start justify-between border-b border-neutral-100 pb-3">
            <div>
              <span class="font-mono text-[11px] text-neutral-400">{{
                selectedTrip.timestamp
              }}</span>
              <h3 class="text-base font-bold text-neutral-900">
                Trip Route &amp; Fare Summary · {{ selectedTrip.id }}
              </h3>
            </div>
            <button
              type="button"
              aria-label="Close modal"
              @click="selectedTrip = null"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-3 text-xs">
            <div class="p-3 bg-neutral-50 border border-neutral-200 rounded-md space-y-2">
              <div class="flex items-start space-x-2">
                <span class="w-2 h-2 rounded-full bg-emerald-500 mt-1 shrink-0" />
                <div>
                  <div class="text-[11px] text-neutral-500">Pickup Barangay</div>
                  <div class="font-semibold text-neutral-900">{{ selectedTrip.pickup }}</div>
                </div>
              </div>
              <div class="flex items-start space-x-2">
                <span class="w-2 h-2 rounded-full bg-neutral-900 mt-1 shrink-0" />
                <div>
                  <div class="text-[11px] text-neutral-500">Dropoff Destination</div>
                  <div class="font-semibold text-neutral-900">{{ selectedTrip.dropoff }}</div>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <div class="text-neutral-500">Passenger</div>
                <div class="font-semibold text-neutral-900">{{ selectedTrip.rider }}</div>
                <div class="font-mono text-neutral-500">{{ selectedTrip.riderPhone }}</div>
              </div>
              <div>
                <div class="text-neutral-500">Assigned Driver</div>
                <div class="font-semibold text-neutral-900">{{ selectedTrip.driver }}</div>
                <div class="font-mono text-neutral-500">
                  {{ selectedTrip.plateNumber }} · {{ selectedTrip.driverPhone }}
                </div>
              </div>
              <div>
                <div class="text-neutral-500">Distance / Duration</div>
                <div class="font-mono font-semibold text-neutral-900">
                  {{ selectedTrip.distanceKm }} km · {{ selectedTrip.duration }}
                </div>
              </div>
              <div>
                <div class="text-neutral-500">Agreed Fare (15% Commission)</div>
                <div class="font-mono font-bold text-neutral-900">
                  {{ formatPhp(selectedTrip.fare) }} ({{ selectedTrip.paymentMethod }})
                </div>
              </div>
            </div>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <RouterLink
              to="/payments/settlements"
              @click="selectedTrip = null"
              class="px-3.5 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 rounded-md text-xs font-semibold"
            >
              Inspect Cash Settlements
            </RouterLink>
            <button
              type="button"
              @click="selectedTrip = null"
              class="px-4 py-2 bg-neutral-900 text-white rounded-md text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
