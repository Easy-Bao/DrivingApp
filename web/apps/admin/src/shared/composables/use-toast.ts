import { ref } from 'vue'
import type { ToastTone } from '@/shared/feedback/ToastBanner.vue'

export function useToast(defaultTone: ToastTone = 'info') {
  const message = ref<string | null>(null)
  const tone = ref<ToastTone>(defaultTone)

  function showToast(nextMessage: string, nextTone: ToastTone = defaultTone): void {
    tone.value = nextTone
    message.value = nextMessage
  }

  function dismissToast(): void {
    message.value = null
  }

  return {
    message,
    tone,
    showToast,
    dismissToast,
  }
}
