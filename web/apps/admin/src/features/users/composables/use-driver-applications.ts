import { ref, type Ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import { SEED_DRIVER_APPLICATIONS } from '@/features/users/data/users.seed'
import type { DriverApplication, UserActionResult } from '@/features/users/types'

function cloneApplications(source: readonly DriverApplication[]): DriverApplication[] {
  return source.map((item) => ({
    ...item,
    vehicle: { ...item.vehicle },
  }))
}

const applications: Ref<DriverApplication[]> = ref(cloneApplications(SEED_DRIVER_APPLICATIONS))

export function resetDriverApplicationsForTesting(): void {
  applications.value = cloneApplications(SEED_DRIVER_APPLICATIONS)
}

export function useDriverApplications() {
  const { appendAuditLog } = useAuditLogs()

  function getApplicationById(id: string): DriverApplication | undefined {
    return applications.value.find((app) => app.id === id)
  }

  function approveApplication(id: string): UserActionResult {
    const target = getApplicationById(id)
    if (!target) {
      return { ok: false, error: `Application ${id} was not found.` }
    }
    if (target.status !== 'Pending Review') {
      return {
        ok: false,
        error: `Application ${target.id} is already ${target.status.toLowerCase()}.`,
      }
    }

    target.status = 'Approved'
    target.rejectionReason = undefined

    appendAuditLog({
      action: 'DRIVER_APPLICATION_APPROVED',
      targetEntity: `${target.id} · ${target.applicant}`,
      payload: {
        plate: target.vehicle.plate,
        model: `${target.vehicle.year} ${target.vehicle.make} ${target.vehicle.model}`,
      },
      severity: 'Info',
    })

    return {
      ok: true,
      message: `${target.id} approved. Driver account for ${target.applicant} is now active.`,
    }
  }

  function rejectApplication(id: string, reason: string): UserActionResult {
    const trimmed = reason.trim()
    if (!trimmed) {
      return { ok: false, error: 'Rejection reason is required.' }
    }

    const target = getApplicationById(id)
    if (!target) {
      return { ok: false, error: `Application ${id} was not found.` }
    }
    if (target.status !== 'Pending Review') {
      return {
        ok: false,
        error: `Application ${target.id} is already ${target.status.toLowerCase()}.`,
      }
    }

    target.status = 'Rejected'
    target.rejectionReason = trimmed

    appendAuditLog({
      action: 'DRIVER_APPLICATION_REJECTED',
      targetEntity: `${target.id} · ${target.applicant}`,
      payload: { reason: trimmed },
      severity: 'Warning',
    })

    return {
      ok: true,
      message: `${target.id} rejected (${trimmed}).`,
    }
  }

  return {
    applications,
    getApplicationById,
    approveApplication,
    rejectApplication,
  }
}
