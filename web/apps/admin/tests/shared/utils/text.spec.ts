import { describe, expect, it } from 'vitest'
import { getInitials } from '@/shared'

describe('getInitials', () => {
  it('derives two-letter uppercase initials from full names and single tokens', () => {
    expect(getInitials('System Admin')).toBe('SA')
    expect(getInitials('Clarisse Mendoza')).toBe('CM')
    expect(getInitials('Ramon')).toBe('RA')
    expect(getInitials('  ')).toBe('OP')
    expect(getInitials('', 'AD')).toBe('AD')
  })
})
