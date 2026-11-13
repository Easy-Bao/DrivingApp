import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'

describe('ConfirmDialog', () => {
  it('enforces mandatory reason when configured and emits confirm', async () => {
    const wrapper = mount(ConfirmDialog, {
      props: {
        open: true,
        title: 'Suspend Taxicle Driver',
        description: 'Confirm driver suspension in Pagadian dispatch.',
        confirmLabel: 'Suspend Driver',
        requireReason: true,
        reason: '',
        'onUpdate:reason': (value: string) => wrapper.setProps({ reason: value }),
      },
    })

    const confirmBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Suspend Driver'))
    expect(confirmBtn).toBeDefined()
    expect(confirmBtn?.attributes('disabled')).toBeDefined()

    const textarea = wrapper.find('textarea')
    await textarea.setValue('Expired LTO restriction A1 license')

    expect(confirmBtn?.attributes('disabled')).toBeUndefined()
    await confirmBtn?.trigger('click')
    expect(wrapper.emitted('confirm')).toBeTruthy()
  })

  it('closes on escape key press', async () => {
    const wrapper = mount(ConfirmDialog, {
      props: {
        open: true,
        title: 'Confirm Action',
        description: 'Proceed with operation?',
      },
    })

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(wrapper.emitted('cancel')).toBeTruthy()
    expect(wrapper.emitted('update:open')?.[0]).toEqual([false])
  })
})
