import { ref } from 'vue'

export interface TopUpRequest {
  id: string
  driverName: string
  driverPhone: string
  vehiclePlate: string
  currentBalance: number
  amount: number
  paymentMethod: 'Company QR Code' | 'Company Bank Transfer'
  referenceCode: string
  submittedAt: string
  companyAccountPaid: string
  proofNote: string
  receiptFileName: string
  status: 'Pending' | 'Verified' | 'Rejected'
}

const topUpRequests = ref<TopUpRequest[]>([
  {
    id: 'TOP-8921',
    driverName: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    vehiclePlate: '7XYZ892',
    currentBalance: 1.5,
    amount: 50.0,
    paymentMethod: 'Company QR Code',
    referenceCode: 'QR-TXN-8829104',
    submittedAt: '8 minutes ago',
    companyAccountPaid: 'Company QR Merchant #ER-8801',
    proofNote: 'Screenshot verified against company mobile payment receipt #8829104',
    receiptFileName: 'company_qr_receipt_8829104.png',
    status: 'Pending',
  },
  {
    id: 'TOP-8920',
    driverName: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    vehiclePlate: 'EV-4491',
    currentBalance: 3.2,
    amount: 100.0,
    paymentMethod: 'Company Bank Transfer',
    referenceCode: 'WIRE-99218204',
    submittedAt: '24 minutes ago',
    companyAccountPaid: 'Company Fleet Acct: 0182-9981-2291',
    proofNote: 'Bank deposit receipt matches exact timestamp and account holder name',
    receiptFileName: 'bank_wire_deposit_99218204.pdf',
    status: 'Pending',
  },
  {
    id: 'TOP-8919',
    driverName: 'David Kim',
    driverPhone: '+1 (555) 345-6789',
    vehiclePlate: 'CAM-8891',
    currentBalance: 0.0,
    amount: 30.0,
    paymentMethod: 'Company QR Code',
    referenceCode: 'QR-TXN-7719201',
    submittedAt: '42 minutes ago',
    companyAccountPaid: 'Company QR Merchant #ER-8801',
    proofNote: 'Bank notification confirmed for ₱30.00',
    receiptFileName: 'company_qr_receipt_7719201.png',
    status: 'Pending',
  },
])

export function useTopups() {
  function getRequestById(id: string): TopUpRequest | undefined {
    return topUpRequests.value.find((r) => r.id === id)
  }

  function verifyAndCredit(req: TopUpRequest): void {
    req.status = 'Verified'
    req.currentBalance += req.amount
  }

  function rejectRequest(req: TopUpRequest): void {
    req.status = 'Rejected'
  }

  return {
    topUpRequests,
    getRequestById,
    verifyAndCredit,
    rejectRequest,
  }
}
