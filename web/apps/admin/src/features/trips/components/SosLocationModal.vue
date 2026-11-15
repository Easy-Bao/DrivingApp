<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { SosIncident } from '@/features/trips/types'
import { FloatingToast, ModalDialog, StatusBadge, useClipboardCopy } from '@/shared'

defineProps<{
  incident: SosIncident | null
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const {
  copied,
  toastMessage: copyToastMessage,
  copy,
  clear,
} = useClipboardCopy('Copied coordinates')

function handleOpenUpdate(open: boolean) {
  if (!open) {
    clear()
    emit('close')
  }
}

function copyCoordinates(incident: SosIncident) {
  void copy(`${incident.latitude.toFixed(4)}, ${incident.longitude.toFixed(4)}`)
}
</script>

<template>
  <ModalDialog
    :open="Boolean(incident)"
    :title="incident ? `Incident Location · ${incident.id}` : ''"
    :subtitle="incident ? `${incident.tripId} · ${incident.corridor}` : undefined"
    size="lg"
    close-label="Close"
    @update:open="handleOpenUpdate"
  >
    <template v-if="incident" #header-meta>
      <StatusBadge
        :label="incident.status"
        :tone="incident.status === 'Active' ? 'danger' : 'success'"
      />
    </template>

    <div v-if="incident" class="space-y-4 text-xs">
      <div
        class="h-64 border border-dashed border-neutral-300 bg-neutral-50 flex flex-col items-center justify-center gap-2 text-center p-6"
        data-test="sos-map"
      >
        <Icon icon="lucide:map-pin" class="h-6 w-6 text-neutral-700" aria-hidden="true" />
        <div class="text-sm font-semibold text-neutral-900">Live Map</div>
        <div class="font-mono text-xs text-neutral-600">{{ incident.coords }}</div>
        <div class="text-[11px] text-neutral-500">{{ incident.corridor }}</div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 p-3 border border-neutral-200 bg-white">
        <div>
          <div class="text-neutral-500">Triggered By</div>
          <div class="font-semibold text-neutral-900 mt-0.5">{{ incident.triggeredBy }}</div>
          <div class="text-neutral-500 mt-0.5">
            {{ incident.driverName }} · {{ incident.driverPlate }}
          </div>
        </div>
        <div>
          <div class="text-neutral-500">Coordinates</div>
          <div class="font-mono font-semibold text-neutral-900 mt-0.5">{{ incident.coords }}</div>
          <button
            type="button"
            class="mt-1 inline-flex items-center gap-1 text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
            @click="copyCoordinates(incident)"
          >
            <Icon
              :icon="copied ? 'lucide:check' : 'lucide:copy'"
              class="h-3.5 w-3.5"
              aria-hidden="true"
            />
            <span>Copy Coordinates</span>
          </button>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end">
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="handleOpenUpdate(false)"
        >
          Close
        </button>
      </div>
    </template>
  </ModalDialog>

  <FloatingToast :message="copyToastMessage" />
</template>
