import { Context } from 'hono';
import {
  AdminAuthenticationError,
  AdminAuthenticationService,
} from '../../services/admin/admin.service.ts';
import { DrizzleAdminAccountRepository } from '../../repositories/admin/admin.repository.ts';
import type { LoginAdminInput } from '../../schemas/admin/admin.zod.ts';

const adminAuthenticationService = new AdminAuthenticationService(
  new DrizzleAdminAccountRepository(),
);

export async function handleAuthenticateAdmin(context: Context) {
  try {
    const body = context.req.valid('json' as never) as LoginAdminInput;
    const result = await adminAuthenticationService.authenticateOwner(body);
    return context.json({ success: true, data: result });
  } catch (error: unknown) {
    if (error instanceof AdminAuthenticationError) {
      return context.json(
        {
          success: false,
          error: {
            code: error.code,
            message: error.message,
          },
        },
        error.status,
      );
    }

    return context.json(
      {
        success: false,
        error: {
          code: 'ADMIN_AUTHENTICATION_FAILED',
          message: 'Admin authentication failed',
        },
      },
      500,
    );
  }
}
