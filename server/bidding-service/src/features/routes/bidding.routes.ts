import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleComputeFare,
  handleCreateSession,
  handleGetActiveSessions,
  handleGetOffers,
  handlePlaceOffer,
  handleAcceptOffer,
  handleAcceptOfferBody,
  handleCancelSession,
  handleCancelOffer,
  handleGetSessionDetails,
  handleManualAssignment,
} from '../controllers/bidding.controller.ts';
import {
  AcceptOfferSchema,
  CreateBidSessionSchema,
  EstimateFareSchema,
  ManualAssignmentSchema,
  PlaceOfferSchema,
} from '../schemas/bidding.schema.ts';
import {
  authOrInternalMiddleware,
  authMiddleware,
  AuthVariables,
  internalAuthMiddleware,
  requireAnyRole,
  requireRole,
} from '../../shared/middleware/auth.ts';

export const biddingRouter = new Hono<{ Variables: AuthVariables }>();

biddingRouter.post(
  '/fare',
  zValidator('json', EstimateFareSchema),
  handleComputeFare,
);
biddingRouter.post(
  '/',
  authMiddleware,
  requireRole('passenger'),
  zValidator('json', CreateBidSessionSchema),
  handleCreateSession,
);
biddingRouter.post(
  '/internal/:sessionId/assign',
  internalAuthMiddleware,
  zValidator('json', ManualAssignmentSchema),
  handleManualAssignment,
);
biddingRouter.get(
  '/active',
  authOrInternalMiddleware,
  requireAnyRole('driver', 'internal'),
  handleGetActiveSessions,
);
biddingRouter.get(
  '/:sessionId',
  authOrInternalMiddleware,
  requireAnyRole('passenger', 'driver', 'internal'),
  handleGetSessionDetails,
);
biddingRouter.get(
  '/:sessionId/offers',
  authOrInternalMiddleware,
  requireAnyRole('passenger', 'internal'),
  handleGetOffers,
);
biddingRouter.post(
  '/:sessionId/offer',
  authMiddleware,
  requireRole('driver'),
  zValidator('json', PlaceOfferSchema),
  handlePlaceOffer,
);
biddingRouter.post(
  '/:sessionId/offers/:offerId/accept',
  authMiddleware,
  requireRole('passenger'),
  handleAcceptOffer,
);
biddingRouter.post(
  '/:sessionId/accept',
  authMiddleware,
  requireRole('passenger'),
  zValidator('json', AcceptOfferSchema),
  handleAcceptOfferBody,
);
biddingRouter.post(
  '/:sessionId/cancel',
  authMiddleware,
  requireRole('passenger'),
  handleCancelSession,
);
biddingRouter.delete(
  '/:sessionId',
  authMiddleware,
  requireRole('passenger'),
  handleCancelSession,
);
biddingRouter.post(
  '/:sessionId/cancel-offer',
  authMiddleware,
  requireRole('driver'),
  handleCancelOffer,
);
