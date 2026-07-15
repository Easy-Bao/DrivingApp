/**
 * Routing definitions mapping bidding endpoints to controller actions, with input validation.
 */
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleComputeFare,
  handleCreateSession,
  handleGetActiveSessions,
  handleGetOffers,
  handlePlaceOffer,
  handleAcceptOffer,
  handleCancelSession,
  handleCancelOffer,
  handleGetSessionDetails,
} from '../controllers/bidding.controller.ts';
import {
  CreateBidSessionSchema,
  PlaceOfferSchema,
} from '../schemas/bidding.schema.ts';

export const biddingRouter = new Hono();

biddingRouter.post('/fare', handleComputeFare);
biddingRouter.post('/', zValidator('json', CreateBidSessionSchema), handleCreateSession);
biddingRouter.get('/active', handleGetActiveSessions);
biddingRouter.get('/:sessionId', handleGetSessionDetails);
biddingRouter.get('/:sessionId/offers', handleGetOffers);
biddingRouter.post('/:sessionId/offer', zValidator('json', PlaceOfferSchema), handlePlaceOffer);
biddingRouter.post('/:sessionId/offers/:offerId/accept', handleAcceptOffer);
biddingRouter.post('/:sessionId/cancel', handleCancelSession);
biddingRouter.post('/:sessionId/cancel-offer', handleCancelOffer);
