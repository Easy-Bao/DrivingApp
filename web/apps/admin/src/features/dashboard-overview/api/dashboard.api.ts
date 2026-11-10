import type { DashboardMetricSummary } from '@/features/dashboard-overview/types'

export async function fetchDashboardMetricSummary(): Promise<DashboardMetricSummary> {
  return {
    activeRidesCount: 0,
    onlineDriversCount: 0,
    totalRevenueCents: 0,
    systemHealthStatus: 'healthy',
  }
}
