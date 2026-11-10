import { computed, onMounted, ref } from 'vue'
import { fetchDashboardMetricSummary } from '@/features/dashboard/api/dashboard.api'
import type { DashboardMetricSummary } from '@/features/dashboard/dashboard.types'

export function useDashboard() {
  const metrics = ref<DashboardMetricSummary | null>(null)
  const isPending = ref(false)
  const failure = ref<string | null>(null)

  const hasTelemetry = computed(() => metrics.value !== null)

  async function loadMetrics(): Promise<void> {
    isPending.value = true
    failure.value = null
    try {
      metrics.value = await fetchDashboardMetricSummary()
    } catch (err) {
      failure.value = err instanceof Error ? err.message : 'Unknown error'
    } finally {
      isPending.value = false
    }
  }

  onMounted(() => {
    void loadMetrics()
  })

  return {
    metrics,
    isPending,
    failure,
    hasTelemetry,
    loadMetrics,
  }
}
