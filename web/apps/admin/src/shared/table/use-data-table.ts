import { computed, ref, toValue, watch, type MaybeRefOrGetter } from 'vue'

export interface UseDataTableOptions {
  initialPageSize?: number
}

function normalizePositiveInt(value: number, fallback: number): number {
  if (!Number.isFinite(value)) return fallback
  return Math.max(1, Math.floor(value))
}

export function useDataTable<T>(
  source: MaybeRefOrGetter<readonly T[]>,
  options: UseDataTableOptions = {},
) {
  const itemsPerPage = ref(normalizePositiveInt(options.initialPageSize ?? 10, 10))
  const requestedPage = ref(1)

  const items = computed(() => toValue(source))
  const totalItems = computed(() => items.value.length)
  const totalPages = computed(() => Math.max(1, Math.ceil(totalItems.value / itemsPerPage.value)))

  const currentPage = computed({
    get: () => Math.min(totalPages.value, Math.max(1, requestedPage.value)),
    set: (page: number) => {
      requestedPage.value = Math.min(totalPages.value, Math.max(1, normalizePositiveInt(page, 1)))
    },
  })

  watch(totalPages, (nextTotal) => {
    if (requestedPage.value > nextTotal) {
      requestedPage.value = nextTotal
    }
  })

  const startIndex = computed(() => {
    if (totalItems.value === 0) return 0
    return (currentPage.value - 1) * itemsPerPage.value
  })

  const paginatedItems = computed(() => {
    return items.value.slice(startIndex.value, startIndex.value + itemsPerPage.value)
  })

  function setPage(page: number): void {
    currentPage.value = page
  }

  function setItemsPerPage(size: number): void {
    itemsPerPage.value = normalizePositiveInt(size, 1)
    requestedPage.value = 1
  }

  function resetPage(): void {
    requestedPage.value = 1
  }

  return {
    currentPage,
    itemsPerPage,
    totalItems,
    totalPages,
    paginatedItems,
    setPage,
    setItemsPerPage,
    resetPage,
  }
}
