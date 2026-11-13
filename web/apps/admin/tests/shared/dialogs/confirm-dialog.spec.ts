import { defineComponent, ref } from 'vue'
import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'

describe('ConfirmDialog', () => {
  it('enforces mandatory reason when configured and emits confirm', async () => {
    const onConfirm = ref(false)
    const Host = defineComponent({
      components: { ConfirmDialog },
      setup() {
        const open = ref(true)
        const reason = ref('')
        return { open, reason, onConfirm }
      },
      template: `
        <ConfirmDialog
          v-model:open="open"
          v-model:reason="reason"
          title="Suspend Driver"
          description="Confirm driver suspension in Pagadian dispatch."
          confirm-label="Suspend Driver"
          :require-reason="true"
          @confirm="onConfirm = true"
        />
      `,
    })

    const wrapper = mount(Host, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
    })

    const findConfirmButton = () =>
      wrapper.findAll('button').find((button) => button.text().includes('Suspend Driver'))

    expect(findConfirmButton()?.attributes('disabled')).toBeDefined()

    await wrapper.find('textarea').setValue('Expired LTO restriction A1 license')
    expect(findConfirmButton()?.attributes('disabled')).toBeUndefined()

    await findConfirmButton()?.trigger('click')
    expect(onConfirm.value).toBe(true)
  })

  it('closes on escape key press', async () => {
    const wrapper = mount(ConfirmDialog, {
      global: {
        stubs: {
          Teleport: { template: '<div><slot /></div>' },
        },
      },
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
