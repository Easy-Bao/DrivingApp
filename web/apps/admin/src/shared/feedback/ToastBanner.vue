<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue'
import { Icon } from '@iconify/vue'

export type ToastTone = 'info' | 'success' | 'warning' | 'error'

const props = withDefaults(
  defineProps<{
    message: string | null
    tone?: ToastTone
    duration?: number
  }>(),
  {
    tone: 'info',
    duration: 3500,
  },
)

const emit = defineEmits<{
  (e: 'dismiss'): void
}>()

let dismissTimer: ReturnType<typeof setTimeout> | null = null

const clearDismissTimer = () => {
  if (dismissTimer !== null) {
    clearTimeout(dismissTimer)
    dismissTimer = null
  }
}

watch(
  [() => props.message, () => props.duration],
  ([message, duration]) => {
    clearDismissTimer()
    if (!message || duration <= 0) return
    dismissTimer = setTimeout(() => {
      dismissTimer = null
      emit('dismiss')
    }, duration)
  },
  { immediate: true },
)

onBeforeUnmount(clearDismissTimer)

const iconClasses = computed(() => {
  switch (props.tone) {
    case 'success':
      return 'text-emerald-400'
    case 'warning':
      return 'text-amber-400'
    case 'error':
      return 'text-rose-400'
    default:
      return 'text-neutral-300'
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
    class="bg-neutral-900 text-white border border-neutral-900 p-3 text-xs font-medium flex items-center justify-between gap-3"
  >
    <div class="flex items-center gap-2 min-w-0">
      <Icon :icon="iconName" class="text-sm shrink-0" :class="iconClasses" aria-hidden="true" />
      <span class="truncate">{{ message }}</span>
    </div>
    <button
      type="button"
      aria-label="Dismiss notification"
      class="p-1 text-neutral-400 hover:text-white transition-colors cursor-pointer shrink-0"
      @click="emit('dismiss')"
    >
      <Icon icon="lucide:x" class="text-xs" aria-hidden="true" />
    </button>
  </div>
</template>
