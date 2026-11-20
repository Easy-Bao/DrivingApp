import { onBeforeUnmount, ref } from 'vue'

export function useClipboardCopy(successLabel = 'Copied to clipboard', durationMs = 2000) {
  const copied = ref(false)
  const toastMessage = ref<string | null>(null)
  let resetTimer: ReturnType<typeof setTimeout> | null = null

  const clear = () => {
    if (resetTimer !== null) {
      clearTimeout(resetTimer)
      resetTimer = null
    }
    copied.value = false
    toastMessage.value = null
  }

  async function copy(value: string) {
    try {
      if (typeof navigator !== 'undefined' && navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(value)
      }
    } catch {
      // Ignore clipboard restrictions in non-secure browser or test contexts.
    }

    copied.value = true
    toastMessage.value = successLabel
    if (resetTimer !== null) {
      clearTimeout(resetTimer)
    }
    resetTimer = setTimeout(() => {
      copied.value = false
      toastMessage.value = null
      resetTimer = null
    }, durationMs)
  }

  onBeforeUnmount(clear)

  return { copied, toastMessage, copy, clear }
}
