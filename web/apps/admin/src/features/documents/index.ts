export { buildDocumentPreviewSvg, escapeXml } from '@/features/documents/domain/doc-preview'
export { isDocumentExpired } from '@/features/documents/domain/expiry'
export {
  resetDocumentsForTesting,
  useExpiringDocuments,
  useRejectedDocuments,
  useVerificationDocuments,
} from '@/features/documents/composables/use-documents'
export type {
  DocumentActionResult,
  DocumentPreviewInput,
  ExpiringDocument,
  ExpiryStatus,
  PendingDocument,
  RejectedDocument,
  VerificationChecklist,
  VerificationStatus,
} from '@/features/documents/types'
