import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import NotFoundPage from '@/pages/[...path].vue'

const mockBack = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({ back: mockBack }),
  RouterLink: true,
}))

describe('NotFoundPage', () => {
  beforeEach(() => {
    mockBack.mockClear()
  })

  it('renders 404 recovery actions and navigates back when requested', async () => {
    const wrapper = mount(NotFoundPage)

    expect(wrapper.text()).toContain('Error 404')
    expect(wrapper.text()).toContain('Page Not Found')
    expect(wrapper.find('a[href="/dashboard/overview"]').text()).toContain('Return to Overview')

    const goBackBtn = wrapper.findAll('button').find((b) => b.text().includes('Go Back'))
    expect(goBackBtn).toBeDefined()
    await goBackBtn!.trigger('click')
    expect(mockBack).toHaveBeenCalledOnce()
  })
})
