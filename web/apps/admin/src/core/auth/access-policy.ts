import type { OperatorRole } from '@/core/auth/auth-session'

export interface RoutePolicyRule {
  readonly prefix: string
  readonly roles: readonly OperatorRole[]
}

export const ROUTE_ACCESS_POLICY: readonly RoutePolicyRule[] = [
  { prefix: '/users/operators', roles: ['root_operator'] },
  { prefix: '/users/roles', roles: ['root_operator'] },
  { prefix: '/settings/content', roles: ['root_operator'] },
  { prefix: '/settings/app-settings', roles: ['root_operator'] },
  { prefix: '/settings/audit-logs', roles: ['root_operator'] },
  { prefix: '/settings/service-zones', roles: ['root_operator', 'fleet_ops'] },
  { prefix: '/settings/cities', roles: ['root_operator', 'fleet_ops'] },
  { prefix: '/documents', roles: ['root_operator', 'fleet_ops'] },
  { prefix: '/payments/refunds', roles: ['root_operator', 'finance_ops', 'support_lead'] },
  { prefix: '/payments', roles: ['root_operator', 'finance_ops'] },
  { prefix: '/trips', roles: ['root_operator', 'fleet_ops', 'support_lead'] },
  { prefix: '/users', roles: ['root_operator', 'fleet_ops', 'support_lead'] },
  { prefix: '/support', roles: ['root_operator', 'support_lead', 'fleet_ops'] },
  {
    prefix: '/reports',
    roles: ['root_operator', 'fleet_ops', 'finance_ops', 'support_lead'],
  },
  {
    prefix: '/dashboard',
    roles: ['root_operator', 'fleet_ops', 'finance_ops', 'support_lead'],
  },
  {
    prefix: '/account',
    roles: ['root_operator', 'fleet_ops', 'finance_ops', 'support_lead'],
  },
]

const SAFE_PARAM_PATTERN = /^[A-Za-z0-9_-]{3,48}$/
const CONTROL_CHAR_PATTERN = /[\u0000-\u001F\u007F]/

export function sanitizeRedirectPath(candidate: unknown, fallback = '/dashboard/overview'): string {
  if (typeof candidate !== 'string') return fallback
  const trimmed = candidate.trim()
  if (!trimmed || CONTROL_CHAR_PATTERN.test(trimmed)) return fallback
  if (!trimmed.startsWith('/') || trimmed.startsWith('//') || trimmed.startsWith('/\\')) {
    return fallback
  }
  const lower = trimmed.toLowerCase()
  if (
    lower.includes('://') ||
    lower.startsWith('/auth/login') ||
    lower.startsWith('/unauthorized')
  ) {
    return fallback
  }
  return trimmed
}

export function isSafeRouteParam(value: unknown): boolean {
  if (typeof value !== 'string') return false
  return SAFE_PARAM_PATTERN.test(value)
}

export function getAllowedRolesForPath(
  path: string,
  routeAllowedRoles?: readonly OperatorRole[],
): readonly OperatorRole[] {
  if (Array.isArray(routeAllowedRoles) && routeAllowedRoles.length > 0) {
    return routeAllowedRoles
  }

  const normalized = (path.split('?')[0] ?? '').replace(/\/+$/, '') || '/'
  const matchedRule = ROUTE_ACCESS_POLICY.find(
    (rule) => normalized === rule.prefix || normalized.startsWith(`${rule.prefix}/`),
  )
  if (matchedRule) {
    return matchedRule.roles
  }

  return ['root_operator']
}

export function canRoleAccessPath(
  role: OperatorRole | null | undefined,
  path: string,
  routeAllowedRoles?: readonly OperatorRole[],
): boolean {
  if (!role) return false
  const allowed = getAllowedRolesForPath(path, routeAllowedRoles)
  return allowed.includes(role)
}
