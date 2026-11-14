export type VerificationStatus = 'Pending Review' | 'Approved' | 'Rejected'

export interface PendingDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  issuingAgency: string
  expiryDate: string
  submittedAt: string
  docImageUrl: string
  hasTwoSides?: boolean
  frontScanUrl?: string
  backScanUrl?: string
  status: VerificationStatus
  rejectionReason?: string
}

export type ExpiryStatus = 'Action Required' | 'Notice Sent' | 'Grace Period'

export interface ExpiringDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  expiryDate: string
  daysLeft: number
  status: ExpiryStatus
  reminded?: boolean
}

export interface RejectedDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  rejectionReason: string
  rejectedBy: string
  rejectedAt: string
  resubmitted: boolean
  reopened?: boolean
}

export interface VerificationChecklist {
  clearScan: boolean
  sealVerified: boolean
  nameMatches: boolean
  validExpiry: boolean
}

export interface DocumentPreviewInput {
  docId: string
  title: string
  holder: string
  authority: string
  plateOrRef: string
  side?: 'Front' | 'Back'
  subtitle?: string
}

export type DocumentActionResult =
  | { ok: true; message: string; count?: number }
  | { ok: false; error: string }
