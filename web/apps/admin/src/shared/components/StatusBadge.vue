<script setup lang="ts">
import { computed } from 'vue'

export type BadgeTone = 'success' | 'warning' | 'danger' | 'info' | 'neutral'

const props = withDefaults(
  defineProps<{
    label: string
    tone?: BadgeTone
  }>(),
  {
    tone: 'neutral',
  },
)

const toneClasses = computed(() => {
  switch (props.tone) {
    case 'success':
      return 'bg-emerald-100 text-emerald-800 border-emerald-200'
    case 'warning':
      return 'bg-amber-100 text-amber-800 border-amber-200'
    case 'danger':
      return 'bg-rose-100 text-rose-800 border-rose-200'
    case 'info':
      return 'bg-sky-100 text-sky-800 border-sky-200'
    default:
      return 'bg-neutral-100 text-neutral-700 border-neutral-200'
  }
})
</script>

<template>
  <span
    class="inline-flex items-center px-2 py-0.5 rounded-none text-[10px] font-semibold border whitespace-nowrap"
    :class="toneClasses"
  >
    {{ label }}
  </span>
</template>
