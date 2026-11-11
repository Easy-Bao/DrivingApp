<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'

const searchQuery = ref('')
const mockDrivers = ref([
  {
    id: 'DRV-101',
    name: 'Marcus Miller',
    phone: '+63 917 234 5678',
    city: 'Quezon City',
    vehicle: 'Bajaj RE 4S (Plate: 1284-ND)',
    trips: 1420,
    rating: 4.92,
    walletBalance: 42.5,
    status: 'Active',
  },
  {
    id: 'DRV-102',
    name: 'Danilo Mendoza',
    phone: '+63 928 412 8890',
    city: 'Pasig City',
    vehicle: 'Kawasaki Barako II (Plate: 4912-NC)',
    trips: 890,
    rating: 4.88,
    walletBalance: 12.0,
    status: 'Active',
  },
  {
    id: 'DRV-103',
    name: 'Reynaldo Garcia',
    phone: '+63 908 771 9923',
    city: 'Manila City',
    vehicle: 'Honda TMX 125 Alpha (Plate: 9021-ND)',
    trips: 2150,
    rating: 4.95,
    walletBalance: 88.0,
    status: 'Active',
  },
  {
    id: 'DRV-104',
    name: 'Javier Santos',
    phone: '+63 917 987 6543',
    city: 'Caloocan City',
    vehicle: 'Bajaj RE Maxima (Plate: 5519-NB)',
    trips: 430,
    rating: 4.65,
    walletBalance: 1.5,
    status: 'Low Balance (Locked)',
  },
  {
    id: 'DRV-105',
    name: 'Eduardo Santos',
    phone: '+63 919 332 4455',
    city: 'Taguig City',
    vehicle: 'TVS King Deluxe FI (Plate: 7712-NC)',
    trips: 1240,
    rating: 4.91,
    walletBalance: 65.0,
    status: 'Active',
  },
  {
    id: 'DRV-106',
    name: 'Maria Lourdes Ramos',
    phone: '+63 920 882 1144',
    city: 'Cebu City',
    vehicle: 'Bajaj Maxima Z (Plate: 3391-ND)',
    trips: 780,
    rating: 4.97,
    walletBalance: 110.5,
    status: 'Active',
  },
  {
    id: 'DRV-107',
    name: 'Jose Mari Bautista',
    phone: '+63 918 665 4411',
    city: 'Davao City',
    vehicle: 'Kawasaki Barako II (Plate: 8821-NC)',
    trips: 1690,
    rating: 4.89,
    walletBalance: 52.0,
    status: 'Active',
  },
  {
    id: 'DRV-108',
    name: 'Felipe Cruz',
    phone: '+63 916 445 8821',
    city: 'Pasay City',
    vehicle: 'Bajaj RE 4S (Plate: 6620-NC)',
    trips: 940,
    rating: 4.84,
    walletBalance: 34.0,
    status: 'Active',
  },
  {
    id: 'DRV-109',
    name: 'Antonio Villanueva',
    phone: '+63 939 556 1209',
    city: 'Mandaluyong City',
    vehicle: 'Kawasaki Barako II (Plate: 1109-ND)',
    trips: 1120,
    rating: 4.93,
    walletBalance: 78.5,
    status: 'Active',
  },
  {
    id: 'DRV-110',
    name: 'Cristopher Alcantara',
    phone: '+63 921 778 2234',
    city: 'Marikina City',
    vehicle: 'Bajaj RE 4S FI (Plate: 9920-ND)',
    trips: 610,
    rating: 4.79,
    walletBalance: 18.0,
    status: 'Active',
  },
  {
    id: 'DRV-111',
    name: 'Nestor Macaraeg',
    phone: '+63 947 889 1120',
    city: 'Valenzuela City',
    vehicle: 'Honda TMX 125 Alpha (Plate: 3310-NC)',
    trips: 1350,
    rating: 4.9,
    walletBalance: 46.0,
    status: 'Active',
  },
  {
    id: 'DRV-112',
    name: 'Rodelio Manalo',
    phone: '+63 915 221 8890',
    city: 'Las Pinas City',
    vehicle: 'TVS King Deluxe (Plate: 4481-ND)',
    trips: 820,
    rating: 4.86,
    walletBalance: 29.5,
    status: 'Active',
  },
])

const filteredDrivers = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return mockDrivers.value
  return mockDrivers.value.filter(
    (d) =>
      d.name.toLowerCase().includes(q) ||
      d.phone.toLowerCase().includes(q) ||
      d.vehicle.toLowerCase().includes(q) ||
      d.city.toLowerCase().includes(q),
  )
})

const currentPage = ref(1)
const itemsPerPage = 10

const paginatedDrivers = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredDrivers.value.slice(start, start + itemsPerPage)
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Active Driver Roster</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Monitor Philippine taxicle fleet, driver ratings, and wallet dispatch statuses.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <RouterLink
          to="/users/driver-applications"
          class="px-3.5 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors"
        >
          View Pending Applications →
        </RouterLink>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div class="relative w-full sm:w-72">
          <Icon icon="lucide:search" class="absolute left-3 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search driver by name, phone, plate..."
            class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs"
            @input="currentPage = 1"
          />
        </div>
        <span class="text-xs text-neutral-500 tabular-nums">
          Showing {{ filteredDrivers.length }} registered drivers
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Contact (PH)</th>
              <th class="py-3 px-4">Operating City</th>
              <th class="py-3 px-4">Taxicle Unit & Plate</th>
              <th class="py-3 px-4">Trips Completed</th>
              <th class="py-3 px-4">Rating</th>
              <th class="py-3 px-4">Prepaid Wallet</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="d in paginatedDrivers" :key="d.id" class="hover:bg-neutral-50/50 transition-colors">
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ d.name }}</td>
              <td class="py-3 px-4 font-mono text-neutral-600">{{ d.phone }}</td>
              <td class="py-3 px-4">{{ d.city }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ d.vehicle }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ d.trips }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900 tabular-nums">★ {{ d.rating }}</td>
              <td
                class="py-3 px-4 font-mono font-medium tabular-nums"
                :class="d.walletBalance < 5 ? 'text-rose-600 font-bold' : 'text-neutral-800'"
              >
                ₱{{ d.walletBalance.toFixed(2) }}
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                  :class="
                    d.status === 'Active'
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-rose-100 text-rose-800'
                  "
                >
                  {{ d.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
                <RouterLink
                  to="/payments/topups"
                  class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
                >
                  Top Up
                </RouterLink>
                <button
                  type="button"
                  class="text-xs text-neutral-400 hover:text-rose-600 font-medium cursor-pointer"
                >
                  Suspend
                </button>
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
  </div>
</template>
