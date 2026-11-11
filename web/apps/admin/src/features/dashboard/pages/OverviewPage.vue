<script setup lang="ts">
import { ref } from 'vue'

const kpis = [
  {
    label: 'Active Rides',
    value: '428',
    change: '+14%',
    accent: 'border-t-emerald-500',
  },
  {
    label: 'Online Drivers',
    value: '1,280',
    change: '+6%',
    accent: 'border-t-blue-500',
  },
  {
    label: 'Today Revenue',
    value: '₱48,250',
    change: '+21%',
    accent: 'border-t-violet-500',
  },
  {
    label: 'Completion Rate',
    value: '96.4%',
    change: '+0.8%',
    accent: 'border-t-amber-500',
  },
]

const recentTrips = ref([
  {
    id: 'TRP-8921',
    rider: 'Sophia Chen',
    driver: 'Marcus Miller',
    pickup: 'Downtown Plaza',
    dropoff: 'Terminal 2 Airport',
    fare: '₱34.50',
    status: 'In Progress',
  },
  {
    id: 'TRP-8920',
    rider: 'Liam O’Connor',
    driver: 'Elena Rostova',
    pickup: 'Financial District',
    dropoff: 'North Suburbs',
    fare: '₱22.00',
    status: 'Completed',
  },
  {
    id: 'TRP-8919',
    rider: 'Amina Idris',
    driver: 'David Kim',
    pickup: 'Convention Center',
    dropoff: 'Metro Station 4',
    fare: '₱14.20',
    status: 'Completed',
  },
  {
    id: 'TRP-8918',
    rider: 'Lucas Vance',
    driver: 'Unassigned',
    pickup: 'Harbor Hotel',
    dropoff: 'Tech Boulevard',
    fare: '₱18.75',
    status: 'Dispatching',
  },
])
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Executive Operations Overview
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Real-time mobility telemetry and platform performance indicators.
        </p>
      </div>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="p-5 bg-white border border-neutral-200 border-t-2 flex flex-col gap-1"
        :class="kpi.accent"
      >
        <span class="text-xs font-medium text-neutral-500 uppercase tracking-wider">{{
          kpi.label
        }}</span>
        <div class="text-3xl font-bold text-neutral-900 tabular-nums">{{ kpi.value }}</div>
        <span class="text-xs font-semibold text-emerald-700">{{ kpi.change }} vs yesterday</span>
      </div>
    </div>

    <!-- Active Operations Grid -->
    <div class="grid grid-cols-1 gap-6">
      <div class="lg:col-span-2 bg-white border border-neutral-200 overflow-hidden">
        <div class="p-5 border-b border-neutral-100 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <h2 class="font-semibold text-sm text-neutral-900">Recent Trip Dispatches</h2>
          </div>
          <RouterLink
            to="/trips?tab=all-trips"
            class="text-xs font-semibold text-neutral-900 hover:underline"
          >
            View All Trips →
          </RouterLink>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs">
            <thead class="bg-neutral-50 text-neutral-500 border-b border-neutral-100 uppercase">
              <tr>
                <th class="py-3 px-4">Trip ID</th>
                <th class="py-3 px-4">Rider</th>
                <th class="py-3 px-4">Driver</th>
                <th class="py-3 px-4">Route</th>
                <th class="py-3 px-4">Fare</th>
                <th class="py-3 px-4">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-neutral-100 text-neutral-700">
              <tr v-for="trip in recentTrips" :key="trip.id" class="hover:bg-neutral-50/50">
                <td class="py-3.5 px-4 font-mono font-medium text-neutral-900">{{ trip.id }}</td>
                <td class="py-3.5 px-4">{{ trip.rider }}</td>
                <td class="py-3.5 px-4">{{ trip.driver }}</td>
                <td class="py-3.5 px-4 text-neutral-500">{{ trip.pickup }} → {{ trip.dropoff }}</td>
                <td class="py-3.5 px-4 font-semibold text-neutral-900">{{ trip.fare }}</td>
                <td class="py-3.5 px-4">
                  <span
                    class="px-2 py-0.5 rounded-full text-[11px] font-semibold"
                    :class="{
                      'bg-emerald-100 text-emerald-800': trip.status === 'Completed',
                      'bg-blue-100 text-blue-800': trip.status === 'In Progress',
                      'bg-amber-100 text-amber-800': trip.status === 'Dispatching',
                    }"
                  >
                    {{ trip.status }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
