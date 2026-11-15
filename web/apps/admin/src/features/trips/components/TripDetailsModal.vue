<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { tripStatusTone } from '@/features/trips/composables/use-trips'
import type { TripRecord } from '@/features/trips/types'
import {
  FloatingToast,
  ModalDialog,
  RouteTimeline,
  StatusBadge,
  formatCentavos,
  useClipboardCopy,
} from '@/shared'

defineProps<{
  trip: TripRecord | null
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const {
  copied,
  toastMessage: copyToastMessage,
  copy: copyBookingId,
  clear,
} = useClipboardCopy('Copied Booking ID')

function handleOpenUpdate(open: boolean) {
  if (!open) {
    clear()
    emit('close')
  }
}
</script>

<template>
  <ModalDialog
    :open="Boolean(trip)"
    title="Trip Details"
    size="lg"
    close-label="Close"
    @update:open="handleOpenUpdate"
  >
    <template v-if="trip" #header-meta>
      <StatusBadge :label="trip.status" :tone="tripStatusTone(trip.status)" />
    </template>

    <template v-if="trip" #subtitle>
      <div class="flex items-center justify-between gap-3 text-xs text-neutral-500">
        <span class="font-mono tabular-nums">Booking ID: {{ trip.id }}</span>
        <button
          type="button"
          title="Copy Booking ID"
          aria-label="Copy Booking ID"
          class="inline-flex items-center gap-1 p-1 text-neutral-400 hover:text-neutral-900 hover:bg-neutral-100 transition-colors cursor-pointer shrink-0"
          @click="copyBookingId(trip.id)"
        >
          <Icon
            :icon="copied ? 'lucide:check' : 'lucide:copy'"
            class="h-3.5 w-3.5"
            :class="copied ? 'text-emerald-600' : ''"
            aria-hidden="true"
          />
        </button>
      </div>
    </template>

    <div v-if="trip" class="space-y-4 text-xs">
      <div class="p-3.5 bg-neutral-50 border border-neutral-200">
        <RouteTimeline :pickup="trip.pickup" :dropoff="trip.dropoff" />
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
        <div>
          <div class="text-neutral-500">Passenger</div>
          <div class="font-semibold text-neutral-900 mt-0.5">{{ trip.rider }}</div>
          <div class="font-mono text-neutral-500">{{ trip.riderPhone }}</div>
        </div>
        <div>
          <div class="text-neutral-500">Assigned Driver</div>
          <div class="font-semibold text-neutral-900 mt-0.5">
            {{ trip.driver ?? 'Unassigned' }}
          </div>
          <div class="font-mono text-neutral-500">
            {{ trip.plateNumber ?? 'Pending' }} · {{ trip.driverPhone ?? '—' }}
          </div>
        </div>
        <div>
          <div class="text-neutral-500">Vehicle Unit</div>
          <div class="font-medium text-neutral-900 mt-0.5">{{ trip.vehicleModel }}</div>
          <div class="text-[11px] text-neutral-400">{{ trip.timestamp }}</div>
        </div>
        <div>
          <div class="text-neutral-500">Distance / Duration</div>
          <div class="font-mono font-semibold text-neutral-900 mt-0.5 tabular-nums">
            {{ trip.distanceKm }} km · {{ trip.duration ?? '—' }}
          </div>
        </div>
        <div>
          <div class="text-neutral-500">Trip Fare</div>
          <div class="font-mono font-bold text-sm text-neutral-900 mt-0.5 tabular-nums">
            {{ formatCentavos(trip.fareCentavos) }}
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-end gap-2">
        <RouterLink
          to="/payments/settlements"
          class="px-3.5 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 text-xs font-semibold transition-colors"
          @click="handleOpenUpdate(false)"
        >
          Settlements
        </RouterLink>
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
          @click="handleOpenUpdate(false)"
        >
          Close
        </button>
      </div>
    </template>
  </ModalDialog>

  <FloatingToast :message="copyToastMessage" />
</template>
