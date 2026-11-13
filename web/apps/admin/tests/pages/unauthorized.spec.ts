import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import UnauthorizedPage from '@/pages/unauthorized.vue'
import { isSessionAuthenticated, loginOperator } from '@/core/auth/auth-session'

const mockPush = vi.fn()
const mockRoute = reactive({
  query: {
    from: '/settings/app-settings',
    required: 'root_operator,fleet_ops',
  } as Record<string, string>,
})

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
  useRouter: () => ({ push: mockPush }),
  RouterLink: true,
}))

describe('UnauthorizedPage', () => {
  beforeEach(() => {
    mockPush.mockClear()
    mockRoute.query = { from: '/settings/app-settings', required: 'root_operator,fleet_ops' }
    loginOperator('finance_ops', '7016')
  })

  it('displays blocked role labels and locks session when switching role', async () => {
    const wrapper = mount(UnauthorizedPage)

    expect(wrapper.text()).toContain('Restricted Access')
    expect(wrapper.text()).toContain('Finance Ops')
    expect(wrapper.text()).toContain('Root Operator, Fleet Ops')
    expect(wrapper.find('a[href="/dashboard/overview"]').text()).toContain('Overview')

    const switchBtn = wrapper.findAll('button').find((b) => b.text().includes('Switch Role'))
    expect(switchBtn).toBeDefined()
    await switchBtn!.trigger('click')

    expect(isSessionAuthenticated()).toBe(false)
    expect(mockPush).toHaveBeenCalledWith({
      name: '/auth/login',
      query: { redirect: '/settings/app-settings' },
    })
  })
})
