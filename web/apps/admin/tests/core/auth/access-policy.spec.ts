import { describe, expect, it } from 'vitest'
import { canRoleAccessPath, ROUTE_ACCESS_POLICY } from '@/core'

describe('route access policy', () => {
  it('enforces single-source role access decisions across operational prefixes', () => {
    expect(ROUTE_ACCESS_POLICY.some((rule) => rule.prefix === '/payments')).toBe(true)

    expect(canRoleAccessPath('root_operator', '/settings/app-settings')).toBe(true)
    expect(canRoleAccessPath('finance_ops', '/payments/topups')).toBe(true)
    expect(canRoleAccessPath('finance_ops', '/users/operators')).toBe(false)
    expect(canRoleAccessPath('fleet_ops', '/documents/verification')).toBe(true)
    expect(canRoleAccessPath('fleet_ops', '/payments/settlements')).toBe(false)
    expect(canRoleAccessPath('support_lead', '/support/tickets')).toBe(true)
    expect(canRoleAccessPath('support_lead', '/settings/cities')).toBe(false)
  })
})
