import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { AuditOutcome, CaseStatus, CaseTargetType } from '../../db/schema.ts';
import { AdminVariables } from '../../shared/middleware/auth.ts';
import { AdminRepository } from '../repositories/admin.repository.ts';
import { AdminService } from '../services/admin.service.ts';

const adminService = new AdminService(new AdminRepository());
type AdminContext = Context<{ Variables: AdminVariables }>;

function mutation(context: AdminContext) {
  return {
    adminId: context.get('adminId'),
    requestId: (context.req.header('Idempotency-Key') ?? '').trim(),
  };
}

function requiredParam(context: Context, name: string): string {
  const value = context.req.param(name);
  if (!value) throw new HTTPException(400, { message: 'INVALID_ROUTE_PARAMETER' });
  return value;
}

export async function handleOverview(context: AdminContext) {
  return context.json(await adminService.overview());
}

export async function handleListCases(context: AdminContext) {
  const query = context.req.valid('query' as never) as {
    page: number;
    limit: number;
    status?: CaseStatus;
    from?: string;
    to?: string;
  };
  return context.json(await adminService.listCases(
    query.status,
    query.limit,
    (query.page - 1) * query.limit,
    query.from,
    query.to,
  ));
}

export async function handleCreateCase(context: AdminContext) {
  const body = context.req.valid('json' as never) as {
    target_type: CaseTargetType;
    target_id: string;
    ride_id?: string | null;
    category: string;
    notes: string;
    reason: string;
  };
  return context.json(await adminService.createCase({
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleUpdateCase(context: AdminContext) {
  const body = context.req.valid('json' as never) as {
    status: CaseStatus;
    resolution?: string | null;
    reason: string;
  };
  return context.json(await adminService.updateCase({
    caseId: requiredParam(context, 'caseId'),
    status: body.status,
    resolution: body.resolution,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleAudits(context: AdminContext) {
  const query = context.req.valid('query' as never) as {
    page: number;
    limit: number;
    status?: AuditOutcome;
    from?: string;
    to?: string;
  };
  return context.json(await adminService.audits(
    query.limit,
    (query.page - 1) * query.limit,
    query.status,
    query.from,
    query.to,
  ));
}

export async function handleReport(context: AdminContext) {
  const type = requiredParam(context, 'type');
  const csv = await adminService.report(type, new URL(context.req.url).searchParams);
  context.header('Content-Type', 'text/csv; charset=utf-8');
  context.header('Content-Disposition', `attachment; filename="easyride-${type}.csv"`);
  return context.body(csv);
}
