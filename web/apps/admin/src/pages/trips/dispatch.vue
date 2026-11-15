<script setup lang="ts">
import { ref } from 'vue'
import { useDispatch, type DispatchZone, type LiveDispatchItem } from '@/features/trips'
import { BaseSelect, ModalDialog, PageHeader, StatusBadge, ToastBanner } from '@/shared'

const {
  zones,
  liveDispatches,
  surgeOptions,
  availableDrivers,
  updateZoneSurge,
  assignDispatchDriver,
} = useDispatch()

const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'error'>('success')
const editingZone = ref<DispatchZone | null>(null)
const selectedSurge = ref('1.0x')
const assigningDispatch = ref<LiveDispatchItem | null>(null)
const selectedDriver = ref(availableDrivers.value[0] ?? '')

const openSurgeModal = (zone: DispatchZone) => {
  editingZone.value = zone
  selectedSurge.value = zone.surge
}

const applySurgeOverride = () => {
  if (!editingZone.value) return
  const targetName = editingZone.value.name
  const result = updateZoneSurge(targetName, selectedSurge.value)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = `Updated dispatch surge multiplier for ${targetName} to ${selectedSurge.value}.`
  editingZone.value = null
}

const openAssignModal = (dispatch: LiveDispatchItem) => {
  assigningDispatch.value = dispatch
  selectedDriver.value = dispatch.driver ?? availableDrivers.value[0] ?? ''
}

const confirmDriverAssignment = () => {
  if (!assigningDispatch.value) return
  const targetId = assigningDispatch.value.id
  const result = assignDispatchDriver(targetId, selectedDriver.value)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = `Manually dispatched ${selectedDriver.value} to ${targetId}.`
  assigningDispatch.value = null
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Dispatch"
      description="Monitor zone supply, adjust surge caps, and assign trips."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div
        v-for="zone in zones"
        :key="zone.name"
        class="bg-white p-4 border border-neutral-200 space-y-3"
      >
        <div class="flex items-center justify-between gap-2">
          <span class="font-bold text-xs text-neutral-900 truncate">{{ zone.name }}</span>
          <button
            type="button"
            class="px-2 py-0.5 text-[10px] font-bold cursor-pointer transition-colors"
            :class="
              zone.surge !== '1.0x'
                ? 'bg-neutral-900 text-white hover:bg-neutral-800'
                : 'bg-neutral-100 text-neutral-700 hover:bg-neutral-200'
            "
            @click="openSurgeModal(zone)"
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

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Active Dispatches</h2>
        <span
          class="px-2.5 py-1 bg-neutral-50 border border-neutral-300 text-[11px] font-semibold text-neutral-800 tabular-nums"
        >
          Live: {{ liveDispatches.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[780px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Dispatch ID</th>
              <th class="py-3 px-4">Passenger</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Zone</th>
              <th class="py-3 px-4">Pickup ETA</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="dispatch in liveDispatches"
              :key="dispatch.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ dispatch.id }}</td>
              <td class="py-3 px-4 font-medium text-neutral-900">{{ dispatch.rider }}</td>
              <td class="py-3 px-4 text-neutral-800">{{ dispatch.driver ?? 'Unassigned' }}</td>
              <td class="py-3 px-4 text-neutral-500">{{ dispatch.zone }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ dispatch.eta }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="dispatch.status"
                  :tone="dispatch.driver ? 'success' : 'warning'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="openAssignModal(dispatch)"
                >
                  {{ dispatch.driver ? 'Reassign' : 'Assign Driver' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      :open="Boolean(editingZone)"
      title="Zone Surge Multiplier"
      size="sm"
      close-label="Close"
      @update:open="(open) => !open && (editingZone = null)"
    >
      <form v-if="editingZone" class="space-y-4 text-xs" @submit.prevent="applySurgeOverride">
        <div class="space-y-2">
          <div class="font-semibold text-neutral-800">{{ editingZone.name }}</div>
          <label class="block text-neutral-500">Select temporary demand multiplier</label>
          <BaseSelect
            v-model="selectedSurge"
            aria-label="Select surge zone multiplier"
            :full-width="true"
            :options="surgeOptions"
          />
        </div>
        <div class="flex items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-3.5 py-1.5 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 cursor-pointer"
            @click="editingZone = null"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-3.5 py-1.5 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
          >
            Apply Surge
          </button>
        </div>
      </form>
    </ModalDialog>

    <ModalDialog
      :open="Boolean(assigningDispatch)"
      :title="assigningDispatch ? `Manual Dispatch · ${assigningDispatch.id}` : ''"
      size="md"
      close-label="Close"
      @update:open="(open) => !open && (assigningDispatch = null)"
    >
      <form
        v-if="assigningDispatch"
        class="space-y-4 text-xs"
        @submit.prevent="confirmDriverAssignment"
      >
        <div class="space-y-2">
          <div>
            Passenger: <span class="font-semibold">{{ assigningDispatch.rider }}</span> ({{
              assigningDispatch.zone
            }})
          </div>
          <label class="block text-neutral-500 pt-1">Select Driver Unit</label>
          <BaseSelect
            v-model="selectedDriver"
            aria-label="Select replacement driver"
            :full-width="true"
            :options="availableDrivers"
          />
        </div>
        <div class="flex items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-3.5 py-1.5 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 cursor-pointer"
            @click="assigningDispatch = null"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="!selectedDriver"
            class="px-3.5 py-1.5 bg-neutral-900 text-white text-xs font-semibold disabled:opacity-40 cursor-pointer"
          >
            Dispatch Driver
          </button>
        </div>
      </form>
    </ModalDialog>
  </div>
</template>
