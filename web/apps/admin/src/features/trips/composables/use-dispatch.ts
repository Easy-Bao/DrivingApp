import { computed, ref } from 'vue'
import { useAuditLogs, usePlatformConfig } from '@/features/settings'
import {
  BASE_SURGE_OPTIONS,
  SEED_BID_SESSIONS,
  SEED_DISPATCH_ZONES,
  SEED_LIVE_DISPATCHES,
} from '@/features/trips/data/trips.seed'
import type {
  BidSession,
  BidSessionStatus,
  DispatchZone,
  LiveDispatchItem,
  TripActionResult,
} from '@/features/trips/types'
import { useDrivers } from '@/features/users'
import type { BadgeTone } from '@/shared'

function cloneBidSessions(source: readonly BidSession[]): BidSession[] {
  return source.map((session) => ({
    ...session,
    offers: session.offers.map((offer) => ({ ...offer })),
  }))
}

function cloneZones(source: readonly DispatchZone[]): DispatchZone[] {
  return source.map((zone) => ({ ...zone }))
}

function cloneLiveDispatches(source: readonly LiveDispatchItem[]): LiveDispatchItem[] {
  return source.map((dispatch) => ({ ...dispatch }))
}

const sessionsRef = ref<BidSession[]>(cloneBidSessions(SEED_BID_SESSIONS))
const zonesRef = ref<DispatchZone[]>(cloneZones(SEED_DISPATCH_ZONES))
const liveDispatchesRef = ref<LiveDispatchItem[]>(cloneLiveDispatches(SEED_LIVE_DISPATCHES))

export function bidSessionStatusTone(status: BidSessionStatus): BadgeTone {
  switch (status) {
    case 'open':
      return 'warning'
    case 'accepted':
      return 'success'
    case 'declined':
    case 'cancelled':
      return 'danger'
    default:
      return 'neutral'
  }
}

export function resetDispatchForTesting() {
  sessionsRef.value = cloneBidSessions(SEED_BID_SESSIONS)
  zonesRef.value = cloneZones(SEED_DISPATCH_ZONES)
  liveDispatchesRef.value = cloneLiveDispatches(SEED_LIVE_DISPATCHES)
}

export function useBiddingSessions() {
  const { appendAuditLog } = useAuditLogs()

  const openSessionCount = computed(
    () => sessionsRef.value.filter((session) => session.status === 'open').length,
  )

  const acceptanceRateLabel = computed(() => {
    const accepted = sessionsRef.value.filter((session) => session.status === 'accepted').length
    if (sessionsRef.value.length === 0) return '0%'
    return `${Math.round((accepted / sessionsRef.value.length) * 100)}%`
  })

  function expireSession(sessionId: string, reason: string): TripActionResult {
    const trimmedReason = reason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'An operator reason is required to expire an open bid session.' }
    }
    const target = sessionsRef.value.find((session) => session.id === sessionId)
    if (!target) {
      return { ok: false, error: `Bid session ${sessionId} not found.` }
    }
    if (target.status !== 'open') {
      return { ok: false, error: `Bid session ${sessionId} is no longer open.` }
    }

    target.status = 'expired'
    target.expiresIn = 'Closed'
    for (const offer of target.offers) {
      if (offer.status === 'pending') {
        offer.status = 'expired'
      }
    }

    appendAuditLog({
      action: 'BID_SESSION_EXPIRED',
      targetEntity: `${target.id} (${target.bookingRef})`,
      severity: 'Warning',
      payload: { reason: trimmedReason, passenger: target.passenger },
    })

    return { ok: true }
  }

  return {
    sessions: sessionsRef,
    openSessionCount,
    acceptanceRateLabel,
    bidSessionStatusTone,
    expireSession,
  }
}

export function useDispatch() {
  const { appendAuditLog } = useAuditLogs()
  const { config } = usePlatformConfig()
  const { drivers } = useDrivers()

  const surgeOptions = computed(() =>
    BASE_SURGE_OPTIONS.filter((label) => {
      const numeric = Number.parseFloat(label.replace(/x$/i, ''))
      return Number.isFinite(numeric) && numeric <= config.value.maxBiddingSurgeCap
    }),
  )

  const availableDrivers = computed(() =>
    drivers.value
      .filter((driver) => driver.status === 'Active')
      .map((driver) => {
        const match = driver.vehicle.match(/Plate:\s*([^)]+)/i)
        return match ? `${driver.name} (${match[1]})` : driver.name
      }),
  )

  function updateZoneSurge(zoneName: string, surge: string): TripActionResult {
    const target = zonesRef.value.find((zone) => zone.name === zoneName)
    if (!target) {
      return { ok: false, error: `Dispatch zone "${zoneName}" not found.` }
    }
    const multiplier = Number.parseFloat(surge.replace(/x$/i, ''))
    if (
      !Number.isFinite(multiplier) ||
      multiplier < 1 ||
      multiplier > config.value.maxBiddingSurgeCap
    ) {
      return {
        ok: false,
        error: `Surge multiplier must stay between 1.0x and configured cap ${config.value.maxBiddingSurgeCap.toFixed(1)}x.`,
      }
    }

    target.surge = surge
    appendAuditLog({
      action: 'DISPATCH_SURGE_UPDATED',
      targetEntity: target.name,
      severity: multiplier >= 1.6 ? 'Warning' : 'Info',
      payload: { surge },
    })
    return { ok: true }
  }

  function assignDispatchDriver(dispatchId: string, driverLabel: string): TripActionResult {
    const trimmedDriver = driverLabel.trim()
    if (!trimmedDriver) {
      return { ok: false, error: 'Select a verified active driver before dispatching.' }
    }
    const target = liveDispatchesRef.value.find((item) => item.id === dispatchId)
    if (!target) {
      return { ok: false, error: `Dispatch ${dispatchId} not found.` }
    }

    target.driver = trimmedDriver
    target.status = 'En Route to Pickup'
    target.eta = '3 mins'

    appendAuditLog({
      action: 'DISPATCH_DRIVER_ASSIGNED',
      targetEntity: target.id,
      severity: 'Info',
      payload: { driver: trimmedDriver, zone: target.zone },
    })
    return { ok: true }
  }

  return {
    zones: zonesRef,
    liveDispatches: liveDispatchesRef,
    surgeOptions,
    availableDrivers,
    updateZoneSurge,
    assignDispatchDriver,
  }
}
