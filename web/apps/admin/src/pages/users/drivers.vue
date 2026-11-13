<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import TablePagination from '@/shared/components/TablePagination.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
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
    vehicle: 'Kawasaki Barako II (Plate: 4912-NC)',
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
    vehicle: 'Honda TMX 125 Alpha (Plate: 9021-ND)',
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
    vehicle: 'Bajaj RE Maxima (Plate: 5519-NB)',
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
    vehicle: 'Kawasaki Barako II (Plate: 8821-NC)',
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
    vehicle: 'Kawasaki Barako II (Plate: 1109-ND)',
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
    vehicle: 'Honda TMX 125 Alpha (Plate: 3310-NC)',
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
    vehicle: 'TVS King Deluxe (Plate: 4481-ND)',
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
  const q = searchQuery.value.trim().toLowerCase()
  return drivers.value.filter((d) => {
    if (statusFilter.value !== 'ALL' && d.status !== statusFilter.value) {
      return false
    }
    if (!q) return true
    return (
      d.id.toLowerCase().includes(q) ||
      d.name.toLowerCase().includes(q) ||
      d.phone.toLowerCase().includes(q) ||
      d.vehicle.toLowerCase().includes(q) ||
      d.city.toLowerCase().includes(q)
    )
  })
})

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
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Drivers</h1>
        <p class="text-sm text-neutral-500 mt-1">Fleet units, TODA corridors, and wallets.</p>
      </div>
    </div>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="relative w-full sm:w-72">
            <Icon
              icon="lucide:search"
              class="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400 text-sm"
            />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search name, phone, plate..."
              class="w-full pl-9 pr-3 py-1.5 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
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
            Applications
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
              <th class="py-3 px-4">Vehicle</th>
              <th class="py-3 px-4">Trips</th>
              <th class="py-3 px-4">Rating</th>
              <th class="py-3 px-4">Wallet</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr
              v-for="d in paginatedDrivers"
              :key="d.id"
              class="hover:bg-neutral-50/50 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ d.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ d.id }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-600">{{ d.phone }}</td>
              <td class="py-3 px-4">{{ d.city }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ d.vehicle }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ d.trips }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900 tabular-nums">
                ★ {{ d.rating.toFixed(2) }}
              </td>
              <td
                class="py-3 px-4 font-mono font-medium tabular-nums"
                :class="d.walletBalance < 50 ? 'text-rose-700 font-bold' : 'text-neutral-800'"
              >
                {{ formatPhp(d.walletBalance) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="d.status" :tone="driverTone(d.status)" />
              </td>
              <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                  @click="inspectedDriver = d"
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
                  @click="openStatusDialog(d)"
                >
                  {{ d.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
              </td>
            </tr>
            <tr v-if="paginatedDrivers.length === 0">
              <td colspan="9" class="py-8 text-center text-xs text-neutral-500">
                No drivers match filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredDrivers.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="inspectedDriver"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="inspectedDriver = null"
      >
        <div class="bg-white border border-neutral-200 shadow-2xl w-full max-w-lg p-6 space-y-4">
          <div class="flex items-start justify-between border-b border-neutral-100 pb-3">
            <div>
              <span class="font-mono text-[11px] text-neutral-400">{{ inspectedDriver.id }}</span>
              <h3 class="text-base font-bold text-neutral-900">{{ inspectedDriver.name }}</h3>
            </div>
            <button
              type="button"
              aria-label="Close modal"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
              @click="inspectedDriver = null"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="grid grid-cols-2 gap-3 text-xs">
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
            <div class="col-span-2">
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

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <RouterLink
              to="/payments/topups"
              class="px-4 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 text-xs font-semibold transition-colors"
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
          </div>
        </div>
      </div>
    </Teleport>

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
