export { env } from '@/core/config/env'
export { HttpClientError, httpClient, resolveApiUrl } from '@/core/http/http-client'
export {
  ROLE_PROFILES,
  getAuthSession,
  isSessionAuthenticated,
  lockAuthSession,
  loginOperator,
  restoreDefaultDemoSession,
  setAuthSessionForTesting,
  updateOperatorProfile,
  useAuthSession,
  type AuthSession,
  type OperatorRole,
  type RoleProfile,
} from '@/core/auth/auth-session'
export {
  ROUTE_ACCESS_POLICY,
  canRoleAccessPath,
  getAllowedRolesForPath,
  isSafeRouteParam,
  sanitizeRedirectPath,
  type RoutePolicyRule,
} from '@/core/auth/access-policy'
