import { beforeEach, describe, expect, it } from 'vitest'
import { loginOperator } from '@/core'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import {
  resetUsersForTesting,
  useDriverApplications,
  useDrivers,
  useOperators,
  useRiders,
  useRoles,
} from '@/features/users'

describe('features/users domain & composables', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetUsersForTesting()
  })

  it('prevents plate number collisions between pending applicants and active fleet drivers', () => {
    const { applications } = useDriverApplications()
    const { drivers } = useDrivers()

    const app901 = applications.value.find((item) => item.id === 'APP-901')
    const drv101 = drivers.value.find((item) => item.id === 'DRV-101')
    expect(app901?.vehicle.plate).toBe('6184-ND')
    expect(drv101?.vehicle).toContain('1284-ND')

    const extractPlate = (vehicleText: string) =>
      /Plate:\s*([A-Z0-9-]+)/i.exec(vehicleText)?.[1] ?? ''
    const activePlates = new Set(drivers.value.map((d) => extractPlate(d.vehicle)).filter(Boolean))
    const pendingPlates = applications.value
      .filter((app) => app.status === 'Pending Review')
      .map((app) => app.vehicle.plate)

    for (const plate of pendingPlates) {
      expect(activePlates.has(plate)).toBe(false)
    }
  })

  it('enforces pending-only transitions and audit trails for driver applications', () => {
    loginOperator('fleet', '7016')
    const { applications, approveApplication, rejectApplication } = useDriverApplications()
    const { logs } = useAuditLogs()

    const approveOk = approveApplication('APP-901')
    expect(approveOk.ok).toBe(true)
    expect(applications.value.find((a) => a.id === 'APP-901')?.status).toBe('Approved')
    expect(logs.value[0]?.action).toBe('DRIVER_APPLICATION_APPROVED')
    expect(logs.value[0]?.actor).toBe('Ramon Villanueva')

    const doubleApprove = approveApplication('APP-901')
    expect(doubleApprove.ok).toBe(false)

    const blankReject = rejectApplication('APP-902', '  ')
    expect(blankReject.ok).toBe(false)

    const rejectOk = rejectApplication('APP-902', 'Expired LTO Official Receipt')
    expect(rejectOk.ok).toBe(true)
    expect(applications.value.find((a) => a.id === 'APP-902')?.status).toBe('Rejected')
    expect(logs.value[0]?.action).toBe('DRIVER_APPLICATION_REJECTED')
  })

  it('tracks integer centavo wallets against live platform threshold and logs driver suspensions', () => {
    const { config, commitConfig } = usePlatformConfig()
    const { drivers, isLowBalanceDriver, suspendDriver, reactivateDriver } = useDrivers()
    const { logs } = useAuditLogs()

    expect(Number.isInteger(drivers.value[0]?.walletBalanceCentavos)).toBe(true)
    commitConfig({ ...config.value, minWalletBalanceCentavos: 20000 }, 'Test reserve floor.')
    const drv101 = drivers.value.find((d) => d.id === 'DRV-101')!
    const drv102 = drivers.value.find((d) => d.id === 'DRV-102')!
    expect(isLowBalanceDriver(drv101)).toBe(false)
    expect(isLowBalanceDriver(drv102)).toBe(true)

    expect(suspendDriver('DRV-101', '').ok).toBe(false)
    expect(suspendDriver('DRV-101', 'Repeated dispatch declines').ok).toBe(true)
    expect(drivers.value.find((d) => d.id === 'DRV-101')?.status).toBe('Suspended')
    expect(logs.value[0]?.action).toBe('DRIVER_SUSPENDED')

    expect(reactivateDriver('DRV-101').ok).toBe(true)
    expect(logs.value[0]?.action).toBe('DRIVER_REACTIVATED')
  })

  it('stores rider spend in integer centavos and enforces suspension reason', () => {
    const { riders, suspendRider, reinstateRider } = useRiders()
    const { logs } = useAuditLogs()

    expect(Number.isInteger(riders.value[0]?.lifetimeSpendCentavos)).toBe(true)
    expect(suspendRider('RDR-201', '   ').ok).toBe(false)

    expect(suspendRider('RDR-201', 'Verified payment chargeback').ok).toBe(true)
    expect(riders.value.find((r) => r.id === 'RDR-201')?.standing).toBe('Suspended')
    expect(logs.value[0]?.action).toBe('RIDER_SUSPENDED')

    expect(reinstateRider('RDR-201').ok).toBe(true)
    expect(riders.value.find((r) => r.id === 'RDR-201')?.standing).toBe('Good Standing')
    expect(logs.value[0]?.action).toBe('RIDER_REINSTATED')
  })

  it('protects root operator account and records RBAC/operator audit events', () => {
    const { operators, updateOperatorRole, toggleOperatorMfa, inviteOperator, suspendOperator } =
      useOperators()
    const { roles, saveRole } = useRoles()
    const { logs } = useAuditLogs()

    const rootUpdate = updateOperatorRole('ADM-001', 'Support')
    expect(rootUpdate.ok).toBe(false)
    const rootSuspend = suspendOperator('ADM-001')
    expect(rootSuspend.ok).toBe(false)

    const invite = inviteOperator({
      name: 'Marco Dizon',
      email: 'marco.dizon@pagadian.ph',
      role: 'Support',
    })
    expect(invite.ok).toBe(true)
    expect(operators.value.some((op) => op.email === 'marco.dizon@pagadian.ph')).toBe(true)
    expect(logs.value[0]?.action).toBe('OPERATOR_INVITED')

    expect(toggleOperatorMfa('ADM-002').ok).toBe(true)
    expect(logs.value[0]?.action).toBe('OPERATOR_MFA_UPDATED')

    const saved = saveRole({
      name: 'Night Shift Dispatch',
      description: 'Monitor overnight trips',
      scopes: ['view:overview', 'view:trips'],
    })
    expect(saved.ok).toBe(true)
    expect(roles.value.some((role) => role.name === 'Night Shift Dispatch')).toBe(true)
    expect(logs.value[0]?.action).toBe('RBAC_ROLE_CREATED')
  })
})
