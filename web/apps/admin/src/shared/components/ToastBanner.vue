<script setup lang="ts">
import { computed } from 'vue'
import { Icon } from '@iconify/vue'

export type ToastTone = 'info' | 'success' | 'warning' | 'error'

const props = withDefaults(
  defineProps<{
    message: string | null
    tone?: ToastTone
  }>(),
  {
    tone: 'info',
  },
)

const emit = defineEmits<{
  (e: 'dismiss'): void
}>()

const containerClasses = computed(() => {
  switch (props.tone) {
    case 'success':
      return 'bg-emerald-950 text-emerald-50 border border-emerald-800'
    case 'warning':
      return 'bg-amber-950 text-amber-50 border border-amber-800'
    case 'error':
      return 'bg-rose-950 text-rose-50 border border-rose-800'
    default:
      return 'bg-neutral-900 text-white border border-neutral-800'
  }
})

const iconName = computed(() => {
  switch (props.tone) {
    case 'success':
      return 'lucide:check-circle-2'
    case 'warning':
      return 'lucide:alert-triangle'
    case 'error':
      return 'lucide:alert-octagon'
    default:
      return 'lucide:info'
  }
})
</script>

<template>
  <div
    v-if="message"
    role="status"
    aria-live="polite"
    class="p-3.5 text-xs font-medium flex items-center justify-between gap-3 shadow-sm"
    :class="containerClasses"
  >
    <div class="flex items-center gap-2.5 min-w-0">
      <Icon :icon="iconName" class="text-sm shrink-0" aria-hidden="true" />
      <span class="truncate">{{ message }}</span>
    </div>
    <button
      type="button"
      aria-label="Dismiss notification"
      class="p-1 hover:bg-white/10 transition-colors cursor-pointer shrink-0"
      @click="emit('dismiss')"
    >
      <Icon icon="lucide:x" class="text-xs" aria-hidden="true" />
    </button>
  </div>
</template>
