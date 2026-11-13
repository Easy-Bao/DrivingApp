import { readonly, ref } from 'vue'

export type OperatorRole = 'root_operator' | 'fleet_ops' | 'finance_ops' | 'support_lead'

export interface AuthSession {
  token: string | null
  userId: string | null
  operatorName: string
  operatorEmail: string
  role: OperatorRole | null
  expiresAt: number
  locked: boolean
}

export interface RoleProfile {
  role: OperatorRole
  label: string
  operatorName: string
  operatorEmail: string
  userId: string
  scopeSummary: string
}

export const ROLE_PROFILES: Record<OperatorRole, RoleProfile> = {
  root_operator: {
    role: 'root_operator',
    label: 'Root Operator',
    operatorName: 'Operations Lead',
    operatorEmail: 'ops@easyride.ph',
    userId: 'OP-001',
    scopeSummary: 'All routes, operators, ledger, dispatch, and settings.',
  },
  fleet_ops: {
    role: 'fleet_ops',
    label: 'Fleet Ops',
    operatorName: 'Ramon Villanueva',
    operatorEmail: 'dispatch@easyride.ph',
    userId: 'OP-002',
    scopeSummary: 'Trips, live dispatch, documents, zones, and safety.',
  },
  finance_ops: {
    role: 'finance_ops',
    label: 'Finance Ops',
    operatorName: 'Clarisse Mendoza',
    operatorEmail: 'treasury@easyride.ph',
    userId: 'OP-003',
    scopeSummary: 'Top-ups, settlements, tariffs, commissions, and reports.',
  },
  support_lead: {
    role: 'support_lead',
    label: 'Support Lead',
    operatorName: 'Marisol Lim',
    operatorEmail: 'safety@easyride.ph',
    userId: 'OP-004',
    scopeSummary: 'Tickets, disputes, safety reports, and refunds.',
  },
}

const STORAGE_KEY = 'easyride_console_session_v1'
const SESSION_DURATION_MS = 8 * 60 * 60 * 1000
const VALID_ROLES = new Set<OperatorRole>([
  'root_operator',
  'fleet_ops',
  'finance_ops',
  'support_lead',
])

function createActiveSession(role: OperatorRole, now = Date.now()): AuthSession {
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

function nonEmptyString(value: unknown, fallback: string): string {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : fallback
}

function createLockedSession(previous?: Partial<AuthSession>): AuthSession {
  return {
    token: null,
    userId: null,
    operatorName: nonEmptyString(previous?.operatorName, ROLE_PROFILES.root_operator.operatorName),
    operatorEmail: nonEmptyString(
      previous?.operatorEmail,
      ROLE_PROFILES.root_operator.operatorEmail,
    ),
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

function clearPersistedSession(): void {
  if (typeof window === 'undefined' || typeof window.sessionStorage === 'undefined') return
  try {
    window.sessionStorage.removeItem(STORAGE_KEY)
  } catch {
    // Ignore storage errors
  }
}

function loadInitialSession(): AuthSession {
  if (typeof window === 'undefined' || typeof window.sessionStorage === 'undefined') {
    return createActiveSession('root_operator')
  }
  try {
    const raw = window.sessionStorage.getItem(STORAGE_KEY)
    if (!raw) {
      const initial = createActiveSession('root_operator')
      persistSession(initial)
      return initial
    }
    const parsed = JSON.parse(raw) as unknown
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      clearPersistedSession()
      return createLockedSession()
    }
    const record = parsed as Partial<AuthSession>
    if (record.locked === true) {
      return createLockedSession(record)
    }
    if (
      typeof record.token === 'string' &&
      record.token.trim().length >= 8 &&
      typeof record.userId === 'string' &&
      record.userId.trim().length > 0 &&
      typeof record.operatorName === 'string' &&
      record.operatorName.trim().length > 0 &&
      typeof record.operatorEmail === 'string' &&
      record.operatorEmail.trim().length > 0 &&
      typeof record.role === 'string' &&
      VALID_ROLES.has(record.role as OperatorRole) &&
      typeof record.expiresAt === 'number' &&
      Number.isFinite(record.expiresAt) &&
      record.expiresAt > Date.now()
    ) {
      return {
        token: record.token.trim(),
        userId: record.userId.trim(),
        operatorName: record.operatorName.trim(),
        operatorEmail: record.operatorEmail.trim(),
        role: record.role as OperatorRole,
        expiresAt: record.expiresAt,
        locked: false,
      }
    }
    const expired = createLockedSession(record)
    persistSession(expired)
    return expired
  } catch {
    clearPersistedSession()
    return createLockedSession()
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
  role: OperatorRole,
  pin: string,
): { ok: true; session: AuthSession } | { ok: false; error: string } {
  const normalizedPin = pin.trim()
  if (normalizedPin.length < 4) {
    return { ok: false, error: 'PIN must be at least 4 characters.' }
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
  const next = createActiveSession('root_operator')
  sessionState.value = next
  persistSession(next)
}

export function lockAuthSession(): void {
  const locked = createLockedSession(sessionState.value)
  sessionState.value = locked
  persistSession(locked)
}

export function updateOperatorProfile(patch: {
  operatorName: string
  operatorEmail: string
}): { ok: true; session: AuthSession } | { ok: false; error: string } {
  if (sessionState.value.locked || !sessionState.value.role) {
    return { ok: false, error: 'Unlock session before updating profile.' }
  }
  const nextName = patch.operatorName.trim()
  const nextEmail = patch.operatorEmail.trim()
  if (!nextName || !nextEmail.includes('@')) {
    return { ok: false, error: 'Enter a valid full name and email address before saving.' }
  }
  const updated: AuthSession = {
    ...sessionState.value,
    operatorName: nextName,
    operatorEmail: nextEmail,
  }
  sessionState.value = updated
  persistSession(updated)
  return { ok: true, session: updated }
}
