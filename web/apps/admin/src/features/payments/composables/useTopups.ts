import { ref } from 'vue'

export interface TopUpRequest {
  id: string
  driverName: string
  driverPhone: string
  vehiclePlate: string
  sidecarBody: string
  currentBalance: number
  amount: number
  paymentMethod: 'Company QR Code' | 'Company Bank Transfer'
  channelProvider: string
  senderAccount: string
  referenceCode: string
  submittedAt: string
  transactionTimestamp: string
  companyAccountPaid: string
  proofNote: string
  receiptFileName: string
  receiptPreviewUrl: string
  rejectionReason?: string
  status: 'Pending' | 'Verified' | 'Rejected'
}

function buildReceiptPreviewSvg(params: {
  provider: string
  amount: number
  reference: string
  recipient: string
  sender: string
  timestamp: string
  accent: string
}): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="540" height="680" viewBox="0 0 540 680">
  <rect width="540" height="680" fill="#f8fafc"/>
  <rect x="30" y="28" width="480" height="624" fill="#ffffff" stroke="#e2e8f0" stroke-width="2"/>
  <rect x="30" y="28" width="480" height="84" fill="${params.accent}"/>
  <text x="58" y="68" font-family="sans-serif" font-size="18" font-weight="700" fill="#ffffff">${params.provider}</text>
  <text x="58" y="92" font-family="sans-serif" font-size="12" fill="#e2e8f0">Official Electronic Fund Transfer Receipt</text>
  <rect x="242" y="148" width="56" height="56" fill="#dcfce7"/>
  <path d="M256 176 l10 10 l18 -20" stroke="#15803d" stroke-width="4" fill="none" stroke-linecap="square" stroke-linejoin="miter"/>
  <text x="270" y="232" text-anchor="middle" font-family="sans-serif" font-size="13" font-weight="700" fill="#15803d">TRANSFER COMPLETED</text>
  <text x="270" y="274" text-anchor="middle" font-family="monospace" font-size="34" font-weight="800" fill="#0f172a">PHP ${params.amount.toFixed(2)}</text>
  <line x1="58" y1="304" x2="482" y2="304" stroke="#e2e8f0" stroke-dasharray="6 4"/>
  <text x="58" y="344" font-family="sans-serif" font-size="12" fill="#64748b">Recipient Merchant / Account</text>
  <text x="58" y="366" font-family="monospace" font-size="14" font-weight="700" fill="#0f172a">${params.recipient}</text>
  <text x="58" y="408" font-family="sans-serif" font-size="12" fill="#64748b">Sender Source</text>
  <text x="58" y="430" font-family="monospace" font-size="14" font-weight="600" fill="#1e293b">${params.sender}</text>
  <text x="58" y="472" font-family="sans-serif" font-size="12" fill="#64748b">Transaction Reference No.</text>
  <text x="58" y="494" font-family="monospace" font-size="15" font-weight="700" fill="#0f172a">${params.reference}</text>
  <text x="58" y="536" font-family="sans-serif" font-size="12" fill="#64748b">Timestamp (PHT · UTC+8)</text>
  <text x="58" y="558" font-family="monospace" font-size="13" font-weight="600" fill="#334155">${params.timestamp}</text>
  <rect x="58" y="586" width="424" height="40" fill="#f1f5f9"/>
  <text x="270" y="610" text-anchor="middle" font-family="monospace" font-size="11" fill="#475569">Pagadian City Taxicle Dispatch Wallet Top-Up</text>
</svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}

const topUpRequests = ref<TopUpRequest[]>([
  {
    id: 'TOP-8921',
    driverName: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    vehiclePlate: '1284-ND',
    sidecarBody: 'Sidecar #084 · Poblacion TODA',
    currentBalance: 42.5,
    amount: 500.0,
    paymentMethod: 'Company QR Code',
    channelProvider: 'GCash QRPh',
    senderAccount: 'Rodelio C. · +63 917 *** 2184',
    referenceCode: 'GC-90281944210',
    submittedAt: '8 minutes ago',
    transactionTimestamp: '2026-11-13 11:34 AM PHT',
    companyAccountPaid: 'EasyRide Pagadian QRPh (#ER-PAG-01)',
    proofNote:
      'Driver uploaded GCash InstaPay screenshot matching merchant QR #ER-PAG-01 for ₱500.00.',
    receiptFileName: 'gcash_qr_receipt_90281944210.jpg',
    receiptPreviewUrl: buildReceiptPreviewSvg({
      provider: 'GCash · QRPh Merchant Transfer',
      amount: 500,
      reference: 'GC-90281944210',
      recipient: 'EasyRide Pagadian (#ER-PAG-01)',
      sender: 'Rodelio Cruz · 0917-440-2184',
      timestamp: '2026-11-13 11:34:18 PHT',
      accent: '#007dfe',
    }),
    status: 'Pending',
  },
  {
    id: 'TOP-8920',
    driverName: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    vehiclePlate: '3891-ZK',
    sidecarBody: 'Sidecar #042 · San Jose TODA',
    currentBalance: 18.0,
    amount: 1000.0,
    paymentMethod: 'Company Bank Transfer',
    channelProvider: 'BDO Unibank Pagadian',
    senderAccount: 'Danilo Mendoza · BDO **** 3319',
    referenceCode: 'BDO-IBFT-88412093',
    submittedAt: '24 minutes ago',
    transactionTimestamp: '2026-11-13 11:18 AM PHT',
    companyAccountPaid: 'BDO EasyRide Corp · 0041-8892-1102',
    proofNote: 'BDO online InstaPay transfer receipt verified against corporate depository log.',
    receiptFileName: 'bdo_transfer_slip_88412093.jpg',
    receiptPreviewUrl: buildReceiptPreviewSvg({
      provider: 'BDO Unibank · InstaPay Deposit',
      amount: 1000,
      reference: 'BDO-IBFT-88412093',
      recipient: 'BDO EasyRide Corp · ****1102',
      sender: 'Danilo Mendoza · 0928-412-8890',
      timestamp: '2026-11-13 11:18:05 PHT',
      accent: '#003a70',
    }),
    status: 'Pending',
  },
  {
    id: 'TOP-8919',
    driverName: 'Edgar Tolentino',
    driverPhone: '+63 915 209 7741',
    vehiclePlate: '5190-QP',
    sidecarBody: 'Sidecar #109 · Agora TODA',
    currentBalance: 0.0,
    amount: 300.0,
    paymentMethod: 'Company QR Code',
    channelProvider: 'Maya QRPh',
    senderAccount: 'Edgar T. · +63 915 *** 7741',
    referenceCode: 'MAYA-774102983',
    submittedAt: '42 minutes ago',
    transactionTimestamp: '2026-11-13 10:59 AM PHT',
    companyAccountPaid: 'EasyRide Maya Merchant (#ER-MAYA-02)',
    proofNote: 'Driver wallet reached ₱0.00 threshold and submitted Maya QR payment proof.',
    receiptFileName: 'maya_qr_proof_774102983.jpg',
    receiptPreviewUrl: buildReceiptPreviewSvg({
      provider: 'Maya · QRPh Settlement',
      amount: 300,
      reference: 'MAYA-774102983',
      recipient: 'EasyRide Maya (#ER-MAYA-02)',
      sender: 'Edgar Tolentino · 0915-209-7741',
      timestamp: '2026-11-13 10:59:41 PHT',
      accent: '#15803d',
    }),
    status: 'Pending',
  },
  {
    id: 'TOP-8918',
    driverName: 'Junel Pineda',
    driverPhone: '+63 998 331 0912',
    vehiclePlate: '9102-AB',
    sidecarBody: 'Sidecar #019 · Balangasan TODA',
    currentBalance: 645.0,
    amount: 500.0,
    paymentMethod: 'Company Bank Transfer',
    channelProvider: 'BPI Family Savings',
    senderAccount: 'Junel Pineda · BPI **** 9104',
    referenceCode: 'BPI-REF-6620192',
    submittedAt: '3 hours ago',
    transactionTimestamp: '2026-11-13 08:22 AM PHT',
    companyAccountPaid: 'BPI EasyRide Operations · 2190-4418-09',
    proofNote: 'Credited cleanly after morning BPI statement reconciliation.',
    receiptFileName: 'bpi_deposit_6620192.jpg',
    receiptPreviewUrl: buildReceiptPreviewSvg({
      provider: 'BPI Online · Fund Transfer',
      amount: 500,
      reference: 'BPI-REF-6620192',
      recipient: 'BPI EasyRide Ops · ****1809',
      sender: 'Junel Pineda · 0998-331-0912',
      timestamp: '2026-11-13 08:22:10 PHT',
      accent: '#991b1b',
    }),
    status: 'Verified',
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

  function rejectRequest(req: TopUpRequest, reason?: string): void {
    req.status = 'Rejected'
    if (reason && reason.trim().length > 0) {
      req.rejectionReason = reason.trim()
    }
  }

  return {
    topUpRequests,
    getRequestById,
    verifyAndCredit,
    rejectRequest,
  }
}
