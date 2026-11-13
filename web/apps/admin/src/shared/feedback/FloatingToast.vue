<script setup lang="ts">
import { Icon } from '@iconify/vue'

withDefaults(
  defineProps<{
    message: string | null
    icon?: string
  }>(),
  {
    icon: 'lucide:check',
  },
)
</script>

<template>
  <Teleport v-if="message" to="body">
    <div
      role="status"
      aria-live="polite"
      class="fixed bottom-4 right-4 z-[60] bg-neutral-900 text-white border border-neutral-800 px-3 py-2 text-xs font-sans font-medium shadow-lg inline-flex items-center gap-2"
    >
      <Icon :icon="icon" class="h-3.5 w-3.5 text-emerald-400 shrink-0" aria-hidden="true" />
      <span>{{ message }}</span>
    </div>
  </Teleport>
</template>
