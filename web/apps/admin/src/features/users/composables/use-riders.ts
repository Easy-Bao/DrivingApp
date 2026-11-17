import { ref, type Ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import { SEED_RIDERS } from '@/features/users/data/users.seed'
import type { RiderRecord, UserActionResult } from '@/features/users/types'

function cloneRiders(source: readonly RiderRecord[]): RiderRecord[] {
  return source.map((item) => ({ ...item }))
}

const riders: Ref<RiderRecord[]> = ref(cloneRiders(SEED_RIDERS))

export function resetRidersForTesting(): void {
  riders.value = cloneRiders(SEED_RIDERS)
}

export function useRiders() {
  const { appendAuditLog } = useAuditLogs()

  function suspendRider(id: string, reason: string): UserActionResult {
    const trimmed = reason.trim()
    if (!trimmed) {
      return { ok: false, error: 'Suspension reason is required.' }
    }

    const target = riders.value.find((rider) => rider.id === id)
    if (!target) {
      return { ok: false, error: `Rider ${id} was not found.` }
    }
    if (target.standing === 'Suspended') {
      return { ok: false, error: `${target.name} is already suspended.` }
    }

    target.standing = 'Suspended'
    target.notes = `Suspended: ${trimmed}`

    appendAuditLog({
      action: 'RIDER_SUSPENDED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { reason: trimmed },
      severity: 'Warning',
    })

    return {
      ok: true,
      message: `${target.name} suspended from booking new rides.`,
    }
  }

  function reinstateRider(id: string): UserActionResult {
    const target = riders.value.find((rider) => rider.id === id)
    if (!target) {
      return { ok: false, error: `Rider ${id} was not found.` }
    }
    if (target.standing !== 'Suspended') {
      return { ok: false, error: `${target.name} is not suspended.` }
    }

    target.standing = 'Good Standing'
    target.notes = 'Account reinstated after trust and safety verification.'

    appendAuditLog({
      action: 'RIDER_REINSTATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { standing: 'Good Standing' },
      severity: 'Info',
    })

    return {
      ok: true,
      message: `${target.name} restored to Good Standing.`,
    }
  }

  return {
    riders,
    suspendRider,
    reinstateRider,
  }
}
