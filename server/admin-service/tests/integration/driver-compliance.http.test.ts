import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';

const databaseDescribe = process.env.RUN_ADMIN_COMPLIANCE_INTEGRATION === '1'
  ? describe
  : describe.skip;

function requireDisposableDatabase() {
  const value = process.env.DATABASE_URL;
  const url = value ? new URL(value) : null;
  if (
    !url
    || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)
    || url.pathname !== '/adm007_compliance_test'
  ) {
    throw new Error(
      'RUN_ADMIN_COMPLIANCE_INTEGRATION requires the local adm007_compliance_test database.',
    );
  }
}

databaseDescribe('ADM-007 Admin to Driver compliance HTTP flow', () => {
  test('keeps approval separate and rejects missing or expired documents', async () => {
    requireDisposableDatabase();
    const jwtSecret = 'adm007-synthetic-jwt-key';
    const internalToken = 'adm007-synthetic-internal-token';
    process.env.JWT_SECRET = jwtSecret;
    process.env.INTERNAL_SERVICE_TOKEN = internalToken;

    const cleanup: Array<() => unknown | Promise<unknown>> = [];
    try {
      const { app: driverApp } = await import('../../../driver-service/src/index.ts');

      const driverServer = Bun.serve({
        hostname: '127.0.0.1',
        port: 0,
        fetch: driverApp.fetch,
      });
      cleanup.unshift(() => driverServer.stop(true));
      process.env.DRIVER_SERVICE_URL = driverServer.url.toString();

      const [
        { adminRouter },
        { globalErrorHandler },
        { postgresClient: adminSql },
      ] = await Promise.all([
        import('../../src/features/routes/admin.routes.ts'),
        import('../../src/shared/middleware/error.ts'),
        import('../../src/shared/drizzle.ts'),
      ]);
      cleanup.push(() => adminSql.end());

      const adminApp = new Hono();
      adminApp.onError(globalErrorHandler);
      adminApp.route('/admin', adminRouter);
      const adminServer = Bun.serve({
        hostname: '127.0.0.1',
        port: 0,
        fetch: adminApp.fetch,
      });
      cleanup.unshift(() => adminServer.stop(true));

      const driverId = 'drv_adm007_synthetic';
      const adminId = 'adm_adm007_synthetic';
      await adminSql`
        truncate table
          driver_idempotency_records,
          driver_credit_ledger,
          driver_credit_reservations,
          driver_topup_requests,
          driver_topup_channels,
          driver_credit_wallets,
          driver_account_restrictions,
          driver_document_checks,
          driver_document_requirements,
          drivers
        restart identity cascade
      `;
      await adminSql`
        truncate table admin_audit_events, admin_mutation_results
        restart identity cascade
      `;
      await adminSql`
        insert into drivers (
          id,
          name,
          email,
          phone,
          vehicle_type,
          plate_number,
          password_hash,
          is_verified
        ) values (
          ${driverId},
          'Synthetic Compliance Driver',
          'adm007-driver@example.test',
          '09990000000',
          'Bao Bao',
          'ADM 007',
          'synthetic-not-a-password-hash',
          true
        )
      `;

      const adminToken = await sign({
        sub: adminId,
        email: 'adm007-owner@example.test',
        role: 'admin',
        exp: Math.floor(Date.now() / 1_000) + 300,
      }, jwtSecret, 'HS256');
      const driverToken = await sign({
        sub: driverId,
        email: 'adm007-driver@example.test',
        role: 'driver',
        exp: Math.floor(Date.now() / 1_000) + 300,
      }, jwtSecret, 'HS256');

      const adminMutation = (
        path: string,
        requestId: string,
        body: Record<string, unknown>,
        method = 'POST',
      ) => fetch(new URL(path, adminServer.url), {
        method,
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
          'Idempotency-Key': requestId,
        },
        body: JSON.stringify(body),
      });
      const setOnline = (isOnline: boolean) => fetch(
        new URL('/drivers/me/online', driverServer.url),
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${driverToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ isOnline }),
        },
      );
      const reserveRide = (rideId: string, includeInternalToken = true) => fetch(
        new URL('/drivers/internal/credits/reservations', driverServer.url),
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Idempotency-Key': `${rideId}-reservation`,
            ...(includeInternalToken
              ? { 'X-Internal-Service-Token': internalToken }
              : {}),
          },
          body: JSON.stringify({
            driverId,
            rideId,
            fareCentavos: 10_000,
            commissionBasisPoints: 1_000,
          }),
        },
      );

      const pendingOnline = await setOnline(true);
      expect(pendingOnline.status).toBe(409);
      expect(await pendingOnline.json()).toMatchObject({
        code: 'DRIVER_NOT_APPROVED',
      });
      const [emailVerifiedDriver] = await adminSql`
        select is_verified, approval_status
        from drivers
        where id = ${driverId}
      `;
      expect(emailVerifiedDriver).toMatchObject({
        is_verified: true,
        approval_status: 'pending',
      });

      const missingApprovalReason = await adminMutation(
        `/admin/v1/drivers/${driverId}/approval`,
        'approval-missing-reason',
        { status: 'approved' },
      );
      expect(missingApprovalReason.status).toBe(400);

      const createdResponse = await adminMutation(
        '/admin/v1/document-requirements',
        'requirement-create',
        {
          name: 'Synthetic Franchise Permit',
          requires_expiry: false,
          is_active: false,
          reason: 'Create the synthetic compliance requirement',
        },
      );
      expect(createdResponse.status).toBe(201);
      const created = await createdResponse.json() as {
        id: string;
        isActive: boolean;
        requiresExpiry: boolean;
      };
      expect(created).toMatchObject({
        isActive: false,
        requiresExpiry: false,
      });

      const updatedResponse = await adminMutation(
        `/admin/v1/document-requirements/${created.id}`,
        'requirement-update',
        {
          is_active: true,
          requires_expiry: true,
          reason: 'Activate the requirement with expiry enforcement',
        },
        'PATCH',
      );
      expect(updatedResponse.status).toBe(200);
      expect(await updatedResponse.json()).toMatchObject({
        id: created.id,
        isActive: true,
        requiresExpiry: true,
      });

      const approvalResponse = await adminMutation(
        `/admin/v1/drivers/${driverId}/approval`,
        'driver-approval',
        {
          status: 'approved',
          reason: 'Synthetic identity review completed',
        },
      );
      expect(approvalResponse.status).toBe(200);
      expect(await approvalResponse.json()).toMatchObject({
        id: driverId,
        isVerified: true,
        approvalStatus: 'approved',
        approvalReviewedBy: adminId,
      });

      const missingDocumentOnline = await setOnline(true);
      expect(missingDocumentOnline.status).toBe(409);
      expect(await missingDocumentOnline.json()).toMatchObject({
        code: 'DRIVER_DOCUMENTS_INCOMPLETE',
      });
      const unauthenticatedReservation = await reserveRide(
        'ride-missing-internal-token',
        false,
      );
      expect(unauthenticatedReservation.status).toBe(401);
      expect(await unauthenticatedReservation.json()).toMatchObject({
        code: 'INTERNAL_TOKEN_REQUIRED',
      });
      const missingDocumentReservation = await reserveRide('ride-missing-document');
      expect(missingDocumentReservation.status).toBe(409);
      expect(await missingDocumentReservation.json()).toMatchObject({
        code: 'DRIVER_DOCUMENTS_INCOMPLETE',
      });

      const missingReviewReason = await adminMutation(
        `/admin/v1/drivers/${driverId}/documents/${created.id}`,
        'document-review-missing-reason',
        {
          status: 'verified',
          expires_at: new Date(Date.now() + 86_400_000).toISOString(),
        },
        'PUT',
      );
      expect(missingReviewReason.status).toBe(400);

      const expiry = new Date(Date.now() + 86_400_000).toISOString();
      const reviewResponse = await adminMutation(
        `/admin/v1/drivers/${driverId}/documents/${created.id}`,
        'document-review',
        {
          status: 'verified',
          expires_at: expiry,
          notes: 'Synthetic permit inspected',
          reason: 'Verify the synthetic permit metadata',
        },
        'PUT',
      );
      expect(reviewResponse.status).toBe(200);
      expect(await reviewResponse.json()).toMatchObject({
        driverId,
        requirementId: created.id,
        status: 'verified',
        expiresAt: expiry,
        notes: 'Synthetic permit inspected',
        reviewedBy: adminId,
      });

      await adminSql`
        insert into driver_credit_wallets (driver_id, balance_centavos)
        values (${driverId}, 1_000)
        on conflict (driver_id) do update
        set balance_centavos = excluded.balance_centavos
      `;
      expect((await setOnline(true)).status).toBe(200);
      expect((await reserveRide('ride-compliant')).status).toBe(201);

      await adminSql`
        update driver_document_checks
        set expires_at = ${new Date(Date.now() - 1_000).toISOString()}
        where driver_id = ${driverId}
          and requirement_id = ${created.id}
      `;
      expect((await setOnline(false)).status).toBe(200);
      const expiredOnline = await setOnline(true);
      expect(expiredOnline.status).toBe(409);
      expect(await expiredOnline.json()).toMatchObject({
        code: 'DRIVER_DOCUMENTS_INCOMPLETE',
      });
      const expiredReservation = await reserveRide('ride-expired-document');
      expect(expiredReservation.status).toBe(409);
      expect(await expiredReservation.json()).toMatchObject({
        code: 'DRIVER_DOCUMENTS_INCOMPLETE',
      });

      const audits = await adminSql`
        select action, reason, outcome, actor_admin_id
        from admin_audit_events
        order by created_at
      `;
      expect(audits).toHaveLength(4);
      expect(audits).toEqual(expect.arrayContaining([
        expect.objectContaining({
          action: 'driver.document_requirement.created',
          reason: 'Create the synthetic compliance requirement',
        }),
        expect.objectContaining({
          action: 'driver.document_requirement.updated',
          reason: 'Activate the requirement with expiry enforcement',
        }),
        expect.objectContaining({
          action: 'driver.approval.updated',
          reason: 'Synthetic identity review completed',
        }),
        expect.objectContaining({
          action: 'driver.document.reviewed',
          reason: 'Verify the synthetic permit metadata',
        }),
      ]));
      expect(audits.every((audit) => (
        audit.outcome === 'succeeded' && audit.actor_admin_id === adminId
      ))).toBe(true);
    } finally {
      for (const stop of cleanup) await stop();
    }
  });
});
