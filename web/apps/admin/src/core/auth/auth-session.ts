export interface AuthSession {
  token: string | null
  userId: string | null
  role: 'super_admin' | 'fleet_ops' | 'finance_admin' | 'support_lead' | null
}

export function getAuthSession(): AuthSession {
  return {
    token: null,
    userId: 'admin-user-01',
    role: 'super_admin',
  }
}
