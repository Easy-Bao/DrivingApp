import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'

describe('EmptyTableRow', () => {
  it('renders empty state metadata and emits reset when reset button is clicked', async () => {
    const wrapper = mount(EmptyTableRow, {
      props: {
        colspan: 6,
        title: 'No trips match criteria',
        description: 'Clear filters to inspect all Pagadian dispatches.',
        showReset: true,
        resetLabel: 'Clear All',
      },
      attachTo: document.createElement('tbody'),
    })

    expect(wrapper.find('td').attributes('colspan')).toBe('6')
    expect(wrapper.text()).toContain('No trips match criteria')
    expect(wrapper.text()).toContain('Clear filters to inspect all Pagadian dispatches.')

    const resetBtn = wrapper.findAll('button').find((b) => b.text().includes('Clear All'))
    expect(resetBtn).toBeDefined()
    await resetBtn!.trigger('click')
    expect(wrapper.emitted('reset')).toHaveLength(1)

    wrapper.unmount()
  })
})
