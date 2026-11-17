import { ref, type Ref } from 'vue'
import { useAuditLogs, usePlatformConfig } from '@/features/settings'
import { SEED_DRIVERS } from '@/features/users/data/users.seed'
import type { DriverRecord, DriverStatus, UserActionResult } from '@/features/users/types'

function cloneDrivers(source: readonly DriverRecord[]): DriverRecord[] {
  return source.map((item) => ({ ...item }))
}

const drivers: Ref<DriverRecord[]> = ref(cloneDrivers(SEED_DRIVERS))

export function resetDriversForTesting(): void {
  drivers.value = cloneDrivers(SEED_DRIVERS)
}

export function useDrivers() {
  const { config } = usePlatformConfig()
  const { appendAuditLog } = useAuditLogs()

  function isLowBalanceDriver(driver: DriverRecord): boolean {
    if (!config.value.autoLockLowBalanceDispatch) return false
    return driver.walletBalanceCentavos < config.value.minWalletBalanceCentavos
  }

  function getEffectiveDriverStatus(driver: DriverRecord): DriverStatus {
    if (driver.status === 'Suspended') return 'Suspended'
    if (isLowBalanceDriver(driver)) return 'Low Balance (Locked)'
    return 'Active'
  }

  function suspendDriver(id: string, reason: string): UserActionResult {
    const trimmed = reason.trim()
    if (!trimmed) {
      return { ok: false, error: 'Suspension reason is required.' }
    }

    const target = drivers.value.find((driver) => driver.id === id)
    if (!target) {
      return { ok: false, error: `Driver ${id} was not found.` }
    }
    if (target.status === 'Suspended') {
      return { ok: false, error: `Driver ${target.name} is already suspended.` }
    }

    target.status = 'Suspended'
    target.suspensionReason = trimmed

    appendAuditLog({
      action: 'DRIVER_SUSPENDED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { reason: trimmed },
      severity: 'Warning',
    })

    return {
      ok: true,
      message: `${target.name} suspended from receiving new dispatches.`,
    }
  }

  function reactivateDriver(id: string): UserActionResult {
    const target = drivers.value.find((driver) => driver.id === id)
    if (!target) {
      return { ok: false, error: `Driver ${id} was not found.` }
    }
    if (target.status !== 'Suspended') {
      return { ok: false, error: `Driver ${target.name} is not suspended.` }
    }

    target.status = isLowBalanceDriver(target) ? 'Low Balance (Locked)' : 'Active'
    target.suspensionReason = undefined

    appendAuditLog({
      action: 'DRIVER_REACTIVATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { restoredStatus: target.status },
      severity: 'Info',
    })

    return {
      ok: true,
      message: `${target.name} restored to ${target.status} dispatch standing.`,
    }
  }

  return {
    drivers,
    isLowBalanceDriver,
    getEffectiveDriverStatus,
    suspendDriver,
    reactivateDriver,
  }
}
