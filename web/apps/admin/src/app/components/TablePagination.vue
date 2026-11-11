<script setup lang="ts">
import { computed } from 'vue'
import { Icon } from '@iconify/vue'

const props = withDefaults(
  defineProps<{
    totalItems: number
    itemsPerPage?: number
    currentPage: number
  }>(),
  {
    itemsPerPage: 10,
  },
)

const emit = defineEmits<{
  (e: 'update:currentPage', page: number): void
}>()

const totalPages = computed(() => Math.max(1, Math.ceil(props.totalItems / props.itemsPerPage)))

const startItem = computed(() => {
  if (props.totalItems === 0) return 0
  return (props.currentPage - 1) * props.itemsPerPage + 1
})

const endItem = computed(() => {
  return Math.min(props.totalItems, props.currentPage * props.itemsPerPage)
})

function goToPage(page: number) {
  if (page < 1 || page > totalPages.value || page === props.currentPage) return
  emit('update:currentPage', page)
}
</script>

<template>
  <div
    v-if="totalItems > itemsPerPage"
    class="px-4 py-3 border-t border-neutral-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs bg-neutral-50/50 select-none"
  >
    <div class="text-neutral-500 tabular-nums">
      Showing <span class="font-semibold text-neutral-900">{{ startItem }}</span> to
      <span class="font-semibold text-neutral-900">{{ endItem }}</span> of
      <span class="font-semibold text-neutral-900">{{ totalItems }}</span> entries
    </div>

    <div class="flex items-center space-x-1">
      <button
        type="button"
        class="inline-flex items-center px-2.5 py-1 text-neutral-700 bg-white border border-neutral-200 hover:bg-neutral-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors font-medium"
        :disabled="currentPage <= 1"
        @click="goToPage(currentPage - 1)"
      >
        <Icon icon="lucide:chevron-left" class="mr-1 text-xs" />
        <span>Prev</span>
      </button>

      <button
        v-for="page in totalPages"
        :key="page"
        type="button"
        class="w-7 h-7 flex items-center justify-center font-semibold border tabular-nums transition-colors"
        :class="
          page === currentPage
            ? 'bg-neutral-900 text-white border-neutral-900'
            : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
        "
        @click="goToPage(page)"
      >
        {{ page }}
      </button>

      <button
        type="button"
        class="inline-flex items-center px-2.5 py-1 text-neutral-700 bg-white border border-neutral-200 hover:bg-neutral-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors font-medium"
        :disabled="currentPage >= totalPages"
        @click="goToPage(currentPage + 1)"
      >
        <span>Next</span>
        <Icon icon="lucide:chevron-right" class="ml-1 text-xs" />
      </button>
    </div>
  </div>
</template>
