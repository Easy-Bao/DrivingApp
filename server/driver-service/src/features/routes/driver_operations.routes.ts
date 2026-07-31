import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  driverAuthMiddleware,
  DriverAuthEnvironment,
  internalServiceMiddleware,
} from '../../shared/middleware/auth.ts';
import {
  handleApproveAdminTopup,
  handleCheckInternalEligibility,
  handleCreateAdminRestriction,
  handleCreateAdminTopupChannel,
  handleCreateCreditAdjustment,
  handleCreateCreditRefund,
  handleCreateDocumentRequirement,
  handleDisputeInternalReservation,
  handleGetAdminDriverDocuments,
  handleGetAdminDriverStatus,
  handleGetAdminLedger,
  handleGetAdminWallet,
  handleGetInternalDriverProfile,
  handleGetOwnLedger,
  handleGetOwnOperatingStatus,
  handleGetOwnTopupChannels,
  handleGetOwnWallet,
  handleLiftAdminRestriction,
  handleListAdminDrivers,
  handleListAdminRestrictions,
  handleListAdminTopupChannels,
  handleListAdminTopups,
  handleListDocumentRequirements,
  handleListOwnTopups,
  handleRejectAdminTopup,
  handleReleaseInternalReservation,
  handleReserveInternalCredits,
  handleReviewAdminDriverDocument,
  handleSettleInternalReservation,
  handleSubmitOwnTopup,
  handleUpdateAdminDriverApproval,
  handleUpdateAdminTopupChannel,
  handleUpdateDocumentRequirement,
  handleUpdateOwnOnlineStatus,
} from '../controllers/driver_operations.controller.ts';
import {
  AdminDriverListQuerySchema,
  AdminTopupListQuerySchema,
  ApprovalUpdateSchema,
  CreateDocumentRequirementSchema,
  CreateRestrictionSchema,
  CreateTopupChannelSchema,
  CreateTopupRequestSchema,
  CreditAdjustmentSchema,
  CreditDisputeSchema,
  CreditRefundSchema,
  CreditTransitionSchema,
  EligibilityRequestSchema,
  LiftRestrictionSchema,
  PaginationSchema,
  ReserveCreditSchema,
  ReviewDriverDocumentSchema,
  ReviewTopupSchema,
  UpdateDocumentRequirementSchema,
  UpdateTopupChannelSchema,
} from '../schemas/driver_operations.schema.ts';
import { UpdateOnlineStatusSchema } from '../schemas/driver.schema.ts';

export const driverOperationsRouter = new Hono<DriverAuthEnvironment>();

driverOperationsRouter.use('/me', driverAuthMiddleware);
driverOperationsRouter.use('/me/*', driverAuthMiddleware);
driverOperationsRouter.get('/me', handleGetOwnOperatingStatus);
driverOperationsRouter.post(
  '/me/online',
  zValidator('json', UpdateOnlineStatusSchema),
  handleUpdateOwnOnlineStatus,
);
driverOperationsRouter.get('/me/credits', handleGetOwnWallet);
driverOperationsRouter.get(
  '/me/credits/ledger',
  zValidator('query', PaginationSchema),
  handleGetOwnLedger,
);
driverOperationsRouter.get('/me/topup-channels', handleGetOwnTopupChannels);
driverOperationsRouter.post(
  '/me/topups',
  zValidator('json', CreateTopupRequestSchema),
  handleSubmitOwnTopup,
);
driverOperationsRouter.get(
  '/me/topups',
  zValidator('query', PaginationSchema),
  handleListOwnTopups,
);

driverOperationsRouter.use('/admin/*', internalServiceMiddleware);
driverOperationsRouter.get(
  '/admin/drivers',
  zValidator('query', AdminDriverListQuerySchema),
  handleListAdminDrivers,
);
driverOperationsRouter.get(
  '/admin/drivers/:id/operating-status',
  handleGetAdminDriverStatus,
);
driverOperationsRouter.patch(
  '/admin/drivers/:id/approval',
  zValidator('json', ApprovalUpdateSchema),
  handleUpdateAdminDriverApproval,
);
driverOperationsRouter.get(
  '/admin/document-requirements',
  handleListDocumentRequirements,
);
driverOperationsRouter.post(
  '/admin/document-requirements',
  zValidator('json', CreateDocumentRequirementSchema),
  handleCreateDocumentRequirement,
);
driverOperationsRouter.patch(
  '/admin/document-requirements/:requirementId',
  zValidator('json', UpdateDocumentRequirementSchema),
  handleUpdateDocumentRequirement,
);
driverOperationsRouter.get(
  '/admin/drivers/:id/documents',
  handleGetAdminDriverDocuments,
);
driverOperationsRouter.put(
  '/admin/drivers/:id/documents/:requirementId',
  zValidator('json', ReviewDriverDocumentSchema),
  handleReviewAdminDriverDocument,
);
driverOperationsRouter.post(
  '/admin/drivers/:id/restrictions',
  zValidator('json', CreateRestrictionSchema),
  handleCreateAdminRestriction,
);
driverOperationsRouter.get(
  '/admin/drivers/:id/restrictions',
  handleListAdminRestrictions,
);
driverOperationsRouter.post(
  '/admin/restrictions/:restrictionId/lift',
  zValidator('json', LiftRestrictionSchema),
  handleLiftAdminRestriction,
);
driverOperationsRouter.get(
  '/admin/drivers/:id/credits',
  handleGetAdminWallet,
);
driverOperationsRouter.get(
  '/admin/drivers/:id/credits/ledger',
  zValidator('query', PaginationSchema),
  handleGetAdminLedger,
);
driverOperationsRouter.post(
  '/admin/drivers/:id/credits/adjustments',
  zValidator('json', CreditAdjustmentSchema),
  handleCreateCreditAdjustment,
);
driverOperationsRouter.post(
  '/admin/drivers/:id/credits/refunds',
  zValidator('json', CreditRefundSchema),
  handleCreateCreditRefund,
);
driverOperationsRouter.get(
  '/admin/topup-channels',
  handleListAdminTopupChannels,
);
driverOperationsRouter.post(
  '/admin/topup-channels',
  zValidator('json', CreateTopupChannelSchema),
  handleCreateAdminTopupChannel,
);
driverOperationsRouter.patch(
  '/admin/topup-channels/:channelId',
  zValidator('json', UpdateTopupChannelSchema),
  handleUpdateAdminTopupChannel,
);
driverOperationsRouter.get(
  '/admin/topups',
  zValidator('query', AdminTopupListQuerySchema),
  handleListAdminTopups,
);
driverOperationsRouter.post(
  '/admin/topups/:requestId/approve',
  zValidator('json', ReviewTopupSchema),
  handleApproveAdminTopup,
);
driverOperationsRouter.post(
  '/admin/topups/:requestId/reject',
  zValidator('json', ReviewTopupSchema),
  handleRejectAdminTopup,
);

driverOperationsRouter.use('/internal/*', internalServiceMiddleware);
driverOperationsRouter.get(
  '/internal/:id/profile',
  handleGetInternalDriverProfile,
);
driverOperationsRouter.post(
  '/internal/eligibility',
  zValidator('json', EligibilityRequestSchema),
  handleCheckInternalEligibility,
);
driverOperationsRouter.post(
  '/internal/credits/reservations',
  zValidator('json', ReserveCreditSchema),
  handleReserveInternalCredits,
);
driverOperationsRouter.post(
  '/internal/credits/reservations/:rideId/settle',
  zValidator('json', CreditTransitionSchema),
  handleSettleInternalReservation,
);
driverOperationsRouter.post(
  '/internal/credits/reservations/:rideId/release',
  zValidator('json', CreditTransitionSchema),
  handleReleaseInternalReservation,
);
driverOperationsRouter.post(
  '/internal/credits/reservations/:rideId/dispute',
  zValidator('json', CreditDisputeSchema),
  handleDisputeInternalReservation,
);
