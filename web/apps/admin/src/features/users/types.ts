export interface DriverApplication {
  id: string
  applicant: string
  email: string
  phone: string
  appliedDate: string
  appliedTime: string
  city: string
  province: string
  barangay: string
  facePhotoUrl: string
  licenseNumber: string
  licenseType: string
  licenseExpiry: string
  licenseCodes: string
  licenseFrontDoc: string
  licenseBackDoc: string
  vehicle: {
    type: string
    make: string
    model: string
    year: number
    plate: string
    color: string
    bodyNumber: string
    todaFranchise: string
    mtopNumber: string
    engineNumber: string
    chassisNumber: string
    orNumber: string
    crNumber: string
    orDoc: string
    crDoc: string
    insurancePolicy: string
    inspectionDoc: string
  }
  backgroundStatus: 'Passed' | 'Pending' | 'Review Required'
  clearanceType: string
  clearanceNumber: string
  clearanceDoc: string
  backgroundProvider: string
  backgroundNotes: string
  rejectionReason?: string
  status: 'Pending Review' | 'Approved' | 'Rejected'
}

export type DriverStatus = 'Active' | 'Low Balance (Locked)' | 'Suspended'

export interface DriverRecord {
  id: string
  name: string
  phone: string
  city: string
  vehicle: string
  todaZone: string
  trips: number
  rating: number
  walletBalanceCentavos: number
  status: DriverStatus
  suspensionReason?: string
}

export type RiderStanding = 'Good Standing' | 'VIP Rider' | 'Flagged (Dispute)' | 'Suspended'

export interface RiderRecord {
  id: string
  name: string
  phone: string
  barangay: string
  totalTrips: number
  lifetimeSpendCentavos: number
  rating: number
  standing: RiderStanding
  notes: string
}

export interface OperatorAccount {
  id: string
  name: string
  email: string
  role: string
  department: string
  mfaEnabled: boolean
  lastActive: string
  status: 'Active' | 'Suspended'
}

export interface RbacRole {
  id: string
  name: string
  usersCount: number
  summary: string
  scopes: string[]
}

export interface InviteOperatorInput {
  name: string
  email: string
  role: string
}

export interface SaveRoleInput {
  id?: string
  name: string
  description: string
  scopes: string[]
}

export type UserActionResult = { ok: true; message: string } | { ok: false; error: string }
