export interface DashboardMetricSummary {
  activeRidesCount: number
  onlineDriversCount: number
  totalRevenueCents: number
  systemHealthStatus: 'healthy' | 'degraded' | 'outage'
}

export interface DashboardFilterCriteria {
  dateRange: 'today' | 'week' | 'month'
}
