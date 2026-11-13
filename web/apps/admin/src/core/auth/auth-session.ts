import { readonly, ref } from 'vue'

export type AdminRole = 'super_admin' | 'fleet_ops' | 'finance_admin' | 'support_lead'

export interface AuthSession {
  token: string | null
  userId: string | null
  operatorName: string
  operatorEmail: string
  role: AdminRole | null
  expiresAt: number
  locked: boolean
}

export interface RoleProfile {
  role: AdminRole
  label: string
  operatorName: string
  operatorEmail: string
  userId: string
  scopeSummary: string
}

export const ROLE_PROFILES: Record<AdminRole, RoleProfile> = {
  super_admin: {
    role: 'super_admin',
    label: 'Super Administrator',
    operatorName: 'Operations Control Lead',
    operatorEmail: 'ops@easyride.ph',
    userId: 'ADM-001',
    scopeSummary: 'Full platform configuration, RBAC, ledger, dispatch, and safety access',
  },
  fleet_ops: {
    role: 'fleet_ops',
    label: 'Dispatch & Safety Supervisor',
    operatorName: 'Ramon Villanueva',
    operatorEmail: 'dispatch@easyride.ph',
    userId: 'ADM-002',
    scopeSummary: 'Trips, live dispatch, KYC documents, service zones, and passenger safety',
  },
  finance_admin: {
    role: 'finance_admin',
    label: 'Treasury & Settlements Officer',
    operatorName: 'Clarisse Mendoza',
    operatorEmail: 'treasury@easyride.ph',
    userId: 'ADM-003',
    scopeSummary: 'Driver top-ups, cash settlement ledger, tariffs, commissions, and reports',
  },
  support_lead: {
    role: 'support_lead',
    label: 'Trust & Safety Lead',
    operatorName: 'Marisol Lim',
    operatorEmail: 'safety@easyride.ph',
    userId: 'ADM-004',
    scopeSummary: 'Support tickets, incident reports, disputes, rider standing, and refunds',
  },
}

const STORAGE_KEY = 'easyride_admin_session_v1'
const SESSION_DURATION_MS = 8 * 60 * 60 * 1000
const VALID_ROLES = new Set<AdminRole>([
  'super_admin',
  'fleet_ops',
  'finance_admin',
  'support_lead',
])

function createActiveSession(role: AdminRole, now = Date.now()): AuthSession {
  const profile = ROLE_PROFILES[role]
  return {
    token: `ezr-${role}-7016-${now.toString(36)}`,
    userId: profile.userId,
    operatorName: profile.operatorName,
    operatorEmail: profile.operatorEmail,
    role,
    expiresAt: now + SESSION_DURATION_MS,
    locked: false,
  }
}

function createLockedSession(previous?: Partial<AuthSession>): AuthSession {
  return {
    token: null,
    userId: null,
    operatorName: previous?.operatorName || ROLE_PROFILES.super_admin.operatorName,
    operatorEmail: previous?.operatorEmail || ROLE_PROFILES.super_admin.operatorEmail,
    role: null,
    expiresAt: 0,
    locked: true,
  }
}

function persistSession(session: AuthSession): void {
  if (typeof window === 'undefined' || typeof window.sessionStorage === 'undefined') return
  try {
    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(session))
  } catch {
    // Ignore storage quota or private browsing errors
  }
}

function loadInitialSession(): AuthSession {
  if (typeof window === 'undefined' || typeof window.sessionStorage === 'undefined') {
    return createActiveSession('super_admin')
  }
  try {
    const raw = window.sessionStorage.getItem(STORAGE_KEY)
    if (!raw) {
      const initial = createActiveSession('super_admin')
      persistSession(initial)
      return initial
    }
    const parsed = JSON.parse(raw) as Partial<AuthSession>
    if (parsed.locked) {
      return createLockedSession(parsed)
    }
    if (
      typeof parsed.token === 'string' &&
      parsed.token.length >= 8 &&
      typeof parsed.userId === 'string' &&
      parsed.role &&
      VALID_ROLES.has(parsed.role) &&
      typeof parsed.expiresAt === 'number' &&
      parsed.expiresAt > Date.now()
    ) {
      return {
        token: parsed.token,
        userId: parsed.userId,
        operatorName: parsed.operatorName || ROLE_PROFILES[parsed.role].operatorName,
        operatorEmail: parsed.operatorEmail || ROLE_PROFILES[parsed.role].operatorEmail,
        role: parsed.role,
        expiresAt: parsed.expiresAt,
        locked: false,
      }
    }
    const expired = createLockedSession(parsed)
    persistSession(expired)
    return expired
  } catch {
    return createActiveSession('super_admin')
  }
}

const sessionState = ref<AuthSession>(loadInitialSession())

export function getAuthSession(): AuthSession {
  return sessionState.value
}

export function useAuthSession() {
  return readonly(sessionState)
}

export function isSessionAuthenticated(now = Date.now()): boolean {
  const current = sessionState.value
  if (current.locked || !current.token || !current.userId || !current.role) {
    return false
  }
  if (!VALID_ROLES.has(current.role)) {
    return false
  }
  if (current.expiresAt <= now) {
    lockAuthSession()
    return false
  }
  return true
}

export function loginOperator(
  role: AdminRole,
  pin: string,
): { ok: true; session: AuthSession } | { ok: false; error: string } {
  const normalizedPin = pin.trim()
  if (normalizedPin.length < 4) {
    return { ok: false, error: 'Enter a valid operator security PIN (minimum 4 characters).' }
  }
  const next = createActiveSession(role)
  sessionState.value = next
  persistSession(next)
  return { ok: true, session: next }
}

export function setAuthSessionForTesting(session: Partial<AuthSession>): void {
  const next: AuthSession = {
    ...sessionState.value,
    ...session,
  }
  sessionState.value = next
  persistSession(next)
}

export function restoreDefaultDemoSession(): void {
  const next = createActiveSession('super_admin')
  sessionState.value = next
  persistSession(next)
}

export function lockAuthSession(): void {
  const locked = createLockedSession(sessionState.value)
  sessionState.value = locked
  persistSession(locked)
}
