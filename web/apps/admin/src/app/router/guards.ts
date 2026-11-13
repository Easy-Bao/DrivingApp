import type { RouteLocationNormalized, RouteLocationRaw, Router } from 'vue-router'
import { getAuthSession, isSessionAuthenticated, type AdminRole } from '@/core/auth/auth-session'

interface RoutePolicyRule {
  prefix: string
  roles: readonly AdminRole[]
}

const ROUTE_ACCESS_POLICY: readonly RoutePolicyRule[] = [
  { prefix: '/users/admin-users', roles: ['super_admin'] },
  { prefix: '/users/roles', roles: ['super_admin'] },
  { prefix: '/settings/content', roles: ['super_admin'] },
  { prefix: '/settings/app-settings', roles: ['super_admin'] },
  { prefix: '/settings/audit-logs', roles: ['super_admin'] },
  { prefix: '/settings/service-zones', roles: ['super_admin', 'fleet_ops'] },
  { prefix: '/settings/cities', roles: ['super_admin', 'fleet_ops'] },
  { prefix: '/documents', roles: ['super_admin', 'fleet_ops'] },
  { prefix: '/payments/refunds', roles: ['super_admin', 'finance_admin', 'support_lead'] },
  { prefix: '/payments', roles: ['super_admin', 'finance_admin'] },
  { prefix: '/trips', roles: ['super_admin', 'fleet_ops', 'support_lead'] },
  { prefix: '/users', roles: ['super_admin', 'fleet_ops', 'support_lead'] },
  { prefix: '/support', roles: ['super_admin', 'support_lead', 'fleet_ops'] },
  {
    prefix: '/reports',
    roles: ['super_admin', 'fleet_ops', 'finance_admin', 'support_lead'],
  },
  {
    prefix: '/dashboard',
    roles: ['super_admin', 'fleet_ops', 'finance_admin', 'support_lead'],
  },
  {
    prefix: '/account',
    roles: ['super_admin', 'fleet_ops', 'finance_admin', 'support_lead'],
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

function validateDynamicParams(to: Pick<RouteLocationNormalized, 'params' | 'name'>): boolean {
  if (to.name === 'not-found' || !to.params) return true
  for (const [key, rawValue] of Object.entries(to.params)) {
    if (key === 'pathMatch') continue
    if (Array.isArray(rawValue)) return false
    if (!isSafeRouteParam(rawValue)) return false
  }
  return true
}

export function getAllowedRolesForRoute(
  to: Pick<RouteLocationNormalized, 'path' | 'matched' | 'meta' | 'name'>,
): readonly AdminRole[] {
  const metaRoles = to.meta?.allowedRoles as readonly AdminRole[] | undefined
  if (Array.isArray(metaRoles) && metaRoles.length > 0) {
    return metaRoles
  }

  for (const matched of to.matched) {
    const recordRoles = matched.meta?.allowedRoles as readonly AdminRole[] | undefined
    if (Array.isArray(recordRoles) && recordRoles.length > 0) {
      return recordRoles
    }
  }

  const matchedRule = ROUTE_ACCESS_POLICY.find(
    (rule) => to.path === rule.prefix || to.path.startsWith(`${rule.prefix}/`),
  )
  if (matchedRule) {
    return matchedRule.roles
  }

  return ['super_admin']
}

export function enforceRouteSecurity(to: RouteLocationNormalized): RouteLocationRaw | true {
  if (!validateDynamicParams(to)) {
    return { name: 'not-found' }
  }

  const isPublic =
    to.matched.some((record) => record.meta?.public === true) || to.meta?.public === true
  const authenticated = isSessionAuthenticated()

  if (!isPublic && !authenticated) {
    return {
      name: 'auth-login',
      query: { redirect: sanitizeRedirectPath(to.fullPath) },
    }
  }

  if (to.name === 'auth-login' && authenticated) {
    return sanitizeRedirectPath(to.query?.redirect)
  }

  if (isPublic || to.name === 'not-found' || to.name === 'unauthorized') {
    return true
  }

  const session = getAuthSession()
  const allowedRoles = getAllowedRolesForRoute(to)
  if (!session.role || !allowedRoles.includes(session.role)) {
    return {
      name: 'unauthorized',
      query: {
        from: sanitizeRedirectPath(to.path),
        required: allowedRoles.join(','),
      },
    }
  }

  return true
}

export function installRouterSecurityGuards(router: Router): void {
  router.beforeEach((to) => enforceRouteSecurity(to))
}
