<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

interface SosAlert {
  id: string
  tripId: string
  triggeredBy: string
  contactPhone: string
  driver: string
  driverPhone: string
  vehicle: string
  coordinates: string
  timestamp: string
  emergencyServicesNotified: boolean
  status: 'Critical Alert' | 'Dispatched Assistance' | 'Resolved'
}

const sosAlerts = ref<SosAlert[]>([
  {
    id: 'SOS-091',
    tripId: 'TRP-1085',
    triggeredBy: 'Emily Clark (Rider)',
    contactPhone: '+1 (555) 902-1144',
    driver: 'Hassan Tariq',
    driverPhone: '+1 (555) 441-2991',
    vehicle: 'Toyota Prius (Plate: 9ABC21)',
    coordinates: '37.7749° N, 122.4194° W',
    timestamp: '6 mins ago',
    emergencyServicesNotified: true,
    status: 'Critical Alert',
  },
  {
    id: 'SOS-090',
    tripId: 'TRP-1072',
    triggeredBy: 'Daniel Vance (Driver)',
    contactPhone: '+1 (555) 345-6789',
    driver: 'Daniel Vance',
    driverPhone: '+1 (555) 345-6789',
    vehicle: 'Honda Accord (Plate: CAM-8891)',
    coordinates: '37.7833° N, 122.4167° W',
    timestamp: '38 mins ago',
    emergencyServicesNotified: true,
    status: 'Dispatched Assistance',
  },
])

const actionToast = ref<string | null>(null)

function resolveSos(alert: SosAlert) {
  alert.status = 'Resolved'
  actionToast.value = `Incident ${alert.id} marked as resolved. Safety incident report logged.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          SOS & Emergency Operations Center
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          High-priority in-cabin panic button triggers, real-time vehicle GPS coordinates, and 911
          dispatch linkage.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="flex items-center space-x-1.5 px-3 py-1.5 bg-rose-50 border border-rose-200 text-xs font-bold text-rose-800"
        >
          <span class="w-2 h-2 rounded-full bg-rose-600 animate-ping" />
          <span>2 Active Emergency Alerts</span>
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-rose-200 overflow-hidden">
      <div class="p-4 bg-rose-50/60 border-b border-rose-100 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <Icon icon="lucide:siren" class="text-rose-600 text-lg animate-pulse" />
          <h2 class="font-bold text-sm text-rose-950">Active Panic Alarm Queue</h2>
        </div>
        <span class="text-xs font-semibold text-rose-700">Immediate response required</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Alert ID</th>
            <th class="py-3 px-4">Triggered By</th>
            <th class="py-3 px-4">Driver & Vehicle</th>
            <th class="py-3 px-4">GPS Coordinates</th>
            <th class="py-3 px-4">Timestamp</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Emergency Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="sos in sosAlerts" :key="sos.id" class="hover:bg-rose-50/30 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-rose-700">{{ sos.id }}</td>
            <td class="py-3 px-4">
              <div class="font-bold text-neutral-900">{{ sos.triggeredBy }}</div>
              <div class="text-[11px] text-neutral-500 font-mono">{{ sos.contactPhone }}</div>
            </td>
            <td class="py-3 px-4">
              <div class="font-medium text-neutral-900">{{ sos.driver }}</div>
              <div class="text-[11px] text-neutral-500">{{ sos.vehicle }}</div>
            </td>
            <td class="py-3 px-4 font-mono text-neutral-800 font-medium">
              <div class="flex items-center space-x-1">
                <Icon icon="lucide:map-pin" class="text-rose-500 shrink-0" />
                <span>{{ sos.coordinates }}</span>
              </div>
            </td>
            <td class="py-3 px-4 text-neutral-500 font-semibold">{{ sos.timestamp }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  sos.status === 'Critical Alert'
                    ? 'bg-rose-500 text-white animate-pulse'
                    : sos.status === 'Dispatched Assistance'
                      ? 'bg-amber-100 text-amber-800'
                      : 'bg-emerald-100 text-emerald-800'
                "
              >
                {{ sos.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right space-x-2">
              <button
                type="button"
                class="px-2.5 py-1 bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold transition-colors"
                @click="resolveSos(sos)"
              >
                Resolve Incident
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
