import type { RouteLocationNormalized, RouteLocationRaw, Router } from 'vue-router'
import {
  getAllowedRolesForPath,
  getAuthSession,
  isSafeRouteParam,
  isSessionAuthenticated,
  sanitizeRedirectPath,
  type OperatorRole,
} from '@/core'

export { isSafeRouteParam, sanitizeRedirectPath }

function validateDynamicParams(to: Pick<RouteLocationNormalized, 'params' | 'name'>): boolean {
  if (to.name === '/[...path]' || !to.params) return true
  for (const [key, rawValue] of Object.entries(to.params)) {
    if (key === 'path') continue
    if (Array.isArray(rawValue)) return false
    if (!isSafeRouteParam(rawValue)) return false
  }
  return true
}

export function getAllowedRolesForRoute(
  to: Pick<RouteLocationNormalized, 'path' | 'matched' | 'meta' | 'name'>,
): readonly OperatorRole[] {
  const metaRoles = to.meta?.allowedRoles as readonly OperatorRole[] | undefined
  if (Array.isArray(metaRoles) && metaRoles.length > 0) {
    return metaRoles
  }

  for (const matched of to.matched) {
    const recordRoles = matched.meta?.allowedRoles as readonly OperatorRole[] | undefined
    if (Array.isArray(recordRoles) && recordRoles.length > 0) {
      return recordRoles
    }
  }

  return getAllowedRolesForPath(to.path)
}

export function enforceRouteSecurity(to: RouteLocationNormalized): RouteLocationRaw | true {
  if (!validateDynamicParams(to)) {
    return { name: '/[...path]', params: { path: to.path.replace(/^\/+/, '') } }
  }

  const isPublic =
    to.matched.some((record) => record.meta?.public === true) || to.meta?.public === true
  const authenticated = isSessionAuthenticated()

  if (!isPublic && !authenticated) {
    return {
      name: '/auth/login',
      query: { redirect: sanitizeRedirectPath(to.fullPath) },
    }
  }

  if (to.name === '/auth/login' && authenticated) {
    return sanitizeRedirectPath(to.query?.redirect)
  }

  if (isPublic || to.name === '/[...path]' || to.name === '/unauthorized') {
    return true
  }

  const session = getAuthSession()
  const allowedRoles = getAllowedRolesForRoute(to)
  if (!session.role || !allowedRoles.includes(session.role)) {
    return {
      name: '/unauthorized',
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
