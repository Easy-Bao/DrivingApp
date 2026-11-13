import { useRouter } from 'vue-router'

export function useSafeBack(fallbackPath: string) {
  const router = useRouter()

  return function goBack() {
    if (typeof window !== 'undefined' && window.history.state && window.history.state.back) {
      router.back()
      return
    }
    void router.push(fallbackPath)
  }
}
