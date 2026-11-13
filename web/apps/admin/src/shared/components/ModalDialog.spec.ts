import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ModalDialog from '@/shared/components/ModalDialog.vue'

describe('ModalDialog', () => {
  it('renders dialog content when open and closes via button or Escape key', async () => {
    const wrapper = mount(ModalDialog, {
      props: {
        open: true,
        title: 'Inspect Record',
        subtitle: 'Record #101',
      },
      slots: {
        default: '<p>Modal body content</p>',
        footer: '<button type="button">Done</button>',
      },
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    expect(dialog.text()).toContain('Inspect Record')
    expect(dialog.text()).toContain('Record #101')
    expect(dialog.text()).toContain('Modal body content')
    expect(dialog.text()).toContain('Done')

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(wrapper.emitted('update:open')).toEqual([[false]])
    expect(wrapper.emitted('close')).toHaveLength(1)

    await wrapper.find('button[aria-label="Close dialog"]').trigger('click')
    expect(wrapper.emitted('update:open')).toHaveLength(2)
  })
})
