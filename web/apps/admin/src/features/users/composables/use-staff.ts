import { computed, ref, type Ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import {
  OPERATOR_ROLE_OPTIONS,
  RBAC_PERMISSION_CATALOG,
  SEED_OPERATORS,
  SEED_RBAC_ROLES,
} from '@/features/users/data/users.seed'
import type {
  InviteOperatorInput,
  OperatorAccount,
  RbacRole,
  SaveRoleInput,
  UserActionResult,
} from '@/features/users/types'

function cloneOperators(source: readonly OperatorAccount[]): OperatorAccount[] {
  return source.map((item) => ({ ...item }))
}

function cloneRoles(source: readonly RbacRole[]): RbacRole[] {
  return source.map((item) => ({
    ...item,
    scopes: [...item.scopes],
  }))
}

const operators: Ref<OperatorAccount[]> = ref(cloneOperators(SEED_OPERATORS))
const roles: Ref<RbacRole[]> = ref(cloneRoles(SEED_RBAC_ROLES))

export function resetStaffForTesting(): void {
  operators.value = cloneOperators(SEED_OPERATORS)
  roles.value = cloneRoles(SEED_RBAC_ROLES)
}

function inferDepartment(role: string): string {
  if (role.includes('Dispatch')) return 'Fleet Dispatch'
  if (role.includes('Treasury')) return 'Treasury & Wallet QA'
  if (role.includes('Trust') || role.includes('Support')) return 'Compliance & Support'
  return 'Executive Operations'
}

/**
 * Manages staff operator accounts, root protection guards, MFA toggles, and suspensions.
 */
export function useOperators() {
  const { appendAuditLog } = useAuditLogs()

  function inviteOperator(input: InviteOperatorInput): UserActionResult {
    const name = input.name.trim()
    const email = input.email.trim().toLowerCase()
    const role = input.role.trim()

    if (!name || !email) {
      return { ok: false, error: 'Operator name and corporate email are required.' }
    }
    if (operators.value.some((op) => op.email.toLowerCase() === email)) {
      return { ok: false, error: `An operator with email ${email} already exists.` }
    }

    const nextNum = operators.value.length + 1
    const newId = `OPS-${String(nextNum).padStart(3, '0')}`
    const created: OperatorAccount = {
      id: newId,
      name,
      email,
      role,
      department: inferDepartment(role),
      mfaEnabled: true,
      lastActive: 'Invite sent',
      status: 'Active',
    }
    operators.value.unshift(created)

    appendAuditLog({
      action: 'OPERATOR_INVITED',
      targetEntity: `${newId} · ${name}`,
      payload: { email, role },
      severity: 'Info',
    })

    return { ok: true, message: `Invitation sent to ${name} (${email}).` }
  }

  function updateOperatorRole(id: string, role: string): UserActionResult {
    if (id === 'OPS-001') {
      return { ok: false, error: 'Root operator account role cannot be modified.' }
    }
    const target = operators.value.find((op) => op.id === id)
    if (!target) {
      return { ok: false, error: `Operator ${id} was not found.` }
    }
    const trimmedRole = role.trim()
    if (!trimmedRole || target.role === trimmedRole) {
      return { ok: false, error: 'Select a different valid role to apply.' }
    }

    const prevRole = target.role
    target.role = trimmedRole
    target.department = inferDepartment(trimmedRole)

    appendAuditLog({
      action: 'OPERATOR_ROLE_UPDATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { previousRole: prevRole, nextRole: trimmedRole },
      severity: 'Warning',
    })

    return { ok: true, message: `Updated ${target.name} role to ${trimmedRole}.` }
  }

  function toggleOperatorMfa(id: string): UserActionResult {
    if (id === 'OPS-001') {
      return { ok: false, error: 'Root operator account MFA enforcement cannot be disabled.' }
    }
    const target = operators.value.find((op) => op.id === id)
    if (!target) {
      return { ok: false, error: `Operator ${id} was not found.` }
    }

    target.mfaEnabled = !target.mfaEnabled

    appendAuditLog({
      action: 'OPERATOR_MFA_UPDATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { mfaEnabled: target.mfaEnabled },
      severity: 'Warning',
    })

    return {
      ok: true,
      message: `${target.mfaEnabled ? 'Enabled' : 'Disabled'} 2FA enforcement for ${target.name}.`,
    }
  }

  function suspendOperator(id: string, reason?: string): UserActionResult {
    if (id === 'OPS-001') {
      return { ok: false, error: 'Root operator account cannot be suspended.' }
    }
    const target = operators.value.find((op) => op.id === id)
    if (!target) {
      return { ok: false, error: `Operator ${id} was not found.` }
    }
    if (target.status === 'Suspended') {
      return { ok: false, error: `${target.name} is already suspended.` }
    }

    target.status = 'Suspended'
    appendAuditLog({
      action: 'OPERATOR_STATUS_UPDATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { status: 'Suspended', reason: reason?.trim() || undefined },
      severity: 'Critical',
    })

    return { ok: true, message: `${target.name} account suspended.` }
  }

  function reactivateOperator(id: string): UserActionResult {
    const target = operators.value.find((op) => op.id === id)
    if (!target) {
      return { ok: false, error: `Operator ${id} was not found.` }
    }
    if (target.status !== 'Suspended') {
      return { ok: false, error: `${target.name} is already active.` }
    }

    target.status = 'Active'
    appendAuditLog({
      action: 'OPERATOR_STATUS_UPDATED',
      targetEntity: `${target.id} · ${target.name}`,
      payload: { status: 'Active' },
      severity: 'Info',
    })

    return { ok: true, message: `${target.name} account reactivated.` }
  }

  return {
    operators,
    roleOptions: OPERATOR_ROLE_OPTIONS,
    inviteOperator,
    updateOperatorRole,
    toggleOperatorMfa,
    suspendOperator,
    reactivateOperator,
  }
}

/**
 * Manages RBAC roles, permission matrix updates, and live staff counts.
 */
export function useRoles() {
  const { appendAuditLog } = useAuditLogs()

  const roleUserCounts = computed<Record<string, number>>(() => {
    const counts: Record<string, number> = {}
    for (const op of operators.value) {
      counts[op.role] = (counts[op.role] ?? 0) + 1
    }
    return counts
  })

  function saveRole(input: SaveRoleInput): UserActionResult {
    const name = input.name.trim()
    const summary = input.description.trim()
    if (!name || input.scopes.length === 0) {
      return { ok: false, error: 'Role name and at least one permission scope are required.' }
    }

    if (input.id) {
      const target = roles.value.find((role) => role.id === input.id)
      if (!target) {
        return { ok: false, error: `Role ${input.id} was not found.` }
      }
      target.name = name
      target.summary = summary || target.summary
      target.scopes = [...input.scopes]

      appendAuditLog({
        action: 'RBAC_ROLE_UPDATED',
        targetEntity: `${target.id} · ${name}`,
        payload: { scopes: input.scopes },
        severity: 'Warning',
      })

      return { ok: true, message: `Updated permissions for ${name}.` }
    }

    const newRole: RbacRole = {
      id: `ROLE-${roles.value.length + 1}`,
      name,
      usersCount: roleUserCounts.value[name] ?? 0,
      summary: summary || 'Custom console operator role.',
      scopes: [...input.scopes],
    }
    roles.value.push(newRole)

    appendAuditLog({
      action: 'RBAC_ROLE_CREATED',
      targetEntity: `${newRole.id} · ${name}`,
      payload: { scopes: input.scopes },
      severity: 'Info',
    })

    return { ok: true, message: `Created role "${name}".` }
  }

  return {
    roles,
    permissionCatalog: RBAC_PERMISSION_CATALOG,
    roleUserCounts,
    saveRole,
  }
}
