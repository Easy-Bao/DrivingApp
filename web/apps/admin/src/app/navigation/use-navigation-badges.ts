import { computed } from 'vue'
import { useExpiringDocuments, useVerificationDocuments } from '@/features/documents'
import { useSettlements, useTopups } from '@/features/payments'
import { useSupportTickets } from '@/features/support'
import { useSafetyReports, useSosAlerts } from '@/features/trips'
import { useDriverApplications } from '@/features/users'

function formatPositiveCount(count: number): string | undefined {
  return count > 0 ? String(count) : undefined
}

export function useNavigationBadges() {
  const { applications } = useDriverApplications()
  const { pendingDocs } = useVerificationDocuments()
  const { expiringDocs } = useExpiringDocuments()
  const { pendingTopups } = useTopups()
  const { pendingSettlements } = useSettlements()
  const { openTicketCount } = useSupportTickets()
  const { activeAlertsCount } = useSosAlerts()
  const { openReportCount } = useSafetyReports()

  const dynamicBadges = computed<Record<string, string | undefined>>(() => {
    const pendingApplicationsCount = applications.value.filter(
      (application) => application.status === 'Pending Review',
    ).length

    return {
      'driver-applications': formatPositiveCount(pendingApplicationsCount),
      'document-verification': formatPositiveCount(pendingDocs.value.length),
      'expiring-documents': formatPositiveCount(expiringDocs.value.length),
      'sos-alerts': formatPositiveCount(activeAlertsCount.value),
      'safety-reports': formatPositiveCount(openReportCount.value),
      topups: formatPositiveCount(pendingTopups.value.length),
      settlements: formatPositiveCount(pendingSettlements.value.length),
      'tickets-complaints': formatPositiveCount(openTicketCount.value),
    }
  })

  return { dynamicBadges }
}
