import { defineComponent, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { useSafeBack } from '@/shared/composables/use-safe-back'
import { useSafeRouteParam } from '@/shared/composables/use-safe-route-param'

const mockBack = vi.fn()
const mockPush = vi.fn()
const mockRoute = reactive<{ params: Record<string, unknown> }>({
  params: { id: 'TOP-8921' },
})

vi.mock('vue-router', () => ({
  useRouter: () => ({ back: mockBack, push: mockPush }),
  useRoute: () => mockRoute,
}))

describe('route navigation composables', () => {
  beforeEach(() => {
    mockBack.mockClear()
    mockPush.mockClear()
    mockRoute.params = { id: 'TOP-8921' }
    window.history.replaceState(null, '', '/')
  })

  it('uses fallback push when no history back state exists and router.back otherwise', () => {
    const Harness = defineComponent({
      setup() {
        const goBack = useSafeBack('/payments/topups')
        return { goBack }
      },
      template: '<button type="button" @click="goBack">Back</button>',
    })

    const wrapper = mount(Harness)
    void wrapper.find('button').trigger('click')
    expect(mockPush).toHaveBeenCalledWith('/payments/topups')
    expect(mockBack).not.toHaveBeenCalled()

    window.history.replaceState({ back: '/payments/topups' }, '', '/')
    void wrapper.find('button').trigger('click')
    expect(mockBack).toHaveBeenCalledOnce()
  })

  it('validates dynamic route parameters and rejects unsafe traversal tokens', () => {
    const Harness = defineComponent({
      setup() {
        const safeId = useSafeRouteParam('id')
        return { safeId }
      },
      template: '<div>{{ safeId ?? "INVALID" }}</div>',
    })

    const wrapper = mount(Harness)
    expect(wrapper.text()).toBe('TOP-8921')

    mockRoute.params = { id: '../secret' }
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.text()).toBe('INVALID')
    })
  })
})
