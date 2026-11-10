import { ref } from 'vue'

export interface PayoutRequest {
  id: string
  driver: string
  phone: string
  amount: number
  bankName: string
  accountNumber: string
  routingNumber: string
  requestedAt: string
  tripsCount: number
  weeklyGrossEarnings: number
  platformCommissionDeducted: number
  netPayoutAmount: number
  status: 'Pending Batch' | 'Approved' | 'Paid' | 'Rejected'
}

const payoutRequests = ref<PayoutRequest[]>([
  {
    id: 'PAY-401',
    driver: 'Marcus Miller',
    phone: '+1 (555) 234-5678',
    amount: 420.5,
    bankName: 'First National Bank',
    accountNumber: '**** **** 8821',
    routingNumber: '021000021',
    requestedAt: '3 hours ago',
    tripsCount: 28,
    weeklyGrossEarnings: 525.6,
    platformCommissionDeducted: 105.1,
    netPayoutAmount: 420.5,
    status: 'Pending Batch',
  },
  {
    id: 'PAY-402',
    driver: 'Elena Rostova',
    phone: '+1 (555) 876-5432',
    amount: 615.0,
    bankName: 'Silicon Valley Metro Bank',
    accountNumber: '**** **** 1142',
    routingNumber: '121000358',
    requestedAt: '5 hours ago',
    tripsCount: 42,
    weeklyGrossEarnings: 768.75,
    platformCommissionDeducted: 153.75,
    netPayoutAmount: 615.0,
    status: 'Pending Batch',
  },
  {
    id: 'PAY-403',
    driver: 'David Kim',
    phone: '+1 (555) 345-6789',
    amount: 310.0,
    bankName: 'Chase Commercial Banking',
    accountNumber: '**** **** 9081',
    routingNumber: '071000013',
    requestedAt: 'Yesterday',
    tripsCount: 19,
    weeklyGrossEarnings: 387.5,
    platformCommissionDeducted: 77.5,
    netPayoutAmount: 310.0,
    status: 'Pending Batch',
  },
])

export function usePayoutRequests() {
  function getPayoutById(id: string): PayoutRequest | undefined {
    return payoutRequests.value.find((p) => p.id === id)
  }

  function approvePayout(req: PayoutRequest): void {
    req.status = 'Approved'
  }

  function rejectPayout(req: PayoutRequest): void {
    req.status = 'Rejected'
  }

  return {
    payoutRequests,
    getPayoutById,
    approvePayout,
    rejectPayout,
  }
}
