import { ROLE_PROFILES } from '@/core'
import { DEFAULT_PLATFORM_CONFIG } from '@/features/settings/domain/platform-config'
import type {
  AuditLogEntry,
  LegalDocument,
  MunicipalityMarket,
  ServiceZone,
} from '@/features/settings/types'

function formatPhpNumber(centavos: number): string {
  return (centavos / 100).toFixed(2)
}

export const INITIAL_AUDIT_LOGS: readonly AuditLogEntry[] = [
  {
    id: 'AUD-7016-8904',
    actor: ROLE_PROFILES.root_operator.operatorName,
    role: ROLE_PROFILES.root_operator.label,
    action: 'WALLET_TOPUP_VERIFIED',
    targetEntity: 'TOP-8921 (Rodelio Cruz · +₱500.00)',
    ipAddress: '103.164.28.41 (Pagadian Ops)',
    severity: 'Info',
    timestamp: 'Today, 09:45 AM PHT',
    payloadDiff:
      '{"status": "Verified", "amount_centavos": 50000, "wallet_balance_centavos": 71850, "ref": "QR-TXN-8829104"}',
  },
  {
    id: 'AUD-7016-8903',
    actor: ROLE_PROFILES.fleet_ops.operatorName,
    role: ROLE_PROFILES.fleet_ops.label,
    action: 'DRIVER_SUSPENDED',
    targetEntity: 'DRV-7016-501 (Lito Evangelista)',
    ipAddress: '103.164.28.44 (Pagadian Ops)',
    severity: 'Critical',
    timestamp: 'Today, 08:20 AM PHT',
    payloadDiff:
      '{"status": "Suspended", "report_id": "RPT-7016-406", "reason": "Pending safety hearing"}',
  },
  {
    id: 'AUD-7016-8902',
    actor: ROLE_PROFILES.finance_ops.operatorName,
    role: ROLE_PROFILES.finance_ops.label,
    action: 'SURGE_OVERRIDE_UPDATED',
    targetEntity: 'ZN-PAG-02 (Integrated Bus Terminal)',
    ipAddress: '103.164.28.50 (Pagadian Ops)',
    severity: 'Warning',
    timestamp: 'Yesterday, 06:15 PM PHT',
    payloadDiff: `{"previous_surge": "1.4x", "new_surge": "1.8x", "ceiling": "${DEFAULT_PLATFORM_CONFIG.maxBiddingSurgeCap.toFixed(1)}x"}`,
  },
  {
    id: 'AUD-7016-8901',
    actor: ROLE_PROFILES.root_operator.operatorName,
    role: ROLE_PROFILES.root_operator.label,
    action: 'QRPH_IMAGE_ROTATED',
    targetEntity: 'ACC-QR-GCASH (QRPH-PAG-8801)',
    ipAddress: '103.164.28.41 (Pagadian Ops)',
    severity: 'Info',
    timestamp: 'Nov 09, 2026 · 04:05 PM PHT',
    payloadDiff: '{"channel": "GCash Business (QRPh)", "merchant_code": "QRPH-PAG-8801"}',
  },
]

export const INITIAL_CITIES: readonly MunicipalityMarket[] = [
  {
    id: 'MKT-ZDS-7016',
    municipality: 'Pagadian City',
    province: 'Zamboanga del Sur',
    zipCode: '7016',
    centerCoords: '7.8257° N, 123.4370° E',
    minFareCentavos: DEFAULT_PLATFORM_CONFIG.baseFareCentavos,
    requireTodaMtop: true,
    status: 'Active Launch Market',
  },
  {
    id: 'MKT-ZDS-7017',
    municipality: 'Labangan',
    province: 'Zamboanga del Sur',
    zipCode: '7017',
    centerCoords: '7.8594° N, 123.5042° E',
    minFareCentavos: 3000,
    requireTodaMtop: true,
    status: 'Pilot Rollout',
  },
  {
    id: 'MKT-ZDS-7019',
    municipality: 'Tukuran',
    province: 'Zamboanga del Sur',
    zipCode: '7019',
    centerCoords: '7.8492° N, 123.5880° E',
    minFareCentavos: 3500,
    requireTodaMtop: true,
    status: 'Planned Expansion',
  },
  {
    id: 'MKT-ZDS-7015',
    municipality: 'Dumalinao',
    province: 'Zamboanga del Sur',
    zipCode: '7015',
    centerCoords: '7.8130° N, 123.3680° E',
    minFareCentavos: 3000,
    requireTodaMtop: true,
    status: 'Planned Expansion',
  },
]

export const INITIAL_SERVICE_ZONES: readonly ServiceZone[] = [
  {
    id: 'ZN-PAG-01',
    name: 'Poblacion & Agora Market Core',
    barangaysCovered: 'San Jose, San Francisco, Gatas, Santiago, Santo Nino',
    centerCoords: '7.8257° N, 123.4370° E',
    surgeFactor: 1.4,
    polygonPoints: 18,
    activeDrivers: 64,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-02',
    name: 'Integrated Bus Terminal & Bulatok',
    barangaysCovered: 'Bulatok, Tawagan Sur, San Pedro',
    centerCoords: '7.8342° N, 123.4285° E',
    surgeFactor: 1.8,
    polygonPoints: 14,
    activeDrivers: 39,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-03',
    name: 'Dao Capitol & Gaisano Corridor',
    barangaysCovered: 'Dao, Tuburan, Tiguma, Balangasan',
    centerCoords: '7.8391° N, 123.4418° E',
    surgeFactor: 1.2,
    polygonPoints: 16,
    activeDrivers: 45,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-04',
    name: 'Santiago Wharf & Coastal Belt',
    barangaysCovered: 'Santiago, Santa Lucia, Kawit',
    centerCoords: '7.8211° N, 123.4404° E',
    surgeFactor: 1.5,
    polygonPoints: 12,
    activeDrivers: 22,
    status: 'Monitoring',
  },
]

export const INITIAL_LEGAL_DOCUMENTS: readonly LegalDocument[] = [
  {
    id: 'DOC-TOS-PH',
    title: 'Passenger Terms of Service (Pagadian City Operations)',
    audience: 'Passenger & Driver',
    versionMajor: 2,
    versionMinor: 1,
    lastUpdated: 'Nov 02, 2026',
    markdownBody: `# EasyRide Pagadian Terms of Service\n\nAll fares agreed during real-time bidding are payable directly in Philippine Pesos (PHP) cash upon arrival. Standard cancellation fees (PHP ${formatPhpNumber(DEFAULT_PLATFORM_CONFIG.cancellationFeeCentavos)}) apply only outside the 3-minute grace window.`,
  },
  {
    id: 'DOC-TODA-CHARTER',
    title: 'Driver Partner & TODA Franchise Agreement',
    audience: 'Driver Fleet',
    versionMajor: 1,
    versionMinor: 8,
    lastUpdated: 'Oct 28, 2026',
    markdownBody: `# Driver Partner Charter\n\nDrivers must maintain an active LTO Professional License, Pagadian TODA MTOP franchise permit, and at least PHP ${formatPhpNumber(DEFAULT_PLATFORM_CONFIG.minWalletBalanceCentavos)} in prepaid commission credits to receive bid requests.`,
  },
  {
    id: 'DOC-DPA-10173',
    title: 'Data Privacy Act (RA 10173) Location & KYC Notice',
    audience: 'All Platform Users',
    versionMajor: 1,
    versionMinor: 4,
    lastUpdated: 'Oct 15, 2026',
    markdownBody:
      '# Philippine Data Privacy Act Compliance\n\nGPS telemetry, emergency SOS coordinates, and government license images are processed exclusively for dispatch safety, identity verification, and settlement auditing.',
  },
]
