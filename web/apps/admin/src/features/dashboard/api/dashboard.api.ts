import type { DashboardMetricSummary } from '@/features/dashboard/dashboard.types'

export async function fetchDashboardMetricSummary(): Promise<DashboardMetricSummary> {
  return {
    activeRidesCount: 142,
    onlineDriversCount: 1280,
    totalRevenueCents: 8945000,
    systemHealthStatus: 'healthy',
  }
}
