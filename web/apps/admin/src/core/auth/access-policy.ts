import type { OperatorRole } from '@/core/auth/auth-session'

export interface RoutePolicyRule {
  readonly prefix: string
  readonly roles: readonly OperatorRole[]
}

export const ROUTE_ACCESS_POLICY: readonly RoutePolicyRule[] = [
  // Administration / Governance
  { prefix: '/admin', roles: ['admin'] },
  { prefix: '/users/operators', roles: ['admin'] },
  { prefix: '/users/roles', roles: ['admin'] },

  // Independent Configuration modules (scoped by operational role)
  { prefix: '/config/fare-pricing', roles: ['admin', 'finance'] },
  { prefix: '/config/commissions', roles: ['admin', 'finance'] },
  { prefix: '/config/wallet-rules', roles: ['admin', 'finance'] },
  { prefix: '/config/payment-channels', roles: ['admin', 'finance'] },
  { prefix: '/config/dispatch-policy', roles: ['admin', 'fleet'] },
  { prefix: '/config/service-zones', roles: ['admin', 'fleet'] },
  { prefix: '/config/cities', roles: ['admin', 'fleet'] },
  { prefix: '/config/vehicle-classes', roles: ['admin', 'fleet'] },
  { prefix: '/config/document-rules', roles: ['admin', 'fleet'] },
  { prefix: '/config/safety-sos', roles: ['admin', 'fleet', 'support'] },
  { prefix: '/config/help-center', roles: ['admin', 'support', 'fleet'] },
  { prefix: '/config/legal-policies', roles: ['admin'] },
  { prefix: '/config/app-system', roles: ['admin'] },
  { prefix: '/config', roles: ['admin'] },

  // Legacy /settings/* prefixes (aligned with moved destinations)
  { prefix: '/settings/service-zones', roles: ['admin', 'fleet'] },
  { prefix: '/settings/cities', roles: ['admin', 'fleet'] },
  { prefix: '/settings', roles: ['admin'] },

  // Daily Operations
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
