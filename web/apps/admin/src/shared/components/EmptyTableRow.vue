<script setup lang="ts">
import { Icon } from '@iconify/vue'

withDefaults(
  defineProps<{
    colspan: number
    title?: string
    description?: string
    showReset?: boolean
    resetLabel?: string
  }>(),
  {
    title: 'No matching records',
    description: 'Try adjusting your search query or filters.',
    showReset: false,
    resetLabel: 'Reset filters',
  },
)

const emit = defineEmits<{
  (e: 'reset'): void
}>()
</script>

<template>
  <tr>
    <td :colspan="colspan" class="px-4 py-10 text-center">
      <div class="mx-auto max-w-sm flex flex-col items-center gap-2">
        <Icon icon="lucide:search-x" class="text-lg text-neutral-400" aria-hidden="true" />
        <p class="text-xs font-semibold text-neutral-700">{{ title }}</p>
        <p v-if="description" class="text-[11px] text-neutral-500">{{ description }}</p>
        <button
          v-if="showReset"
          type="button"
          class="mt-1 px-3 py-1.5 text-xs font-medium bg-white border border-neutral-200 text-neutral-700 hover:bg-neutral-50 hover:text-neutral-900 transition-colors cursor-pointer"
          @click="emit('reset')"
        >
          {{ resetLabel }}
        </button>
      </div>
    </td>
  </tr>
</template>
