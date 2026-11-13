import { onBeforeUnmount, ref } from 'vue'

/**
 * Copies text to the clipboard with transient copied state and an auto-dismissing status message.
 */
export function useClipboardCopy(successLabel = 'Copied to clipboard', durationMs = 2000) {
  const copied = ref(false)
  const toastMessage = ref<string | null>(null)
  let timer: ReturnType<typeof setTimeout> | null = null

  const clear = () => {
    if (timer !== null) {
      clearTimeout(timer)
      timer = null
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
    if (timer !== null) {
      clearTimeout(timer)
    }
    timer = setTimeout(() => {
      copied.value = false
      toastMessage.value = null
      timer = null
    }, durationMs)
  }

  onBeforeUnmount(clear)

  return { copied, toastMessage, copy, clear }
}
