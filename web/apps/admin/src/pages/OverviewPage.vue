<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const kpis = [
  {
    label: 'Active Rides',
    value: '428',
    change: '+14%',
    icon: 'lucide:route',
    color: 'text-emerald-600',
    bg: 'bg-emerald-50',
  },
  {
    label: 'Online Drivers',
    value: '1,280',
    change: '+6%',
    icon: 'lucide:users',
    color: 'text-blue-600',
    bg: 'bg-blue-50',
  },
  {
    label: 'Today Revenue',
    value: '$48,250',
    change: '+21%',
    icon: 'lucide:dollar-sign',
    color: 'text-violet-600',
    bg: 'bg-violet-50',
  },
  {
    label: 'Completion Rate',
    value: '96.4%',
    change: '+0.8%',
    icon: 'lucide:check-circle-2',
    color: 'text-amber-600',
    bg: 'bg-amber-50',
  },
]

const recentTrips = ref([
  {
    id: 'TRP-8921',
    rider: 'Sophia Chen',
    driver: 'Marcus Miller',
    pickup: 'Downtown Plaza',
    dropoff: 'Terminal 2 Airport',
    fare: '$34.50',
    status: 'In Progress',
  },
  {
    id: 'TRP-8920',
    rider: 'Liam O’Connor',
    driver: 'Elena Rostova',
    pickup: 'Financial District',
    dropoff: 'North Suburbs',
    fare: '$22.00',
    status: 'Completed',
  },
  {
    id: 'TRP-8919',
    rider: 'Amina Idris',
    driver: 'David Kim',
    pickup: 'Convention Center',
    dropoff: 'Metro Station 4',
    fare: '$14.20',
    status: 'Completed',
  },
  {
    id: 'TRP-8918',
    rider: 'Lucas Vance',
    driver: 'Unassigned',
    pickup: 'Harbor Hotel',
    dropoff: 'Tech Boulevard',
    fare: '$18.75',
    status: 'Dispatching',
  },
])
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Executive Operations Overview
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Real-time mobility telemetry and platform performance indicators.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <span
          class="inline-flex items-center px-3 py-1.5 rounded-lg bg-white border border-neutral-200 text-xs font-medium text-neutral-600"
        >
          <Icon icon="lucide:clock" class="mr-1.5 text-neutral-400" />
          Live updates enabled
        </span>
      </div>
    </div>

    <!-- KPI Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="p-5 bg-white border border-neutral-200 rounded-xl shadow-xs flex items-center justify-between"
      >
        <div>
          <span class="text-xs font-medium text-neutral-500 uppercase tracking-wider">{{
            kpi.label
          }}</span>
          <div class="text-2xl font-bold text-neutral-900 mt-1">{{ kpi.value }}</div>
          <span class="text-xs font-semibold text-emerald-600 mt-1 inline-block"
            >{{ kpi.change }} vs yesterday</span
          >
        </div>
        <div
          :class="[
            'w-12 h-12 rounded-xl flex items-center justify-center shrink-0',
            kpi.bg,
            kpi.color,
          ]"
        >
          <Icon :icon="kpi.icon" class="text-2xl" />
        </div>
      </div>
    </div>

    <!-- Active Operations Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Live Trips Feed -->
      <div
        class="lg:col-span-2 bg-white border border-neutral-200 rounded-xl shadow-xs overflow-hidden"
      >
        <div class="p-5 border-b border-neutral-100 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:activity" class="text-neutral-500" />
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

      <!-- Emergency / Live Alerts Card -->
      <div
        class="bg-white border border-neutral-200 rounded-xl shadow-xs p-5 space-y-4 flex flex-col justify-between"
      >
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="font-semibold text-sm text-neutral-900">Priority Alerts</h2>
            <span class="px-2 py-0.5 text-[10px] font-bold bg-rose-100 text-rose-700 rounded-full"
              >Active</span
            >
          </div>

          <div class="p-3.5 rounded-lg bg-rose-50 border border-rose-200 space-y-1">
            <div class="flex items-center space-x-2 text-rose-700 font-semibold text-xs">
              <Icon icon="lucide:siren" class="text-base" />
              <span>SOS Alert: Ride #TRP-8890</span>
            </div>
            <p class="text-[11px] text-rose-600 leading-relaxed">
              Passenger triggered emergency signal near East Industrial Zone. Coordinates relayed to
              safety dispatch.
            </p>
          </div>

          <div class="p-3.5 rounded-lg bg-amber-50 border border-amber-200 space-y-1">
            <div class="flex items-center space-x-2 text-amber-800 font-semibold text-xs">
              <Icon icon="lucide:file-clock" class="text-base" />
              <span>4 Driver Licenses Expiring</span>
            </div>
            <p class="text-[11px] text-amber-700 leading-relaxed">
              Automated notifications sent. Documents enter grace period in 48 hours.
            </p>
          </div>
        </div>

        <RouterLink
          to="/trips?tab=sos-alerts"
          class="w-full py-2 px-3 bg-neutral-900 text-white rounded-lg text-xs font-medium text-center hover:bg-neutral-800 transition-colors block"
        >
          Open Safety Console
        </RouterLink>
      </div>
    </div>
  </div>
</template>
