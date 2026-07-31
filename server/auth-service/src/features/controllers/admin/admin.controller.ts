import { Context } from 'hono';
import {
  AdminAuthenticationError,
  AdminAuthenticationService,
} from '../../services/admin/admin.service.ts';
import { DrizzleAdminAccountRepository } from '../../repositories/admin/admin.repository.ts';
import type { LoginAdminInput } from '../../schemas/admin/admin.zod.ts';
import type { VerifyTokenInput } from '../../schemas/common/common.zod.ts';
import { JsonWebTokenService } from '../../services/common/jwt.service.ts';

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

export function handleVerifyAdminSession(context: Context) {
  try {
    const { token } = context.req.valid('json' as never) as VerifyTokenInput;
    const session = JsonWebTokenService.verifyAdminJsonWebToken(token);
    return context.json({ success: true, data: session });
  } catch {
    return context.json(
      {
        success: false,
        error: {
          code: 'INVALID_ADMIN_SESSION',
          message: 'Admin authentication is invalid or expired.',
        },
      },
      401,
    );
  }
}
