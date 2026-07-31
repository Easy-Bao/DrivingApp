import { error, fail, redirect, type RequestEvent } from '@sveltejs/kit';
import { isAdminSection, type AdminSection } from '$lib/admin';
import { AdminApiError, adminApi, adminMutation } from '$lib/server/admin-api';
import { clearAdminSession } from '$lib/server/session';
import type { Actions, PageServerLoad } from './$types';

const SECTION_ENDPOINTS: Record<AdminSection, string[]> = {
  overview: ['/admin/v1/overview'],
  drivers: ['/admin/v1/drivers?limit=50', '/admin/v1/document-requirements'],
  dispatch: ['/admin/v1/dispatch?limit=50'],
  finance: [
    '/admin/v1/topups?limit=50',
    '/admin/v1/pricing',
    '/admin/v1/topup-channels',
  ],
  zones: ['/admin/v1/zones?limit=100'],
  cases: ['/admin/v1/cases?limit=50'],
  reports: ['/admin/v1/audits?limit=100'],
};

export const load: PageServerLoad = async ({ params, fetch, locals, cookies, url }) => {
  if (!isAdminSection(params.section)) {
    error(404, 'Admin section not found.');
  }

  const filters = {
    status: url.searchParams.get('status') ?? '',
    from: url.searchParams.get('from') ?? '',
    to: url.searchParams.get('to') ?? '',
    page: Math.max(1, Number(url.searchParams.get('page') ?? 1) || 1),
  };
  const query = new URLSearchParams();
  if (filters.status) {
    if (params.section === 'drivers') {
      query.set('approvalStatus', filters.status);
    } else if (
      params.section !== 'reports'
      || ['succeeded', 'failed'].includes(filters.status)
    ) {
      query.set('status', filters.status);
    }
  }
  if (filters.from) query.set('from', filters.from);
  if (filters.to) query.set('to', filters.to);
  query.set('page', String(filters.page));

  try {
    const [payload, extra = null, tertiary = null] = await Promise.all(
      SECTION_ENDPOINTS[params.section].map((endpoint, index) =>
        adminApi<unknown>(
          fetch,
          index === 0 ? `${endpoint}${endpoint.includes('?') ? '&' : '?'}${query}` : endpoint,
          locals.adminToken,
        ),
      ),
    );

    return {
      section: params.section,
      payload,
      extra,
      tertiary,
      lastUpdated: new Date().toISOString(),
      apiError: null,
      filters,
    };
  } catch (caught) {
    if (caught instanceof AdminApiError && caught.status === 401) {
      clearAdminSession(cookies, url.protocol === 'https:');
      redirect(303, '/login');
    }

    return {
      section: params.section,
      payload: null,
      extra: null,
      tertiary: null,
      lastUpdated: new Date().toISOString(),
      filters,
      apiError:
        caught instanceof AdminApiError
          ? `${caught.code}: ${caught.message}`
          : 'ADMIN_API_ERROR: The dashboard data could not be loaded.',
    };
  }
};

function formValues(form: FormData): Record<string, string> {
  return Object.fromEntries(
    [...form.entries()].map(([key, value]) => [key, typeof value === 'string' ? value.trim() : '']),
  );
}

function missing(values: Record<string, string>, ...fields: string[]): string | null {
  return fields.find((field) => !values[field]) ?? null;
}

function isoDate(value: string): string | null {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

async function mutate(
  event: RequestEvent,
  path: string,
  method: 'POST' | 'PUT' | 'PATCH',
  body: Record<string, unknown>,
  success: string,
) {
  try {
    await adminMutation(event.fetch, path, event.locals.adminToken, method, body);
    return { success: true, message: success };
  } catch (caught) {
    if (caught instanceof AdminApiError && caught.status === 401) {
      clearAdminSession(event.cookies, event.url.protocol === 'https:');
      redirect(303, '/login');
    }

    const status =
      caught instanceof AdminApiError && caught.status >= 400 && caught.status <= 599
        ? caught.status
        : 500;
    return fail(status, {
      success: false,
      message: caught instanceof AdminApiError ? caught.message : 'The change could not be saved.',
    });
  }
}

export const actions: Actions = {
  driverApproval: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'driverId', 'status', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/drivers/${encodeURIComponent(values.driverId)}/approval`,
      'POST',
      { status: values.status, reason: values.reason },
      'Driver approval updated.',
    );
  },

  documentVerification: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'driverId', 'documentId', 'status', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const expiresAt = values.expiresAt ? isoDate(`${values.expiresAt}T00:00:00Z`) : null;
    if (values.expiresAt && !expiresAt) {
      return fail(400, { message: 'Document expiry is invalid.' });
    }
    return mutate(
      event,
      `/admin/v1/drivers/${encodeURIComponent(values.driverId)}/documents/${encodeURIComponent(values.documentId)}`,
      'PUT',
      {
        status: values.status,
        expires_at: expiresAt,
        notes: values.notes || null,
        reason: values.reason,
      },
      'Document checklist updated.',
    );
  },

  documentRequirement: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'name', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      '/admin/v1/document-requirements',
      'POST',
      {
        name: values.name,
        requires_expiry: values.requiresExpiry === 'true',
        is_active: true,
        reason: values.reason,
      },
      'Document requirement added.',
    );
  },

  documentRequirementUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'requirementId', 'requiresExpiry', 'isActive', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/document-requirements/${encodeURIComponent(values.requirementId)}`,
      'PATCH',
      {
        requires_expiry: values.requiresExpiry === 'true',
        is_active: values.isActive === 'true',
        reason: values.reason,
      },
      'Document requirement updated.',
    );
  },

  manualAssignment: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'requestId', 'driverId', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      '/admin/v1/dispatch/assign',
      'POST',
      {
        session_id: values.requestId,
        driver_id: values.driverId,
        reason: values.reason,
      },
      'Driver assigned through the standard eligibility checks.',
    );
  },

  topupReview: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'topupId', 'status', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/topups/${encodeURIComponent(values.topupId)}/review`,
      'POST',
      { status: values.status, reason: values.reason },
      `Top-up ${values.status}.`,
    );
  },

  creditAdjustment: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'driverId', 'amountCentavos', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const amountCentavos = Number(values.amountCentavos);
    if (!Number.isSafeInteger(amountCentavos) || amountCentavos === 0) {
      return fail(400, { message: 'Adjustment must be a non-zero whole centavo amount.' });
    }
    return mutate(
      event,
      `/admin/v1/drivers/${encodeURIComponent(values.driverId)}/credits/adjustments`,
      'POST',
      { amount_centavos: amountCentavos, reason: values.reason },
      'Credit adjustment recorded in the immutable ledger.',
    );
  },

  creditRefund: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'driverId', 'amountCentavos', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const amountCentavos = Number(values.amountCentavos);
    if (!Number.isSafeInteger(amountCentavos) || amountCentavos <= 0) {
      return fail(400, { message: 'Refund must be a positive whole centavo amount.' });
    }
    return mutate(
      event,
      `/admin/v1/drivers/${encodeURIComponent(values.driverId)}/credits/refunds`,
      'POST',
      { amount_centavos: amountCentavos, reason: values.reason },
      'Unused purchased credit refunded.',
    );
  },

  topupChannelCreate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'name', 'accountName', 'accountReference', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      '/admin/v1/topup-channels',
      'POST',
      {
        name: values.name,
        account_name: values.accountName,
        account_reference: values.accountReference,
        instructions: values.instructions || null,
        reason: values.reason,
      },
      'Top-up channel created.',
    );
  },

  topupChannelUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(
      values,
      'channelId',
      'name',
      'accountName',
      'accountReference',
      'isActive',
      'reason',
    );
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/topup-channels/${encodeURIComponent(values.channelId)}`,
      'PATCH',
      {
        name: values.name,
        account_name: values.accountName,
        account_reference: values.accountReference,
        instructions: values.instructions || null,
        is_active: values.isActive === 'true',
        reason: values.reason,
      },
      'Top-up channel updated.',
    );
  },

  pricingUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'commissionBasisPoints', 'effectiveAt', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const commissionBasisPoints = Number(values.commissionBasisPoints);
    if (!Number.isInteger(commissionBasisPoints) || commissionBasisPoints < 0 || commissionBasisPoints > 5000) {
      return fail(400, { message: 'Commission must be between 0 and 5,000 basis points.' });
    }
    const effectiveAt = isoDate(values.effectiveAt);
    if (!effectiveAt) {
      return fail(400, { message: 'Commission effective time is invalid.' });
    }
    return mutate(
      event,
      '/admin/v1/pricing/commission',
      'POST',
      {
        rate_basis_points: commissionBasisPoints,
        effective_at: effectiveAt,
        reason: values.reason,
      },
      'Pricing schedule updated.',
    );
  },

  fareRuleUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const required = [
      'serviceType',
      'baseFare',
      'perKmRate',
      'perMinuteRate',
      'minimumFare',
      'surgeMultiplier',
      'isActive',
      'reason',
    ];
    const empty = missing(values, ...required);
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const numericFields = [
      'baseFare',
      'perKmRate',
      'perMinuteRate',
      'minimumFare',
      'surgeMultiplier',
    ] as const;
    const numbers = Object.fromEntries(
      numericFields.map((field) => [field, Number(values[field])]),
    ) as Record<(typeof numericFields)[number], number>;
    if (
      numericFields.some((field) => !Number.isFinite(numbers[field]))
      || numbers.baseFare < 0
      || numbers.perKmRate < 0
      || numbers.perMinuteRate < 0
      || numbers.minimumFare < 0
      || numbers.surgeMultiplier < 1
      || numbers.surgeMultiplier > 3
    ) {
      return fail(400, { message: 'Fare values are invalid.' });
    }
    return mutate(
      event,
      `/admin/v1/pricing/${encodeURIComponent(values.serviceType)}`,
      'PUT',
      {
        base_fare: numbers.baseFare,
        per_km_rate: numbers.perKmRate,
        per_minute_rate: numbers.perMinuteRate,
        minimum_fare: numbers.minimumFare,
        surge_multiplier: numbers.surgeMultiplier,
        is_active: values.isActive === 'true',
        reason: values.reason,
      },
      'Fare rule updated.',
    );
  },

  zoneUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'zoneId', 'isActive', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/zones/${encodeURIComponent(values.zoneId)}`,
      'PUT',
      { is_active: values.isActive === 'true', reason: values.reason },
      'Service zone updated.',
    );
  },

  createCase: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'targetType', 'targetId', 'category', 'notes', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      '/admin/v1/cases',
      'POST',
      {
        target_type: values.targetType,
        target_id: values.targetId,
        ride_id: values.targetType === 'ride' ? values.targetId : null,
        category: values.category,
        notes: values.notes,
        reason: values.reason,
      },
      'Case opened.',
    );
  },

  caseUpdate: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'caseId', 'status', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    return mutate(
      event,
      `/admin/v1/cases/${encodeURIComponent(values.caseId)}`,
      'PATCH',
      {
        status: values.status,
        resolution: values.resolution || null,
        reason: values.reason,
      },
      'Case updated.',
    );
  },

  createRestriction: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'targetType', 'targetId', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    const endsAt = values.endsAt ? isoDate(values.endsAt) : null;
    if (values.endsAt && !endsAt) {
      return fail(400, { message: 'Restriction end time is invalid.' });
    }
    return mutate(
      event,
      '/admin/v1/restrictions',
      'POST',
      {
        target_type: values.targetType,
        target_id: values.targetId,
        case_id: values.caseId || null,
        ends_at: endsAt,
        reason: values.reason,
      },
      'Account restriction recorded.',
    );
  },

  liftRestriction: async (event) => {
    const values = formValues(await event.request.formData());
    const empty = missing(values, 'targetType', 'restrictionId', 'reason');
    if (empty) {
      return fail(400, { message: `${empty} is required.` });
    }
    if (values.targetType !== 'driver' && values.targetType !== 'passenger') {
      return fail(400, { message: 'Account type must be driver or passenger.' });
    }
    return mutate(
      event,
      `/admin/v1/restrictions/${values.targetType}/${encodeURIComponent(values.restrictionId)}/lift`,
      'POST',
      { reason: values.reason },
      'Account restriction lifted.',
    );
  },
};
