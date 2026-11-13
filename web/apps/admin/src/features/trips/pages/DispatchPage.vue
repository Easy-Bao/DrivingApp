<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface DispatchZone {
  name: string
  activeDrivers: number
  pendingRequests: number
  avgWait: string
  surge: string
}

interface LiveDispatchItem {
  id: string
  rider: string
  driver: string
  eta: string
  status: string
  zone: string
}

const availablePagadianDrivers = [
  'Rodelio Cruz (1284-ND)',
  'Danilo Mendoza (4912-NC)',
  'Reynaldo Garcia (9021-ND)',
  'Eduardo Santos (7712-NC)',
  'Maria Lourdes Ramos (3391-ND)',
]

const surgeOptions = ['1.0x', '1.2x', '1.4x', '1.6x', '2.0x']

const activeZones = ref<DispatchZone[]>([
  {
    name: 'Agora Market - Poblacion Core',
    activeDrivers: 48,
    pendingRequests: 12,
    avgWait: '2.4 mins',
    surge: '1.4x',
  },
  {
    name: 'Pagadian Integrated Bus Terminal',
    activeDrivers: 34,
    pendingRequests: 8,
    avgWait: '3.1 mins',
    surge: '1.2x',
  },
  {
    name: 'Capitol Complex - Brgy. Balangasan',
    activeDrivers: 22,
    pendingRequests: 4,
    avgWait: '4.2 mins',
    surge: '1.0x',
  },
  {
    name: "Robinson's Place - Brgy. Tiguma",
    activeDrivers: 19,
    pendingRequests: 5,
    avgWait: '3.8 mins',
    surge: '1.2x',
  },
])

const liveDispatches = ref<LiveDispatchItem[]>([
  {
    id: 'DSP-7016-881',
    rider: 'Althea Mae Villanueva',
    driver: 'Rodelio Cruz (1284-ND)',
    eta: '3 mins',
    status: 'En Route to Pickup',
    zone: 'Agora Market - Poblacion Core',
  },
  {
    id: 'DSP-7016-882',
    rider: 'Carlo Magno Ocampo',
    driver: 'Danilo Mendoza (4912-NC)',
    eta: '1 min',
    status: 'Arrived at Pickup',
    zone: 'Pagadian Integrated Bus Terminal',
  },
  {
    id: 'DSP-7016-883',
    rider: 'Mark Anthony Reyes',
    driver: 'Unassigned',
    eta: '4 mins',
    status: 'Awaiting Driver Assignment',
    zone: "Robinson's Place - Brgy. Tiguma",
  },
])

const toastMessage = ref<string | null>(null)
const editingZone = ref<DispatchZone | null>(null)
const selectedSurge = ref('1.0x')
const assigningDispatch = ref<LiveDispatchItem | null>(null)
const selectedDriver = ref(availablePagadianDrivers[0]!)

const openSurgeModal = (zone: DispatchZone) => {
  editingZone.value = zone
  selectedSurge.value = zone.surge
}

const applySurgeOverride = () => {
  if (!editingZone.value) return
  editingZone.value.surge = selectedSurge.value
  toastMessage.value = `Updated dispatch surge multiplier for ${editingZone.value.name} to ${selectedSurge.value}.`
  editingZone.value = null
}

const openAssignModal = (dispatch: LiveDispatchItem) => {
  assigningDispatch.value = dispatch
  selectedDriver.value = availablePagadianDrivers[0]!
}

const confirmDriverAssignment = () => {
  if (!assigningDispatch.value) return
  assigningDispatch.value.driver = selectedDriver.value
  assigningDispatch.value.status = 'En Route to Pickup'
  assigningDispatch.value.eta = '3 mins'
  toastMessage.value = `Manually dispatched ${selectedDriver.value} to ${assigningDispatch.value.id}.`
  assigningDispatch.value = null
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Real-Time Dispatch Radar
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Monitor Pagadian TODA zone supply density, adjust temporary surge caps, and manually assign
        unserved trips.
      </p>
    </div>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="zone in activeZones"
        :key="zone.name"
        class="bg-white rounded-lg p-4 border border-neutral-200 space-y-3"
      >
        <div class="flex items-center justify-between gap-2">
          <span class="font-bold text-xs text-neutral-900 truncate">{{ zone.name }}</span>
          <button
            type="button"
            @click="openSurgeModal(zone)"
            class="px-2 py-0.5 rounded text-[10px] font-bold cursor-pointer transition-colors"
            :class="
              zone.surge !== '1.0x'
                ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                : 'bg-neutral-100 text-neutral-700 hover:bg-neutral-200'
            "
          >
            {{ zone.surge }} · Adjust
          </button>
        </div>
        <div class="grid grid-cols-3 gap-1 pt-2 border-t border-neutral-100 text-center">
          <div>
            <div class="text-[11px] text-neutral-400">Drivers</div>
            <div class="text-xs font-bold text-neutral-900 tabular-nums">
              {{ zone.activeDrivers }}
            </div>
          </div>
          <div>
            <div class="text-[11px] text-neutral-400">Waiting</div>
            <div class="text-xs font-bold text-neutral-900 tabular-nums">
              {{ zone.pendingRequests }}
            </div>
          </div>
          <div>
            <div class="text-[11px] text-neutral-400">ETA</div>
            <div class="text-xs font-bold text-neutral-900 tabular-nums">{{ zone.avgWait }}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Active Real-Time Dispatches</h2>
        <span class="text-xs text-neutral-400">Pagadian TODA live telemetry stream</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[780px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Dispatch ID</th>
              <th class="py-3 px-4">Passenger</th>
              <th class="py-3 px-4">Matched Driver</th>
              <th class="py-3 px-4">Pagadian Zone</th>
              <th class="py-3 px-4">Pickup ETA</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
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
              <td class="py-3 px-4">
                <StatusBadge
                  :label="d.status"
                  :tone="d.driver === 'Unassigned' ? 'warning' : 'success'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  @click="openAssignModal(d)"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors cursor-pointer"
                >
                  {{ d.driver === 'Unassigned' ? 'Assign Driver' : 'Reassign' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="editingZone"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="editingZone = null"
      >
        <form
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-sm p-6 space-y-4"
          @submit.prevent="applySurgeOverride"
        >
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">Zone Surge Multiplier</h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="editingZone = null"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>
          <div class="text-xs space-y-2">
            <div class="font-semibold text-neutral-800">{{ editingZone.name }}</div>
            <label class="block text-neutral-500">Select temporary demand multiplier</label>
            <BaseSelect
              v-model="selectedSurge"
              aria-label="Select surge zone multiplier"
              :full-width="true"
              :options="surgeOptions"
            />
          </div>
          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="editingZone = null"
              class="px-3.5 py-1.5 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-3.5 py-1.5 bg-neutral-900 text-white rounded-md text-xs font-semibold cursor-pointer"
            >
              Apply Surge
            </button>
          </div>
        </form>
      </div>
    </Teleport>

    <Teleport to="body">
      <div
        v-if="assigningDispatch"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="assigningDispatch = null"
      >
        <form
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-md p-6 space-y-4"
          @submit.prevent="confirmDriverAssignment"
        >
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">
              Manual Taxicle Dispatch · {{ assigningDispatch.id }}
            </h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="assigningDispatch = null"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>
          <div class="text-xs space-y-2">
            <div>
              Passenger: <span class="font-semibold">{{ assigningDispatch.rider }}</span> ({{
                assigningDispatch.zone
              }})
            </div>
            <label class="block text-neutral-500 pt-1">Select Active Pagadian Taxicle Unit</label>
            <BaseSelect
              v-model="selectedDriver"
              aria-label="Select replacement driver"
              :full-width="true"
              :options="availablePagadianDrivers"
            />
          </div>
          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="assigningDispatch = null"
              class="px-3.5 py-1.5 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-3.5 py-1.5 bg-neutral-900 text-white rounded-md text-xs font-semibold cursor-pointer"
            >
              Dispatch Driver
            </button>
          </div>
        </form>
      </div>
    </Teleport>
  </div>
</template>
