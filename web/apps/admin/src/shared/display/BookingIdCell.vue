<script setup lang="ts">
import { Icon } from '@iconify/vue'
import FloatingToast from '@/shared/feedback/FloatingToast.vue'
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

    <FloatingToast :message="toastMessage" />
  </div>
</template>
