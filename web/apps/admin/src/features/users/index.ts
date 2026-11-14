import { resetDriverApplicationsForTesting } from '@/features/users/composables/use-driver-applications'
import { resetDriversForTesting } from '@/features/users/composables/use-drivers'
import { resetRidersForTesting } from '@/features/users/composables/use-riders'
import { resetStaffForTesting } from '@/features/users/composables/use-staff'

export {
  default as ApplicationDocumentViewerModal,
  type ApplicationViewerDocument,
} from '@/features/users/components/ApplicationDocumentViewerModal.vue'
export { default as ApplicationDecisionModals } from '@/features/users/components/ApplicationDecisionModals.vue'
export { default as ApplicationProfileSections } from '@/features/users/components/ApplicationProfileSections.vue'
export { useDriverApplications } from '@/features/users/composables/use-driver-applications'
export { useDrivers } from '@/features/users/composables/use-drivers'
export { useRiders } from '@/features/users/composables/use-riders'
export { useOperators, useRoles } from '@/features/users/composables/use-staff'
export type {
  DriverApplication,
  DriverRecord,
  DriverStatus,
  InviteOperatorInput,
  OperatorAccount,
  RbacRole,
  RiderRecord,
  RiderStanding,
  SaveRoleInput,
  UserActionResult,
} from '@/features/users/types'

/**
 * Resets all user, fleet, passenger, application, and RBAC stores to seed state for tests.
 */
export function resetUsersForTesting(): void {
  resetDriverApplicationsForTesting()
  resetDriversForTesting()
  resetRidersForTesting()
  resetStaffForTesting()
}
