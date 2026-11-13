<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { formatBookingReference } from '@/shared/utils/format'
import { useClipboardCopy } from '@/shared/utils/use-clipboard-copy'

defineProps<{
  bookingId: string
}>()

const { copied, toastMessage, copy } = useClipboardCopy('Copied Booking ID')
</script>

<template>
  <div class="inline-flex items-center gap-1.5 font-mono">
    <span class="font-semibold text-neutral-900 tabular-nums" :title="bookingId">
      {{ formatBookingReference(bookingId) }}
    </span>
    <button
      type="button"
      :title="`Copy Booking ID: ${bookingId}`"
      :aria-label="`Copy Booking ID ${bookingId}`"
      class="inline-flex items-center justify-center p-1 text-neutral-400 hover:text-neutral-900 hover:bg-neutral-100 transition-colors cursor-pointer shrink-0"
      @click="copy(bookingId)"
    >
      <Icon
        :icon="copied ? 'lucide:check' : 'lucide:copy'"
        class="h-3.5 w-3.5"
        :class="copied ? 'text-emerald-600' : ''"
        aria-hidden="true"
      />
    </button>

    <Teleport to="body">
      <div
        v-if="toastMessage"
        role="status"
        aria-live="polite"
        class="fixed bottom-4 right-4 z-[60] bg-neutral-900 text-white border border-neutral-800 px-3 py-2 text-xs font-sans font-medium shadow-lg inline-flex items-center gap-2"
      >
        <Icon
          icon="lucide:check"
          class="h-3.5 w-3.5 text-emerald-400 shrink-0"
          aria-hidden="true"
        />
        <span>{{ toastMessage }}</span>
      </div>
    </Teleport>
  </div>
</template>
