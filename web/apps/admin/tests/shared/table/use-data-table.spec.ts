import { ref } from 'vue'
import { describe, expect, it } from 'vitest'
import { useDataTable } from '@/shared/table/use-data-table'

describe('useDataTable', () => {
  it('paginates rows, resets or clamps page when dataset shrinks, and guards invalid page sizes', async () => {
    const rows = ref(Array.from({ length: 12 }, (_, index) => ({ id: index + 1 })))
    const table = useDataTable(rows, { initialPageSize: 5 })

    expect(table.totalPages.value).toBe(3)
    expect(table.paginatedItems.value.map((r) => r.id)).toEqual([1, 2, 3, 4, 5])

    table.setPage(3)
    expect(table.currentPage.value).toBe(3)
    expect(table.paginatedItems.value.map((r) => r.id)).toEqual([11, 12])

    rows.value = [{ id: 1 }, { id: 2 }]
    expect(table.totalPages.value).toBe(1)
    expect(table.paginatedItems.value.map((r) => r.id)).toEqual([1, 2])

    table.setItemsPerPage(0)
    expect(table.itemsPerPage.value).toBe(1)
  })
})
