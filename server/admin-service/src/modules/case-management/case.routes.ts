import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  AdminVariables,
  adminAuthMiddleware,
} from '../../common/middleware/auth.ts';
import {
  CaseListQuerySchema,
  CaseParamSchema,
  ComplaintCreateSchema,
  ComplaintUpdateSchema,
} from './case.schema.ts';
import { CaseService } from './case.service.ts';

const caseService = new CaseService();

function mutation(context: {
  get(name: 'adminId'): string;
  req: { header(name: string): string | undefined };
}) {
  return {
    adminId: context.get('adminId'),
    requestId: (context.req.header('Idempotency-Key') ?? '').trim(),
  };
}

export const caseRoutes = new Hono<{ Variables: AdminVariables }>();

caseRoutes.use('*', adminAuthMiddleware);
caseRoutes.get('/overview', async (context) => context.json(await caseService.overview()));
caseRoutes.get(
  '/cases',
  zValidator('query', CaseListQuerySchema),
  async (context) => {
    const query = context.req.valid('query');
    return context.json(await caseService.list(
      query.status,
      query.limit,
      (query.page - 1) * query.limit,
      query.from,
      query.to,
    ));
  },
);
caseRoutes.post(
  '/cases',
  zValidator('json', ComplaintCreateSchema),
  async (context) => {
    const body = context.req.valid('json');
    return context.json(await caseService.create({
      payload: body,
      reason: body.reason,
      ...mutation(context),
    }), 201);
  },
);
caseRoutes.patch(
  '/cases/:caseId',
  zValidator('param', CaseParamSchema),
  zValidator('json', ComplaintUpdateSchema),
  async (context) => {
    const body = context.req.valid('json');
    return context.json(await caseService.update({
      caseId: context.req.valid('param').caseId,
      status: body.status,
      resolution: body.resolution,
      reason: body.reason,
      ...mutation(context),
    }));
  },
);
