<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const operationalZones = ref([
  {
    id: 'ZN-1',
    name: 'Downtown Financial & Entertainment District',
    city: 'Metro Central',
    surgeFactor: '1.4x',
    polygonPoints: 48,
    activeDrivers: 54,
    status: 'Active (Peak Demand)',
  },
  {
    id: 'ZN-2',
    name: 'Airport Express Transportation Hub & Terminals',
    city: 'Metro Central',
    surgeFactor: '1.2x',
    polygonPoints: 24,
    activeDrivers: 38,
    status: 'Active',
  },
  {
    id: 'ZN-3',
    name: 'West Valley University Campus & Tech Corridor',
    city: 'Metro Central',
    surgeFactor: '1.0x',
    polygonPoints: 36,
    activeDrivers: 24,
    status: 'Active',
  },
  {
    id: 'ZN-4',
    name: 'North Hills Residential Estates',
    city: 'Metro Central',
    surgeFactor: '1.0x',
    polygonPoints: 60,
    activeDrivers: 16,
    status: 'Active',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Geofenced Service Areas & Zones
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure geofence polygon boundaries, zone surge multipliers, and airport pickup fees.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <Icon icon="lucide:plus" />
        <span>Create Geofence Zone</span>
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Configured Operational Boundaries</h2>
        <span class="text-xs text-neutral-400">Synced to mobile navigation SDKs</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Zone ID</th>
            <th class="py-3 px-4">Zone Name</th>
            <th class="py-3 px-4">Municipal City</th>
            <th class="py-3 px-4">Surge Factor</th>
            <th class="py-3 px-4">Polygon Boundary</th>
            <th class="py-3 px-4">Active Drivers</th>
            <th class="py-3 px-4 text-right">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="z in operationalZones"
            :key="z.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ z.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ z.name }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ z.city }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  z.surgeFactor !== '1.0x'
                    ? 'bg-amber-100 text-amber-800'
                    : 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ z.surgeFactor }}
              </span>
            </td>
            <td class="py-3 px-4 font-mono text-neutral-500">{{ z.polygonPoints }} GPS Vertices</td>
            <td class="py-3 px-4 font-bold text-neutral-800">{{ z.activeDrivers }} drivers</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800"
              >
                {{ z.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
