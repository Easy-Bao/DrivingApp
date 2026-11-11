<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const searchQuery = ref('')
const filterStatus = ref('all')

const mockTrips = ref([
  {
    id: 'TRP-1092',
    rider: 'Alexander Wright',
    riderPhone: '+1 (555) 301-4491',
    driver: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    tier: 'Comfort',
    pickup: 'Terminal 1 Arrivals, Airport',
    dropoff: 'Grand Hyatt Hotel, Downtown',
    fare: '₱42.50',
    distance: '18.4 km',
    duration: '28 mins',
    paymentMethod: 'In-App Card',
    status: 'Completed',
    timestamp: '14 mins ago',
  },
  {
    id: 'TRP-1091',
    rider: 'Jessica Patel',
    riderPhone: '+1 (555) 482-1920',
    driver: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    tier: 'Economy',
    pickup: '7th Avenue Shopping Center',
    dropoff: 'Oakridge Residential Area',
    fare: '₱16.20',
    distance: '6.2 km',
    duration: '14 mins',
    paymentMethod: 'Cash',
    status: 'In Progress',
    timestamp: '22 mins ago',
  },
  {
    id: 'TRP-1090',
    rider: 'Carlos Mendez',
    riderPhone: '+1 (555) 918-2831',
    driver: 'David Kim',
    driverPhone: '+1 (555) 345-6789',
    tier: 'XL Family',
    pickup: 'Convention Center Gate 4',
    dropoff: 'Metro Station North',
    fare: '₱28.00',
    distance: '11.8 km',
    duration: '21 mins',
    paymentMethod: 'In-App Card',
    status: 'Completed',
    timestamp: '1 hour ago',
  },
  {
    id: 'TRP-1089',
    rider: 'Sarah Jenkins',
    riderPhone: '+1 (555) 671-8291',
    driver: 'Unassigned',
    driverPhone: '—',
    tier: 'Comfort',
    pickup: 'Financial Plaza Tower B',
    dropoff: 'Suburban Heights',
    fare: '₱31.50',
    distance: '14.1 km',
    duration: '—',
    paymentMethod: 'In-App Card',
    status: 'Cancelled',
    timestamp: '2 hours ago',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Trip Registry & History</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Complete log of platform rides, route GPS trails, fares, and real-time operational
          statuses.
        </p>
      </div>
    </div>

    <!-- Quick Metrics -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Today's Completed Trips</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">3,491</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Active Rides Now</span>
        <div class="text-xl font-bold tabular-nums text-emerald-600 mt-1">142</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Avg Trip Fare</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">₱22.80</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Completion Rate</span>
        <div class="text-xl font-bold tabular-nums text-blue-600 mt-1">96.4%</div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="relative w-full sm:w-72">
          <Icon icon="lucide:search" class="absolute left-3 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search trip ID, rider, driver, route..."
            class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
          />
        </div>
        <div class="flex items-center space-x-2">
          <select
            v-model="filterStatus"
            class="px-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs text-neutral-700"
          >
            <option value="all">All Statuses</option>
            <option value="Completed">Completed</option>
            <option value="In Progress">In Progress</option>
            <option value="Cancelled">Cancelled</option>
          </select>
        </div>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Trip ID</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Route</th>
            <th class="py-3 px-4">Fare</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Details</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="trip in mockTrips"
            :key="trip.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ trip.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ trip.rider }}</div>
              <div class="text-[11px] text-neutral-400">{{ trip.riderPhone }}</div>
            </td>
            <td class="py-3 px-4">
              <div class="font-medium text-neutral-800">{{ trip.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ trip.tier }}</div>
            </td>
            <td class="py-3 px-4 max-w-xs truncate">
              <div class="truncate text-neutral-800 font-medium">{{ trip.pickup }}</div>
              <div class="truncate text-[11px] text-neutral-400">→ {{ trip.dropoff }}</div>
            </td>
            <td class="py-3 px-4">
              <div class="font-bold text-neutral-900">{{ trip.fare }}</div>
              <div class="text-xs text-neutral-400">{{ trip.paymentMethod }}</div>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  trip.status === 'Completed'
                    ? 'bg-emerald-100 text-emerald-800'
                    : trip.status === 'In Progress'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-rose-100 text-rose-800'
                "
              >
                {{ trip.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
              >
                View Route
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
