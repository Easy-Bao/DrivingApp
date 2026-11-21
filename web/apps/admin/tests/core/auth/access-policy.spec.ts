import { describe, expect, it } from 'vitest'
import { canRoleAccessPath, ROUTE_ACCESS_POLICY } from '@/core'

describe('route access policy', () => {
  it('enforces single-source role access decisions across operational, configuration, and governance prefixes', () => {
    expect(ROUTE_ACCESS_POLICY.some((rule) => rule.prefix === '/payments')).toBe(true)
    expect(ROUTE_ACCESS_POLICY.some((rule) => rule.prefix === '/config/fare-pricing')).toBe(true)

    expect(canRoleAccessPath('admin', '/config/app-system')).toBe(true)
    expect(canRoleAccessPath('admin', '/admin/audit-logs')).toBe(true)

    expect(canRoleAccessPath('finance', '/payments/topups')).toBe(true)
    expect(canRoleAccessPath('finance', '/config/fare-pricing')).toBe(true)
    expect(canRoleAccessPath('finance', '/config/wallet-rules')).toBe(true)
    expect(canRoleAccessPath('finance', '/config/dispatch-policy')).toBe(false)
    expect(canRoleAccessPath('finance', '/admin/operators')).toBe(false)

    expect(canRoleAccessPath('fleet', '/documents/verification')).toBe(true)
    expect(canRoleAccessPath('fleet', '/config/dispatch-policy')).toBe(true)
    expect(canRoleAccessPath('fleet', '/config/vehicle-classes')).toBe(true)
    expect(canRoleAccessPath('fleet', '/config/document-rules')).toBe(true)
    expect(canRoleAccessPath('fleet', '/payments/settlements')).toBe(false)
    expect(canRoleAccessPath('fleet', '/config/fare-pricing')).toBe(false)

    expect(canRoleAccessPath('support', '/support/tickets')).toBe(true)
    expect(canRoleAccessPath('support', '/config/safety-sos')).toBe(true)
    expect(canRoleAccessPath('support', '/config/help-center')).toBe(true)
    expect(canRoleAccessPath('support', '/config/cities')).toBe(false)
    expect(canRoleAccessPath('support', '/config/app-system')).toBe(false)
  })
})
