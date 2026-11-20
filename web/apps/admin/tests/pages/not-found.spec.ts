import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import NotFoundPage from '@/pages/[...path].vue'

const mockBack = vi.fn()
const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({ back: mockBack, push: mockPush }),
  RouterLink: true,
}))

describe('NotFoundPage', () => {
  beforeEach(() => {
    mockBack.mockClear()
    mockPush.mockClear()
    window.history.replaceState(null, '')
  })

  it('renders 404 recovery actions and falls back to overview when no in-app history exists', async () => {
    const wrapper = mount(NotFoundPage)

    expect(wrapper.text()).toContain('Error 404')
    expect(wrapper.text()).toContain('Page Not Found')
    expect(wrapper.find('a[href="/dashboard/overview"]').text()).toContain('Return to Overview')

    const goBackBtn = wrapper.findAll('button').find((button) => button.text().includes('Go Back'))
    expect(goBackBtn).toBeDefined()
    await goBackBtn!.trigger('click')
    expect(mockPush).toHaveBeenCalledWith('/dashboard/overview')
  })

  it('navigates back when in-app history state exists', async () => {
    window.history.replaceState({ back: '/trips/all' }, '')
    const wrapper = mount(NotFoundPage)

    const goBackBtn = wrapper.findAll('button').find((button) => button.text().includes('Go Back'))
    await goBackBtn!.trigger('click')
    expect(mockBack).toHaveBeenCalledOnce()
  })
})
