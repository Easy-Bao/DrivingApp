import { defineComponent, h } from 'vue'
import { config } from '@vue/test-utils'
import { afterEach, beforeEach, vi } from 'vitest'
import { restoreDefaultDemoSession } from '@/core/auth/auth-session'

const RouterLinkStub = defineComponent({
  name: 'RouterLink',
  props: {
    to: {
      type: [String, Object],
      default: '',
    },
  },
  setup(props, { slots }) {
    return () => {
      const href =
        typeof props.to === 'string'
          ? props.to
          : props.to && typeof props.to === 'object' && 'path' in props.to
            ? String(props.to.path ?? '')
            : ''
      return h('a', { href }, slots.default?.())
    }
  },
})

config.global.stubs = {
  Teleport: { template: '<div><slot /></div>' },
  RouterLink: RouterLinkStub,
}

const scrollToSpy = vi.fn()
Object.defineProperty(window, 'scrollTo', {
  value: scrollToSpy,
  writable: true,
  configurable: true,
})

const clipboardWriteText = vi.fn().mockResolvedValue(undefined)
Object.defineProperty(navigator, 'clipboard', {
  value: { writeText: clipboardWriteText },
  writable: true,
  configurable: true,
})

const anchorClickSpy = vi.fn()
Object.defineProperty(HTMLAnchorElement.prototype, 'click', {
  value: anchorClickSpy,
  writable: true,
  configurable: true,
})

beforeEach(() => {
  window.sessionStorage.clear()
  restoreDefaultDemoSession()
  scrollToSpy.mockClear()
  anchorClickSpy.mockClear()
  clipboardWriteText.mockReset()
  clipboardWriteText.mockResolvedValue(undefined)
  Object.defineProperty(navigator, 'clipboard', {
    value: { writeText: clipboardWriteText },
    writable: true,
    configurable: true,
  })
})

afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})
