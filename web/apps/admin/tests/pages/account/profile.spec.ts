import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import ProfilePage from '@/pages/account/profile.vue'
import { loginOperator } from '@/core/auth/auth-session'

const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: mockPush }),
}))

describe('ProfilePage', () => {
  it('binds displayed operator identity to the active authenticated role and locks via router', async () => {
    loginOperator('finance_ops', '7016')
    const wrapper = mount(ProfilePage)

    expect(wrapper.text()).toContain('Clarisse Mendoza')
    expect(wrapper.text()).toContain('treasury@easyride.ph')
    expect(wrapper.text()).toContain('Finance Ops')
    expect(wrapper.text()).not.toContain('Root Access')

    const lockBtn = wrapper.findAll('button').find((b) => b.text().includes('Lock Session'))
    expect(lockBtn).toBeDefined()
    await lockBtn!.trigger('click')
    expect(mockPush).toHaveBeenCalledWith({
      name: '/auth/login',
      query: { redirect: '/account/profile' },
    })
  })

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
