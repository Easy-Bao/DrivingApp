export type {
  AppendAuditLogInput,
  AuditLogEntry,
  AuditSeverity,
  LegalDocument,
  LegalDocumentAudience,
  MunicipalityMarket,
  MunicipalityStatus,
  MutationResult,
  PlatformConfig,
  SaveLegalDocumentInput,
  SaveMunicipalityInput,
  SaveServiceZoneInput,
  ServiceZone,
  ServiceZoneStatus,
} from '@/features/settings/types'
export {
  DEFAULT_PLATFORM_CONFIG,
  clonePlatformConfig,
} from '@/features/settings/domain/platform-config'
export {
  validateLegalDocumentInput,
  validateMunicipalityInput,
  validatePlatformConfig,
  validateServiceZoneInput,
} from '@/features/settings/domain/validation'
export {
  resetSettingsForTesting,
  useAuditLogs,
  useCities,
  useLegalPolicies,
  usePlatformConfig,
  useServiceZones,
} from '@/features/settings/composables/use-settings'
