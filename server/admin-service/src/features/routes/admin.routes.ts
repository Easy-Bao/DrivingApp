import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleAudits,
  handleCreateCase,
  handleCreateCreditAdjustment,
  handleCreateCreditRefund,
  handleCreateDocumentRequirement,
  handleCreateTopUpChannel,
  handleDispatch,
  handleGetDriver,
  handleInternalCommission,
  handleInternalZoneCheck,
  handleListCases,
  handleListDocumentRequirements,
  handleListDrivers,
  handleListTopUps,
  handleListTopUpChannels,
  handleListZones,
  handleManualAssignment,
  handleOverview,
  handlePricing,
  handleReport,
  handleRestrictAccount,
  handleLiftRestriction,
  handleReviewDriverDocument,
  handleReviewTopUp,
  handleScheduleCommission,
  handleUpdateFareRule,
  handleUpdateCase,
  handleUpdateDriverApproval,
  handleUpdateDocumentRequirement,
  handleUpdateTopUpChannel,
  handleUpdateZone,
} from '../controllers/admin.controller.ts';
import {
  ApprovalSchema,
  AuditListQuerySchema,
  CaseListQuerySchema,
  CommissionPolicySchema,
  ComplaintCreateSchema,
  ComplaintUpdateSchema,
  CreditAdjustmentSchema,
  CreditRefundSchema,
  DocumentRequirementSchema,
  DocumentRequirementUpdateSchema,
  DocumentReviewSchema,
  FareRuleSchema,
  ManualAssignmentSchema,
  RestrictionSchema,
  RestrictionLiftSchema,
  TopUpChannelCreateSchema,
  TopUpChannelUpdateSchema,
  TopUpReviewSchema,
  ZoneCheckSchema,
  ZoneUpdateSchema,
} from '../schemas/admin.schema.ts';
import {
  AdminVariables,
  adminAuthMiddleware,
  internalAuthMiddleware,
} from '../../shared/middleware/auth.ts';

export const adminRouter = new Hono<{ Variables: AdminVariables }>();

adminRouter.use('/v1/*', adminAuthMiddleware);
adminRouter.get('/v1/overview', handleOverview);
adminRouter.get('/v1/drivers', handleListDrivers);
adminRouter.get('/v1/drivers/:driverId', handleGetDriver);
adminRouter.post(
  '/v1/drivers/:driverId/approval',
  zValidator('json', ApprovalSchema),
  handleUpdateDriverApproval,
);
adminRouter.get('/v1/document-requirements', handleListDocumentRequirements);
adminRouter.post(
  '/v1/document-requirements',
  zValidator('json', DocumentRequirementSchema),
  handleCreateDocumentRequirement,
);
adminRouter.patch(
  '/v1/document-requirements/:requirementId',
  zValidator('json', DocumentRequirementUpdateSchema),
  handleUpdateDocumentRequirement,
);
adminRouter.put(
  '/v1/drivers/:driverId/documents/:requirementId',
  zValidator('json', DocumentReviewSchema),
  handleReviewDriverDocument,
);
adminRouter.post(
  '/v1/drivers/:driverId/credits/adjustments',
  zValidator('json', CreditAdjustmentSchema),
  handleCreateCreditAdjustment,
);
adminRouter.post(
  '/v1/drivers/:driverId/credits/refunds',
  zValidator('json', CreditRefundSchema),
  handleCreateCreditRefund,
);
adminRouter.get('/v1/topups', handleListTopUps);
adminRouter.post(
  '/v1/topups/:topUpId/review',
  zValidator('json', TopUpReviewSchema),
  handleReviewTopUp,
);
adminRouter.get('/v1/topup-channels', handleListTopUpChannels);
adminRouter.post(
  '/v1/topup-channels',
  zValidator('json', TopUpChannelCreateSchema),
  handleCreateTopUpChannel,
);
adminRouter.patch(
  '/v1/topup-channels/:channelId',
  zValidator('json', TopUpChannelUpdateSchema),
  handleUpdateTopUpChannel,
);
adminRouter.get('/v1/dispatch', handleDispatch);
adminRouter.post(
  '/v1/dispatch/assign',
  zValidator('json', ManualAssignmentSchema),
  handleManualAssignment,
);
adminRouter.get('/v1/pricing', handlePricing);
adminRouter.post(
  '/v1/pricing/commission',
  zValidator('json', CommissionPolicySchema),
  handleScheduleCommission,
);
adminRouter.put(
  '/v1/pricing/:serviceType',
  zValidator('json', FareRuleSchema),
  handleUpdateFareRule,
);
adminRouter.get('/v1/zones', handleListZones);
adminRouter.put(
  '/v1/zones/:psgcCode',
  zValidator('json', ZoneUpdateSchema),
  handleUpdateZone,
);
adminRouter.get(
  '/v1/cases',
  zValidator('query', CaseListQuerySchema),
  handleListCases,
);
adminRouter.post(
  '/v1/cases',
  zValidator('json', ComplaintCreateSchema),
  handleCreateCase,
);
adminRouter.patch(
  '/v1/cases/:caseId',
  zValidator('json', ComplaintUpdateSchema),
  handleUpdateCase,
);
adminRouter.post(
  '/v1/restrictions',
  zValidator('json', RestrictionSchema),
  handleRestrictAccount,
);
adminRouter.post(
  '/v1/restrictions/:targetType/:restrictionId/lift',
  zValidator('json', RestrictionLiftSchema),
  handleLiftRestriction,
);
adminRouter.get(
  '/v1/audits',
  zValidator('query', AuditListQuerySchema),
  handleAudits,
);
adminRouter.get(
  '/v1/audit',
  zValidator('query', AuditListQuerySchema),
  handleAudits,
);
adminRouter.get('/v1/reports/:type', handleReport);

adminRouter.use('/internal/*', internalAuthMiddleware);
adminRouter.post(
  '/internal/zones/check',
  zValidator('json', ZoneCheckSchema),
  handleInternalZoneCheck,
);
adminRouter.get('/internal/pricing/commission', handleInternalCommission);
