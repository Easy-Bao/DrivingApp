import { onBeforeUnmount, toValue, watch, type MaybeRefOrGetter } from 'vue'

export function useEscapeKey(enabled: MaybeRefOrGetter<boolean>, onEscape: () => void): void {
  const handleKeydown = (event: KeyboardEvent) => {
    if (event.key === 'Escape' && toValue(enabled)) {
      onEscape()
    }
  }

  const detach = () => {
    if (typeof window !== 'undefined') {
      window.removeEventListener('keydown', handleKeydown)
    }
  }

  watch(
    () => toValue(enabled),
    (isEnabled) => {
      if (typeof window === 'undefined') return
      if (isEnabled) {
        window.addEventListener('keydown', handleKeydown)
      } else {
        detach()
      }
    },
    { immediate: true },
  )

  onBeforeUnmount(detach)
}
