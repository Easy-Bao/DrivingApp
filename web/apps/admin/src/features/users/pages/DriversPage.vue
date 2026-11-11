<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const searchQuery = ref('')
const mockDrivers = ref([
  {
    id: 'DRV-101',
    name: 'Marcus Miller',
    phone: '+1 (555) 234-5678',
    vehicle: 'Toyota Camry (2023)',
    trips: 1420,
    rating: 4.92,
    walletBalance: 42.5,
    status: 'Active',
  },
  {
    id: 'DRV-102',
    name: 'Elena Rostova',
    phone: '+1 (555) 876-5432',
    vehicle: 'Hyundai Ioniq 5',
    trips: 890,
    rating: 4.88,
    walletBalance: 12.0,
    status: 'Active',
  },
  {
    id: 'DRV-103',
    name: 'David Kim',
    phone: '+1 (555) 345-6789',
    vehicle: 'Honda Accord (2022)',
    trips: 2150,
    rating: 4.95,
    walletBalance: 88.0,
    status: 'Active',
  },
  {
    id: 'DRV-104',
    name: 'Javier Santos',
    phone: '+1 (555) 987-6543',
    vehicle: 'Nissan Sentra (2020)',
    trips: 430,
    rating: 4.65,
    walletBalance: 1.5,
    status: 'Low Balance (Locked)',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Active Driver Roster</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Monitor active driver fleet, performance ratings, and wallet dispatch statuses.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <RouterLink
          to="/users/driver-applications"
          class="px-3.5 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors"
        >
          View 8 Pending Applications →
        </RouterLink>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div class="relative w-72">
          <Icon icon="lucide:search" class="absolute left-3 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search driver by name, phone, plate..."
            class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs"
          />
        </div>
        <span class="text-xs text-neutral-500">Showing 4 active drivers</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
          <tr>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Contact</th>
            <th class="py-3 px-4">Assigned Vehicle</th>
            <th class="py-3 px-4">Trips Completed</th>
            <th class="py-3 px-4">Rating</th>
            <th class="py-3 px-4">Wallet Balance</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100 text-neutral-700">
          <tr v-for="d in mockDrivers" :key="d.id" class="hover:bg-neutral-50/50">
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ d.name }}</td>
            <td class="py-3 px-4">{{ d.phone }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ d.vehicle }}</td>
            <td class="py-3 px-4">{{ d.trips }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">★ {{ d.rating }}</td>
            <td
              class="py-3 px-4 font-mono font-medium"
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
            <td class="py-3 px-4 text-right space-x-2">
              <RouterLink
                :to="`/payment/driver-topups`"
                class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
                >Top Up</RouterLink
              >
              <button
                type="button"
                class="text-xs text-neutral-400 hover:text-rose-600 font-medium"
              >
                Suspend
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
