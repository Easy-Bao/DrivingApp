import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import LoginPage from '@/pages/auth/login.vue'
import { getAuthSession, isSessionAuthenticated, lockAuthSession } from '@/core/auth/auth-session'

const mockReplace = vi.fn()
const mockRoute = reactive({
  query: {} as Record<string, string>,
})

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
  useRouter: () => ({ replace: mockReplace, push: mockReplace }),
}))

describe('LoginPage', () => {
  beforeEach(() => {
    mockReplace.mockClear()
    mockRoute.query = {}
    lockAuthSession()
  })

  it('rejects invalid security PINs and blocks unsafe open redirects on sign in', async () => {
    const wrapper = mount(LoginPage)

    expect(wrapper.text()).toContain('EasyRide Operations')

    const pinInput = wrapper.find('input[placeholder*="4+ digit PIN"]')
    await pinInput.setValue('12')
    await wrapper.find('form').trigger('submit')

    expect(isSessionAuthenticated()).toBe(false)
    expect(mockReplace).not.toHaveBeenCalled()

    mockRoute.query = { redirect: 'https://evil.example/phish' }
    await pinInput.setValue('7016')
    await wrapper.find('form').trigger('submit')

    expect(isSessionAuthenticated()).toBe(true)
    expect(getAuthSession().role).toBe('root_operator')
    expect(mockReplace).toHaveBeenCalledWith('/dashboard/overview')
  })

  it('redirects to validated internal routes after sign in', async () => {
    mockRoute.query = { redirect: '/payments/topups?tab=pending' }
    const wrapper = mount(LoginPage)

    await wrapper.find('input[placeholder*="4+ digit PIN"]').setValue('7016')
    await wrapper.find('form').trigger('submit')

    expect(mockReplace).toHaveBeenCalledWith('/payments/topups?tab=pending')
  })
})
