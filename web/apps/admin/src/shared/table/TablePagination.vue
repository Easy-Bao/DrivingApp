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

const safeItemsPerPage = computed(() => {
  if (!Number.isFinite(props.itemsPerPage)) return 1
  return Math.max(1, Math.floor(props.itemsPerPage))
})

const totalPages = computed(() =>
  Math.max(1, Math.ceil(Math.max(0, props.totalItems) / safeItemsPerPage.value)),
)

const safeCurrentPage = computed(() => {
  const raw = Number.isFinite(props.currentPage) ? Math.floor(props.currentPage) : 1
  return Math.min(totalPages.value, Math.max(1, raw))
})

const startItem = computed(() => {
  if (props.totalItems <= 0) return 0
  return (safeCurrentPage.value - 1) * safeItemsPerPage.value + 1
})

const endItem = computed(() => {
  if (props.totalItems <= 0) return 0
  return Math.min(props.totalItems, safeCurrentPage.value * safeItemsPerPage.value)
})

const visiblePages = computed<(number | 'ellipsis-left' | 'ellipsis-right')[]>(() => {
  const total = totalPages.value
  const current = safeCurrentPage.value
  if (total <= 7) {
    return Array.from({ length: total }, (_, index) => index + 1)
  }

  const pages: (number | 'ellipsis-left' | 'ellipsis-right')[] = [1]
  const windowStart = Math.max(2, current - 1)
  const windowEnd = Math.min(total - 1, current + 1)

  if (windowStart > 2) {
    pages.push('ellipsis-left')
  }
  for (let page = windowStart; page <= windowEnd; page++) {
    pages.push(page)
  }
  if (windowEnd < total - 1) {
    pages.push('ellipsis-right')
  }
  pages.push(total)

  return pages
})

function goToPage(page: number) {
  if (page < 1 || page > totalPages.value || page === safeCurrentPage.value) return
  emit('update:currentPage', page)
}
</script>

<template>
  <div
    v-if="totalItems > safeItemsPerPage"
    class="px-4 py-3 border-t border-neutral-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs bg-neutral-50/50 select-none"
  >
    <div class="text-neutral-500 tabular-nums">
      Showing <span class="font-semibold text-neutral-900">{{ startItem }}</span> to
      <span class="font-semibold text-neutral-900">{{ endItem }}</span> of
      <span class="font-semibold text-neutral-900">{{ totalItems }}</span> entries
    </div>

    <nav aria-label="Pagination" class="flex items-center justify-between sm:justify-end gap-1">
      <button
        type="button"
        aria-label="Previous page"
        class="inline-flex items-center px-2.5 h-8 text-neutral-700 bg-white border border-neutral-200 hover:bg-neutral-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors font-medium cursor-pointer"
        :disabled="safeCurrentPage <= 1"
        @click="goToPage(safeCurrentPage - 1)"
      >
        <Icon icon="lucide:chevron-left" class="mr-1 text-xs" aria-hidden="true" />
        <span>Prev</span>
      </button>

      <span class="sm:hidden px-2 text-xs text-neutral-600 font-medium tabular-nums">
        Page {{ safeCurrentPage }} / {{ totalPages }}
      </span>

      <div class="hidden sm:flex items-center gap-1">
        <template v-for="entry in visiblePages" :key="entry">
          <span
            v-if="typeof entry === 'string'"
            class="w-8 h-8 flex items-center justify-center text-neutral-400"
            aria-hidden="true"
          >
            &hellip;
          </span>
          <button
            v-else
            type="button"
            :aria-label="`Page ${entry}`"
            :aria-current="entry === safeCurrentPage ? 'page' : undefined"
            class="w-8 h-8 flex items-center justify-center font-semibold border tabular-nums transition-colors cursor-pointer"
            :class="
              entry === safeCurrentPage
                ? 'bg-neutral-900 text-white border-neutral-900'
                : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
            "
            @click="goToPage(entry)"
          >
            {{ entry }}
          </button>
        </template>
      </div>

      <button
        type="button"
        aria-label="Next page"
        class="inline-flex items-center px-2.5 h-8 text-neutral-700 bg-white border border-neutral-200 hover:bg-neutral-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors font-medium cursor-pointer"
        :disabled="safeCurrentPage >= totalPages"
        @click="goToPage(safeCurrentPage + 1)"
      >
        <span>Next</span>
        <Icon icon="lucide:chevron-right" class="ml-1 text-xs" aria-hidden="true" />
      </button>
    </nav>
  </div>
</template>
