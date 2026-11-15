import { describe, expect, it } from 'vitest'
import { canRoleAccessPath, ROUTE_ACCESS_POLICY } from '@/core'

describe('route access policy', () => {
  it('enforces single-source role access decisions across operational prefixes', () => {
    expect(ROUTE_ACCESS_POLICY.some((rule) => rule.prefix === '/payments')).toBe(true)

    expect(canRoleAccessPath('admin', '/settings/app-settings')).toBe(true)
    expect(canRoleAccessPath('finance', '/payments/topups')).toBe(true)
    expect(canRoleAccessPath('finance', '/users/operators')).toBe(false)
    expect(canRoleAccessPath('fleet', '/documents/verification')).toBe(true)
    expect(canRoleAccessPath('fleet', '/payments/settlements')).toBe(false)
    expect(canRoleAccessPath('support', '/support/tickets')).toBe(true)
    expect(canRoleAccessPath('support', '/settings/cities')).toBe(false)
  })
})
