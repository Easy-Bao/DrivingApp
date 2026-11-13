import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { PageHeader, StatusBadge, formatCentavos } from '@/shared'

describe('shared barrel facade and basic UI atoms', () => {
  it('exports public shared primitives cleanly from @/shared', () => {
    expect(formatCentavos(5500)).toBe('₱55.00')

    const header = mount(PageHeader, {
      props: {
        title: 'Drivers',
        description: 'Manage active drivers and assigned vehicles.',
      },
      slots: {
        actions: '<button type="button">Add Driver</button>',
      },
    })
    expect(header.find('h1').text()).toBe('Drivers')
    expect(header.text()).toContain('Manage active drivers and assigned vehicles.')
    expect(header.text()).toContain('Add Driver')

    const badge = mount(StatusBadge, {
      props: { label: 'Verified', tone: 'success' },
    })
    expect(badge.text()).toBe('Verified')
  })
})
