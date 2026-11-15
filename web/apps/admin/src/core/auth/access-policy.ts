import type { OperatorRole } from '@/core/auth/auth-session'

export interface RoutePolicyRule {
  readonly prefix: string
  readonly roles: readonly OperatorRole[]
}

export const ROUTE_ACCESS_POLICY: readonly RoutePolicyRule[] = [
  { prefix: '/users/operators', roles: ['admin'] },
  { prefix: '/users/roles', roles: ['admin'] },
  { prefix: '/settings/content', roles: ['admin'] },
  { prefix: '/settings/app-settings', roles: ['admin'] },
  { prefix: '/settings/audit-logs', roles: ['admin'] },
  { prefix: '/settings/service-zones', roles: ['admin', 'fleet'] },
  { prefix: '/settings/cities', roles: ['admin', 'fleet'] },
  { prefix: '/documents', roles: ['admin', 'fleet'] },
  { prefix: '/payments/refunds', roles: ['admin', 'finance', 'support'] },
  { prefix: '/payments', roles: ['admin', 'finance'] },
  { prefix: '/trips', roles: ['admin', 'fleet', 'support'] },
  { prefix: '/users', roles: ['admin', 'fleet', 'support'] },
  { prefix: '/support', roles: ['admin', 'support', 'fleet'] },
  {
    prefix: '/reports',
    roles: ['admin', 'fleet', 'finance', 'support'],
  },
  {
    prefix: '/dashboard',
    roles: ['admin', 'fleet', 'finance', 'support'],
  },
  {
    prefix: '/account',
    roles: ['admin', 'fleet', 'finance', 'support'],
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

  return ['admin']
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
