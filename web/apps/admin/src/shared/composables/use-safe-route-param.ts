import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { isSafeRouteParam } from '@/core'

export function useSafeRouteParam(paramName = 'id') {
  const route = useRoute()

  return computed<string | null>(() => {
    const raw = (route.params as Record<string, unknown> | undefined)?.[paramName]
    const value = Array.isArray(raw) ? raw[0] : raw
    if (!isSafeRouteParam(value)) {
      return null
    }
    return value as string
  })
}
