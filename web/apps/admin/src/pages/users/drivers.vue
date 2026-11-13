<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

type DriverStatus = 'Active' | 'Low Balance (Locked)' | 'Suspended'

interface DriverRecord {
  id: string
  name: string
  phone: string
  city: string
  vehicle: string
  todaZone: string
  trips: number
  rating: number
  walletBalance: number
  status: DriverStatus
  suspensionReason?: string
}

const searchQuery = ref('')
const statusFilter = ref<'ALL' | DriverStatus>('ALL')
const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'info'>('success')

const drivers = ref<DriverRecord[]>([
  {
    id: 'DRV-101',
    name: 'Rodelio Cruz',
    phone: '+63 917 440 2184',
    city: 'Brgy. San Jose',
    vehicle: 'Bajaj RE 4S (Plate: 1284-ND)',
    todaZone: 'San Jose - Agora Corridor',
    trips: 1420,
    rating: 4.92,
    walletBalance: 420.5,
    status: 'Active',
  },
  {
    id: 'DRV-102',
    name: 'Danilo Mendoza',
    phone: '+63 928 412 8890',
    city: 'Brgy. Tuburan',
    vehicle: 'TVS King Deluxe (Plate: 4912-NC)',
    todaZone: 'Tuburan - Integrated Terminal',
    trips: 890,
    rating: 4.88,
    walletBalance: 185.0,
    status: 'Active',
  },
  {
    id: 'DRV-103',
    name: 'Reynaldo Garcia',
    phone: '+63 908 771 9923',
    city: 'Brgy. Balangasan',
    vehicle: 'Bajaj Maxima Z (Plate: 9021-ND)',
    todaZone: 'Balangasan - Capitol Complex',
    trips: 2150,
    rating: 4.95,
    walletBalance: 880.0,
    status: 'Active',
  },
  {
    id: 'DRV-104',
    name: 'Javier Santos',
    phone: '+63 917 987 6543',
    city: 'Brgy. San Pedro',
    vehicle: 'Bajaj RE FI (Plate: 5519-NB)',
    todaZone: 'San Pedro - Pier Port',
    trips: 430,
    rating: 4.65,
    walletBalance: 15.5,
    status: 'Low Balance (Locked)',
  },
  {
    id: 'DRV-105',
    name: 'Eduardo Santos',
    phone: '+63 919 332 4455',
    city: 'Brgy. Kawit',
    vehicle: 'TVS King Deluxe FI (Plate: 7712-NC)',
    todaZone: 'Kawit - Rotunda Hub',
    trips: 1240,
    rating: 4.91,
    walletBalance: 650.0,
    status: 'Active',
  },
  {
    id: 'DRV-106',
    name: 'Maria Lourdes Ramos',
    phone: '+63 920 882 1144',
    city: 'Brgy. Santa Lucia',
    vehicle: 'Bajaj Maxima Z (Plate: 3391-ND)',
    todaZone: 'Santa Lucia - Commercial Core',
    trips: 780,
    rating: 4.97,
    walletBalance: 1105.5,
    status: 'Active',
  },
  {
    id: 'DRV-107',
    name: 'Jose Mari Bautista',
    phone: '+63 918 665 4411',
    city: 'Brgy. Gatas',
    vehicle: 'Piaggio Ape City (Plate: 8821-NC)',
    todaZone: 'Gatas - Robinson Mall Loop',
    trips: 1690,
    rating: 4.89,
    walletBalance: 520.0,
    status: 'Active',
  },
  {
    id: 'DRV-108',
    name: 'Felipe Cruz',
    phone: '+63 916 445 8821',
    city: 'Brgy. Tiguma',
    vehicle: 'Bajaj RE 4S (Plate: 6620-NC)',
    todaZone: 'Tiguma - Pagadian Airport',
    trips: 940,
    rating: 4.84,
    walletBalance: 340.0,
    status: 'Active',
  },
  {
    id: 'DRV-109',
    name: 'Antonio Villanueva',
    phone: '+63 939 556 1209',
    city: 'Brgy. Dao',
    vehicle: 'NWOW ERV2 Electric (Plate: 1109-ND)',
    todaZone: 'Dao - Provincial Hospital',
    trips: 1120,
    rating: 4.93,
    walletBalance: 785.0,
    status: 'Active',
  },
  {
    id: 'DRV-110',
    name: 'Cristopher Alcantara',
    phone: '+63 921 778 2234',
    city: 'Brgy. Santiago',
    vehicle: 'Bajaj RE 4S FI (Plate: 9920-ND)',
    todaZone: 'Santiago - Coastal Highway',
    trips: 610,
    rating: 4.79,
    walletBalance: 180.0,
    status: 'Active',
  },
  {
    id: 'DRV-111',
    name: 'Nestor Macaraeg',
    phone: '+63 947 889 1120',
    city: 'Brgy. Danlugan',
    vehicle: 'Piaggio Ape City (Plate: 3310-NC)',
    todaZone: 'Danlugan - Highway West',
    trips: 1350,
    rating: 4.9,
    walletBalance: 460.0,
    status: 'Active',
  },
  {
    id: 'DRV-112',
    name: 'Ernesto Manalo',
    phone: '+63 915 221 8890',
    city: 'Brgy. Bulatok',
    vehicle: 'TVS King Duramax (Plate: 4481-ND)',
    todaZone: 'Bulatok - Mercado North',
    trips: 820,
    rating: 4.86,
    walletBalance: 295.0,
    status: 'Active',
  },
])

const inspectedDriver = ref<DriverRecord | null>(null)
const pendingStatusTarget = ref<DriverRecord | null>(null)
const suspendReason = ref('')

const filteredDrivers = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return drivers.value.filter((driver) => {
    if (statusFilter.value !== 'ALL' && driver.status !== statusFilter.value) {
      return false
    }
    if (!query) return true
    return (
      driver.id.toLowerCase().includes(query) ||
      driver.name.toLowerCase().includes(query) ||
      driver.phone.toLowerCase().includes(query) ||
      driver.vehicle.toLowerCase().includes(query) ||
      driver.city.toLowerCase().includes(query)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || statusFilter.value !== 'ALL'),
)

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
}

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

const currentPage = ref(1)
const itemsPerPage = 10

const paginatedDrivers = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredDrivers.value.slice(start, start + itemsPerPage)
})

const driverTone = (status: DriverStatus) => {
  if (status === 'Active') return 'success'
  if (status === 'Low Balance (Locked)') return 'warning'
  return 'danger'
}

const openStatusDialog = (driver: DriverRecord) => {
  suspendReason.value = ''
  pendingStatusTarget.value = driver
}

const confirmStatusChange = () => {
  const target = pendingStatusTarget.value
  if (!target) return

  if (target.status === 'Suspended') {
    target.status = target.walletBalance < 50 ? 'Low Balance (Locked)' : 'Active'
    target.suspensionReason = undefined
    toastTone.value = 'success'
    toastMessage.value = `${target.name} restored to ${target.status}.`
  } else {
    if (!suspendReason.value.trim()) return
    target.status = 'Suspended'
    target.suspensionReason = suspendReason.value.trim()
    toastTone.value = 'warning'
    toastMessage.value = `${target.name} suspended from dispatch queues.`
  }

  pendingStatusTarget.value = null
  suspendReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Drivers"
      description="Manage active drivers, assigned vehicles, and account statuses."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-72">
            <SearchField
              v-model="searchQuery"
              placeholder="Search name, phone, plate..."
              aria-label="Search drivers"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter drivers by status"
            :options="[
              { label: 'All', value: 'ALL' },
              { label: 'Active', value: 'Active' },
              { label: 'Low Balance (Locked)', value: 'Low Balance (Locked)' },
              { label: 'Suspended', value: 'Suspended' },
            ]"
          />
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span
            class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums"
          >
            Drivers: {{ filteredDrivers.length }}
          </span>
          <RouterLink
            to="/users/driver-applications"
            class="px-3.5 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors"
          >
            Driver Applications
          </RouterLink>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[920px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Phone</th>
              <th class="py-3 px-4">Area</th>
              <th class="py-3 px-4">Vehicle Unit</th>
              <th class="py-3 px-4">Trips</th>
              <th class="py-3 px-4">Rating</th>
              <th class="py-3 px-4">Wallet</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr
              v-for="driver in paginatedDrivers"
              :key="driver.id"
              class="hover:bg-neutral-50/50 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ driver.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ driver.id }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-600">{{ driver.phone }}</td>
              <td class="py-3 px-4">{{ driver.city }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ driver.vehicle }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ driver.trips }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900 tabular-nums">
                ★ {{ driver.rating.toFixed(2) }}
              </td>
              <td
                class="py-3 px-4 font-mono font-medium tabular-nums"
                :class="driver.walletBalance < 50 ? 'text-rose-700 font-bold' : 'text-neutral-800'"
              >
                {{ formatPhp(driver.walletBalance) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="driver.status" :tone="driverTone(driver.status)" />
              </td>
              <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                  @click="inspectedDriver = driver"
                >
                  Inspect
                </button>
                <RouterLink
                  to="/payments/topups"
                  class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
                >
                  Top Up
                </RouterLink>
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-medium cursor-pointer"
                  @click="openStatusDialog(driver)"
                >
                  {{ driver.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedDrivers.length === 0"
              :colspan="9"
              title="No drivers match your filters"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredDrivers.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedDriver)"
      :title="inspectedDriver?.name ?? ''"
      :subtitle="inspectedDriver?.id"
      size="lg"
      close-label="Close modal"
      @close="inspectedDriver = null"
    >
      <div v-if="inspectedDriver" class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
          <div>
            <div class="text-neutral-500">Phone</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ inspectedDriver.phone }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Area</div>
            <div class="font-medium text-neutral-900 mt-0.5">{{ inspectedDriver.city }}</div>
          </div>
          <div class="sm:col-span-2">
            <div class="text-neutral-500">Vehicle &amp; Corridor</div>
            <div class="font-medium text-neutral-900 mt-0.5">
              {{ inspectedDriver.vehicle }} · {{ inspectedDriver.todaZone }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Wallet</div>
            <div
              class="font-mono font-bold mt-0.5"
              :class="inspectedDriver.walletBalance < 50 ? 'text-rose-700' : 'text-neutral-900'"
            >
              {{ formatPhp(inspectedDriver.walletBalance) }}
              <span v-if="inspectedDriver.walletBalance < 50" class="text-[11px] font-sans">
                (&lt; ₱50)
              </span>
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Trips &amp; Rating</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ inspectedDriver.trips }} · ★ {{ inspectedDriver.rating.toFixed(2) }}
            </div>
          </div>
        </div>

        <div
          v-if="inspectedDriver.suspensionReason"
          class="p-3 bg-neutral-50 border border-neutral-300 text-xs text-neutral-800"
        >
          <span class="font-semibold">Suspension Note:</span>
          {{ inspectedDriver.suspensionReason }}
        </div>
      </div>

      <template #footer>
        <RouterLink
          to="/payments/topups"
          class="px-4 py-2 bg-white border border-neutral-200 hover:bg-neutral-100 text-neutral-800 text-xs font-semibold transition-colors"
          @click="inspectedDriver = null"
        >
          Top-Ups
        </RouterLink>
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="inspectedDriver = null"
        >
          Close
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      :open="Boolean(pendingStatusTarget)"
      v-model:reason="suspendReason"
      :title="pendingStatusTarget?.status === 'Suspended' ? 'Reactivate Driver' : 'Suspend Driver'"
      :description="
        pendingStatusTarget?.status === 'Suspended'
          ? `Restore ${pendingStatusTarget?.name} to dispatch queues.`
          : `Suspend ${pendingStatusTarget?.name} from bidding and trip assignments.`
      "
      :confirm-label="pendingStatusTarget?.status === 'Suspended' ? 'Reactivate' : 'Suspend Driver'"
      tone="neutral"
      :require-reason="pendingStatusTarget?.status !== 'Suspended'"
      reason-label="Reason"
      reason-placeholder="Enter compliance or safety reason..."
      @cancel="pendingStatusTarget = null"
      @confirm="confirmStatusChange"
    />
  </div>
</template>
