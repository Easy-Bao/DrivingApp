<script setup lang="ts">
import { ref } from 'vue'

const activeZones = ref([
  {
    name: 'Downtown Central',
    activeDrivers: 48,
    pendingRequests: 12,
    avgWait: '2.4 mins',
    surge: '1.4x',
  },
  {
    name: 'Airport Express Corridor',
    activeDrivers: 34,
    pendingRequests: 8,
    avgWait: '3.1 mins',
    surge: '1.2x',
  },
  {
    name: 'West Valley University',
    activeDrivers: 22,
    pendingRequests: 4,
    avgWait: '4.2 mins',
    surge: '1.0x',
  },
  {
    name: 'North Residential Hills',
    activeDrivers: 15,
    pendingRequests: 2,
    avgWait: '5.8 mins',
    surge: '1.0x',
  },
])

const liveDispatches = ref([
  {
    id: 'DSP-881',
    rider: 'Jessica Patel',
    driver: 'Elena Rostova',
    eta: '3 mins',
    status: 'En Route to Pickup',
    zone: 'Downtown Central',
  },
  {
    id: 'DSP-882',
    rider: 'David Ross',
    driver: 'Marcus Miller',
    eta: '1 min',
    status: 'Arrived at Pickup',
    zone: 'Airport Express Corridor',
  },
  {
    id: 'DSP-883',
    rider: 'Carlos Mendez',
    driver: 'David Kim',
    eta: '5 mins',
    status: 'Matching Vehicle',
    zone: 'West Valley University',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Real-Time Dispatch Radar</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Monitor live vehicle telemetry, fleet coverage density, and algorithm matching efficiency.
        </p>
      </div>
    </div>

    <!-- Active Zone Health -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="zone in activeZones"
        :key="zone.name"
        class="bg-white p-4 border border-neutral-200 space-y-2"
      >
        <div class="flex items-center justify-between">
          <span class="font-bold text-xs text-neutral-900 truncate">{{ zone.name }}</span>
          <span
            class="px-2 py-0.5 text-[10px] font-bold"
            :class="
              zone.surge !== '1.0x'
                ? 'bg-amber-100 text-amber-800'
                : 'bg-neutral-100 text-neutral-600'
            "
          >
            {{ zone.surge }}
          </span>
        </div>
        <div class="grid grid-cols-3 gap-1 pt-1 border-t border-neutral-100 text-center">
          <div>
            <div class="text-xs text-neutral-400">Drivers</div>
            <div class="text-xs font-bold text-neutral-900">{{ zone.activeDrivers }}</div>
          </div>
          <div>
            <div class="text-xs text-neutral-400">Waiting</div>
            <div class="text-xs font-bold text-neutral-900">{{ zone.pendingRequests }}</div>
          </div>
          <div>
            <div class="text-xs text-neutral-400">ETA</div>
            <div class="text-xs font-bold text-neutral-900">{{ zone.avgWait }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Live Active Dispatches -->
    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <h2 class="font-bold text-sm text-neutral-900">Active Real-Time Dispatches</h2>
        </div>
        <span class="text-xs text-neutral-400">Updated every 3 seconds</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Dispatch ID</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Matched Driver</th>
            <th class="py-3 px-4">Zone</th>
            <th class="py-3 px-4">Pickup ETA</th>
            <th class="py-3 px-4 text-right">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="d in liveDispatches"
            :key="d.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ d.id }}</td>
            <td class="py-3 px-4 font-medium text-neutral-900">{{ d.rider }}</td>
            <td class="py-3 px-4 text-neutral-800">{{ d.driver }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ d.zone }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ d.eta }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800"
              >
                {{ d.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
