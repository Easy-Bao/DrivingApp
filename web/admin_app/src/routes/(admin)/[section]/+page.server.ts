import { error, fail } from '@sveltejs/kit';
import { isAdminSection } from '$lib/admin';
import { AdminApiError, adminApi, adminMutation } from '$lib/server/admin-api';
import type { Actions, PageServerLoad } from './$types';

function queryPath(base: string, url: URL): string {
  const query = new URLSearchParams();
  for (const name of ['page', 'limit', 'status', 'from', 'to']) {
    const value = url.searchParams.get(name);
    if (value) query.set(name, value);
  }
  const suffix = query.toString();
  return suffix ? `${base}?${suffix}` : base;
}

function value(form: FormData, name: string): string {
  return String(form.get(name) ?? '').trim();
}

function actionFailure(caught: unknown) {
  if (caught instanceof AdminApiError) {
    return fail(caught.status, { message: caught.message });
  }
  return fail(500, { message: 'The Admin request could not be completed.' });
}

export const load: PageServerLoad = async ({ params, url, fetch, locals }) => {
  if (!isAdminSection(params.section)) error(404, 'Admin section not found.');

  const paths = {
    overview: '/admin/v1/overview',
    cases: queryPath('/admin/v1/cases', url),
    audit: queryPath('/admin/v1/audits', url),
    reports: null,
  } as const;
  const path = paths[params.section];

  try {
    return {
      section: params.section,
      payload: path
        ? await adminApi<unknown>(fetch, path, locals.adminToken)
        : null,
      unavailable: false,
    };
  } catch (caught) {
    return {
      section: params.section,
      payload: null,
      unavailable: true,
      message: caught instanceof AdminApiError
        ? caught.message
        : 'The Admin service is unavailable.',
    };
  }
};

export const actions: Actions = {
  createCase: async ({ request, fetch, locals }) => {
    const form = await request.formData();
    const payload = {
      target_type: value(form, 'targetType'),
      target_id: value(form, 'targetId'),
      ride_id: value(form, 'rideId') || null,
      category: value(form, 'category'),
      notes: value(form, 'notes'),
      reason: value(form, 'reason'),
    };
    if (!payload.target_type || !payload.target_id || !payload.category
      || !payload.notes || !payload.reason) {
      return fail(400, { message: 'Complete every required case field.' });
    }

    try {
      await adminMutation(
        fetch,
        '/admin/v1/cases',
        locals.adminToken,
        'POST',
        payload,
      );
      return { success: true, message: 'Complaint case recorded.' };
    } catch (caught) {
      return actionFailure(caught);
    }
  },

  updateCase: async ({ request, fetch, locals }) => {
    const form = await request.formData();
    const caseId = value(form, 'caseId');
    const payload = {
      status: value(form, 'status'),
      resolution: value(form, 'resolution') || null,
      reason: value(form, 'reason'),
    };
    if (!caseId || !payload.status || !payload.reason) {
      return fail(400, { message: 'Case, status, and reason are required.' });
    }

    try {
      await adminMutation(
        fetch,
        `/admin/v1/cases/${encodeURIComponent(caseId)}`,
        locals.adminToken,
        'PATCH',
        payload,
      );
      return { success: true, message: 'Complaint case updated.' };
    } catch (caught) {
      return actionFailure(caught);
    }
  },
};
