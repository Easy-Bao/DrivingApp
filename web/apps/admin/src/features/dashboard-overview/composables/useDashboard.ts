import { ref } from 'vue'
import { fetchDashboardMetricSummary } from '@/features/dashboard-overview/api/dashboard.api'
import type { DashboardMetricSummary } from '@/features/dashboard-overview/types'

export function useDashboard() {
  const isLoading = ref(false)
  const metrics = ref<DashboardMetricSummary | null>(null)

  async function loadMetrics() {
    isLoading.value = true
    try {
      metrics.value = await fetchDashboardMetricSummary()
    } finally {
      isLoading.value = false
    }
  }

  return {
    isLoading,
    metrics,
    loadMetrics,
  }
}
