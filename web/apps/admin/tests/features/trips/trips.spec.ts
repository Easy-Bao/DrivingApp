import { beforeEach, describe, expect, it } from 'vitest'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import {
  resetTripsForTesting,
  useBiddingSessions,
  useCancellationDisputes,
  useDispatch,
  useSafetyReports,
  useSosAlerts,
  useTrips,
} from '@/features/trips'

describe('trips feature stores & state guards', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetTripsForTesting()
  })

  it('computes dynamic trip completion rate and preserves nullable unassigned fields', () => {
    const { trips, completionRateLabel, averageFareCentavos } = useTrips()
    expect(trips.value.length).toBeGreaterThanOrEqual(10)

    const unassigned = trips.value.find((item) => item.status === 'Dispatching')
    expect(unassigned).toBeDefined()
    expect(unassigned!.driver).toBeNull()
    expect(unassigned!.duration).toBeNull()

    expect(completionRateLabel.value).not.toBe('96.4%')
    expect(Number.isInteger(averageFareCentavos.value)).toBe(true)
  })

  it('requires operator reason to expire open bid sessions and closes pending offers', () => {
    const { sessions, expireSession } = useBiddingSessions()
    const { logs } = useAuditLogs()

    expect(expireSession('BID-3041', '   ').ok).toBe(false)
    expect(expireSession('BID-3040', 'Already accepted').ok).toBe(false)

    const result = expireSession('BID-3041', 'Passenger boarded offline tricycle')
    expect(result.ok).toBe(true)

    const updated = sessions.value.find((item) => item.id === 'BID-3041')!
    expect(updated.status).toBe('expired')
    expect(updated.expiresIn).toBe('Closed')
    expect(updated.offers.every((offer) => offer.status === 'expired')).toBe(true)
    expect(logs.value[0]!.action).toBe('BID_SESSION_EXPIRED')
  })

  it('enforces max surge cap and valid driver assignment in dispatch', () => {
    const { zones, liveDispatches, updateZoneSurge, assignDispatchDriver } = useDispatch()

    expect(updateZoneSurge('Agora Market - Poblacion Core', '3.0x').ok).toBe(false)
    expect(updateZoneSurge('Agora Market - Poblacion Core', '1.6x').ok).toBe(true)
    expect(zones.value[0]!.surge).toBe('1.6x')

    expect(assignDispatchDriver('DSP-7016-883', '   ').ok).toBe(false)
    expect(assignDispatchDriver('DSP-7016-883', 'Rodelio Cruz (1284-ND)').ok).toBe(true)
    const assigned = liveDispatches.value.find((item) => item.id === 'DSP-7016-883')!
    expect(assigned.driver).toBe('Rodelio Cruz (1284-ND)')
    expect(assigned.status).toBe('En Route to Pickup')
  })

  it('enforces investigation notes on disputes, safety reports, and SOS resolutions', () => {
    const { disputes, resolveDispute } = useCancellationDisputes()
    const { reports, moderateReport } = useSafetyReports()
    const { alerts, activeAlertsCount, notifyResponders, resolveAlert } = useSosAlerts()
    const { logs } = useAuditLogs()

    expect(
      resolveDispute('CAN-7016-301', {
        responsibility: 'no_fault',
        waiveFee: true,
        auditNote: '  ',
      }).ok,
    ).toBe(false)
    expect(
      resolveDispute('CAN-7016-301', {
        responsibility: 'no_fault',
        waiveFee: true,
        auditNote: 'Verified junction congestion via telemetry',
      }).ok,
    ).toBe(true)
    expect(disputes.value[0]!.cancellationFeeCentavos).toBe(0)
    expect(disputes.value[0]!.disputeStatus).toBe('Fee Waived & Overridden')

    expect(moderateReport('RPT-7016-409', { status: 'resolved', moderationNote: '' }).ok).toBe(
      false,
    )
    expect(
      moderateReport('RPT-7016-409', {
        status: 'resolved',
        moderationNote: 'Verified TODA ID card in person',
      }).ok,
    ).toBe(true)
    expect(reports.value[0]!.status).toBe('resolved')

    expect(notifyResponders('SOS-7016-104').ok).toBe(true)
    expect(alerts.value[0]!.responderNotified).toBe(true)
    expect(activeAlertsCount.value).toBe(2)
    expect(resolveAlert('SOS-7016-104', '   ').ok).toBe(false)
    expect(resolveAlert('SOS-7016-104', 'Patrol confirmed safe transfer').ok).toBe(true)
    expect(activeAlertsCount.value).toBe(1)
    expect(logs.value[0]!.action).toBe('SOS_ALERT_RESOLVED')

    resetTripsForTesting()
    expect(activeAlertsCount.value).toBe(2)
  })
})
