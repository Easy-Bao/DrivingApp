import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import TablePagination from '@/shared/table/TablePagination.vue'

describe('TablePagination', () => {
  it('guards against non-positive itemsPerPage without producing infinite pages', () => {
    const wrapper = mount(TablePagination, {
      props: {
        totalItems: 25,
        itemsPerPage: 0,
        currentPage: 1,
      },
    })

    expect(wrapper.find('nav[aria-label="Pagination"]').exists()).toBe(true)
    expect(wrapper.find('button[aria-label="Next page"]').exists()).toBe(true)
    expect(wrapper.text()).toContain('Showing 1 to 1 of 25 entries')
    expect(wrapper.text()).not.toContain('Infinity')
  })

  it('emits valid page updates and disables navigation boundaries', async () => {
    const wrapper = mount(TablePagination, {
      props: {
        totalItems: 30,
        itemsPerPage: 10,
        currentPage: 2,
      },
    })

    expect(wrapper.text()).toContain('Showing 11 to 20 of 30 entries')
    await wrapper.find('button[aria-label="Next page"]').trigger('click')
    expect(wrapper.emitted('update:currentPage')?.[0]).toEqual([3])

    await wrapper.setProps({ currentPage: 3 })
    expect(wrapper.find('button[aria-label="Next page"]').attributes('disabled')).toBeDefined()
  })
})
