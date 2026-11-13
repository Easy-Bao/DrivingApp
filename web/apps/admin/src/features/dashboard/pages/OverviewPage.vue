<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import { useTopups } from '@/features/payments/composables/useTopups'
import { useSettlements } from '@/features/payments/composables/useSettlements'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import { formatPhp } from '@/shared/utils/format'

const { topUpRequests } = useTopups()
const { pendingReviewCount } = useSettlements()

const pendingTopupCount = computed(
  () => topUpRequests.value.filter((item) => item.status === 'Pending').length,
)

const kpis = [
  {
    label: 'Active Rides',
    value: '142',
    change: '+14%',
    accent: 'border-t-emerald-500',
  },
  {
    label: 'Online Drivers',
    value: '318',
    change: '+6%',
    accent: 'border-t-blue-500',
  },
  {
    label: 'Today Revenue',
    value: formatPhp(48250),
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
    id: 'TRP-7016-8921',
    rider: 'Althea Mae Villanueva',
    driver: 'Rodelio Cruz',
    pickup: 'Brgy. San Jose',
    dropoff: 'Agora Public Market',
    fare: 55,
    status: 'In Progress' as const,
  },
  {
    id: 'TRP-7016-8920',
    rider: 'Carlo Magno Ocampo',
    driver: 'Danilo Mendoza',
    pickup: 'Brgy. Gatas',
    dropoff: "Robinson's Place Pagadian",
    fare: 65,
    status: 'Completed' as const,
  },
  {
    id: 'TRP-7016-8919',
    rider: 'Jessa Mae Lim',
    driver: 'Reynaldo Garcia',
    pickup: 'Pagadian Integrated Terminal',
    dropoff: 'ZDS Medical Center',
    fare: 85,
    status: 'Completed' as const,
  },
  {
    id: 'TRP-7016-8918',
    rider: 'Mark Anthony Reyes',
    driver: 'Unassigned',
    pickup: 'Santiago District',
    dropoff: 'Provincial Capitol Complex',
    fare: 50,
    status: 'Dispatching' as const,
  },
])

const tripTone = (status: 'Completed' | 'In Progress' | 'Dispatching') => {
  if (status === 'Completed') return 'success'
  if (status === 'In Progress') return 'info'
  return 'warning'
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Executive Operations Overview
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Real-time Pagadian taxicle telemetry, bidding dispatch velocity, and treasury metrics.
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <RouterLink
          to="/trips/bidding"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 hover:bg-neutral-50 transition-colors"
        >
          <Icon icon="lucide:gavel" class="w-3.5 h-3.5 text-neutral-500" />
          <span>Live Bidding</span>
        </RouterLink>
        <RouterLink
          to="/payments/topups"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-amber-50 border border-amber-200 rounded-md text-xs font-semibold text-amber-900 hover:bg-amber-100 transition-colors"
        >
          <Icon icon="lucide:wallet" class="w-3.5 h-3.5 text-amber-700" />
          <span>{{ pendingTopupCount }} Pending Top-Ups</span>
        </RouterLink>
        <RouterLink
          to="/payments/settlements"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-rose-50 border border-rose-200 rounded-md text-xs font-semibold text-rose-900 hover:bg-rose-100 transition-colors"
        >
          <Icon icon="lucide:coins" class="w-3.5 h-3.5 text-rose-700" />
          <span>{{ pendingReviewCount }} Settlement Reviews</span>
        </RouterLink>
      </div>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="p-5 bg-white rounded-lg border border-neutral-200 border-t-2 flex flex-col gap-1"
        :class="kpi.accent"
      >
        <span class="text-xs font-medium text-neutral-500 uppercase tracking-wider">{{
          kpi.label
        }}</span>
        <div class="text-3xl font-bold text-neutral-900 tabular-nums">{{ kpi.value }}</div>
        <span class="text-xs font-semibold text-emerald-700">{{ kpi.change }} vs yesterday</span>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-6">
      <div class="lg:col-span-2 bg-white rounded-lg border border-neutral-200 overflow-hidden">
        <div class="p-5 border-b border-neutral-100 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <h2 class="font-semibold text-sm text-neutral-900">Recent Trip Dispatches</h2>
          </div>
          <RouterLink
            to="/trips/all"
            class="text-xs font-semibold text-neutral-900 hover:underline"
          >
            View All Trips →
          </RouterLink>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full min-w-[760px] text-left text-xs">
            <thead class="bg-neutral-50 text-neutral-500 border-b border-neutral-100 uppercase">
              <tr>
                <th class="py-3 px-4">Trip ID</th>
                <th class="py-3 px-4">Passenger</th>
                <th class="py-3 px-4">Driver</th>
                <th class="py-3 px-4">Route (Pagadian)</th>
                <th class="py-3 px-4">Agreed Fare</th>
                <th class="py-3 px-4">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-neutral-100 text-neutral-700">
              <tr v-for="trip in recentTrips" :key="trip.id" class="hover:bg-neutral-50/50">
                <td class="py-3.5 px-4 font-mono font-medium text-neutral-900">{{ trip.id }}</td>
                <td class="py-3.5 px-4">{{ trip.rider }}</td>
                <td class="py-3.5 px-4">{{ trip.driver }}</td>
                <td class="py-3.5 px-4 text-neutral-500">{{ trip.pickup }} → {{ trip.dropoff }}</td>
                <td class="py-3.5 px-4 font-mono font-semibold text-neutral-900">
                  {{ formatPhp(trip.fare) }}
                </td>
                <td class="py-3.5 px-4">
                  <StatusBadge :label="trip.status" :tone="tripTone(trip.status)" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
