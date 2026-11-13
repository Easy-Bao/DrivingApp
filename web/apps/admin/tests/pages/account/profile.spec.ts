import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ProfilePage from '@/pages/account/profile.vue'

describe('ProfilePage', () => {
  it('saves updated operator profile preferences and validates email input', async () => {
    const wrapper = mount(ProfilePage)

    const nameInput = wrapper.find('#profile-full-name')
    await nameInput.setValue('Carlo Reyes')

    await wrapper.find('form').trigger('submit')
    expect(wrapper.text()).toContain('Operator profile preferences updated.')
    expect(wrapper.text()).toContain('Carlo Reyes')
  })

  it('opens and validates the password rotation modal', async () => {
    const wrapper = mount(ProfilePage)

    const rotateBtn = wrapper
      .findAll('button')
      .find((btn) => btn.text().includes('Rotate Password'))
    expect(rotateBtn).toBeDefined()
    await rotateBtn!.trigger('click')

    const dialog = wrapper.find('[role="dialog"]')
    expect(dialog.exists()).toBe(true)
    expect(dialog.text()).toContain('Rotate Account Password')

    const passwordInputs = dialog.findAll('input[type="password"]')
    expect(passwordInputs.length).toBe(3)
    await passwordInputs[0]!.setValue('CurrentPass!1')
    await passwordInputs[1]!.setValue('StrongerPass!99')
    await passwordInputs[2]!.setValue('StrongerPass!99')

    await dialog.find('form').trigger('submit')

    expect(wrapper.text()).toContain('Session credentials rotated and active tokens refreshed.')
  })
})
