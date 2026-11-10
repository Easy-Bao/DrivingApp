<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const bookings = ref([
  {
    id: 'SCH-701',
    rider: 'Dr. Evelyn Reed',
    riderPhone: '+1 (555) 721-0029',
    pickupTime: 'Today, 16:30',
    pickupLocation: 'St. Jude Medical Pavilion, Suite 400',
    destination: 'International Airport Terminal 3',
    tier: 'Executive Black',
    assignedDriver: 'Anthony Stark',
    driverStatus: 'Confirmed & En Route',
    estFare: '$68.00',
  },
  {
    id: 'SCH-702',
    rider: 'Samuel Vance',
    riderPhone: '+1 (555) 881-2244',
    pickupTime: 'Tomorrow, 06:00',
    pickupLocation: '45 Lakeview Drive, Suburban Estates',
    destination: 'Union Central Train Depot',
    tier: 'Comfort',
    assignedDriver: 'Marcus Miller',
    driverStatus: 'Dispatched',
    estFare: '$38.50',
  },
  {
    id: 'SCH-703',
    rider: 'Chloe Bennett',
    riderPhone: '+1 (555) 332-9911',
    pickupTime: 'Tomorrow, 09:15',
    pickupLocation: 'The Grand Hotel, Lobby',
    destination: 'Convention Center West Entrance',
    tier: 'XL Family',
    assignedDriver: 'Pending Auto-Dispatch',
    driverStatus: 'Queued (Auto-assigns 45m before)',
    estFare: '$45.00',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Scheduled & Advance Bookings
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage advance airport reservations, automated dispatch assignments, and driver
          confirmations.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 rounded-lg bg-blue-50 border border-blue-200 text-xs font-semibold text-blue-800"
        >
          3 Upcoming Bookings
        </span>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Upcoming Advance Reservations</h2>
        <span class="text-xs text-neutral-400"
          >Driver dispatched automatically 45 mins prior to pickup</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Booking ID</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Pickup Time</th>
            <th class="py-3 px-4">Route Details</th>
            <th class="py-3 px-4">Service Tier</th>
            <th class="py-3 px-4">Assigned Chauffeur</th>
            <th class="py-3 px-4 text-right">Est. Fare</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="b in bookings" :key="b.id" class="hover:bg-neutral-50/70 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ b.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ b.rider }}</div>
              <div class="text-[11px] text-neutral-400">{{ b.riderPhone }}</div>
            </td>
            <td class="py-3 px-4 font-semibold text-neutral-900">
              <div class="flex items-center space-x-1.5">
                <Icon icon="lucide:clock" class="text-neutral-400" />
                <span>{{ b.pickupTime }}</span>
              </div>
            </td>
            <td class="py-3 px-4 max-w-xs">
              <div class="truncate text-neutral-800 font-medium">{{ b.pickupLocation }}</div>
              <div class="truncate text-[11px] text-neutral-400">→ {{ b.destination }}</div>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-neutral-100 text-neutral-800"
              >
                {{ b.tier }}
              </span>
            </td>
            <td class="py-3 px-4">
              <div class="font-medium text-neutral-900">{{ b.assignedDriver }}</div>
              <div class="text-[11px] text-emerald-600 font-medium">{{ b.driverStatus }}</div>
            </td>
            <td class="py-3 px-4 text-right font-bold text-neutral-900">
              {{ b.estFare }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
