<script setup lang="ts">
import { ref } from 'vue'

const operatingCities = ref([
  {
    id: 'CITY-01',
    cityName: 'Metro Central',
    stateProvince: 'California',
    country: 'United States',
    currency: 'PHP (₱)',
    timeZone: 'America/Los_Angeles (PST/PDT)',
    activeDrivers: 1280,
    status: 'Operational',
  },
  {
    id: 'CITY-02',
    cityName: 'Bay Harbor East',
    stateProvince: 'California',
    country: 'United States',
    currency: 'PHP (₱)',
    timeZone: 'America/Los_Angeles (PST/PDT)',
    activeDrivers: 140,
    status: 'Operational',
  },
  {
    id: 'CITY-03',
    cityName: 'Cascade Valley',
    stateProvince: 'Washington',
    country: 'United States',
    currency: 'PHP (₱)',
    timeZone: 'America/Los_Angeles (PST/PDT)',
    activeDrivers: 0,
    status: 'Launching Next Quarter',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Operating Cities & Regional Centers
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage operating regional licenses, default municipal currencies, and timezone parameters.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <span>Add Operating City</span>
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Regional License Registry</h2>
        <span class="text-xs text-neutral-400">Jurisdictional operating permissions</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">City ID</th>
            <th class="py-3 px-4">City & State</th>
            <th class="py-3 px-4">Country</th>
            <th class="py-3 px-4">Currency</th>
            <th class="py-3 px-4">Timezone</th>
            <th class="py-3 px-4">Fleet Population</th>
            <th class="py-3 px-4 text-right">Operational Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="c in operatingCities"
            :key="c.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ c.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">
              {{ c.cityName }}, {{ c.stateProvince }}
            </td>
            <td class="py-3 px-4 text-neutral-600">{{ c.country }}</td>
            <td class="py-3 px-4 font-mono text-neutral-700">{{ c.currency }}</td>
            <td class="py-3 px-4 text-neutral-500 text-[11px]">{{ c.timeZone }}</td>
            <td class="py-3 px-4 font-bold text-neutral-800">{{ c.activeDrivers }} drivers</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  c.status === 'Operational'
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-blue-100 text-blue-800'
                "
              >
                {{ c.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
