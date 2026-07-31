import { error } from '@sveltejs/kit';
import { isReportName } from '$lib/admin';
import { AdminApiError, adminApi } from '$lib/server/admin-api';
import { parseCsv } from '$lib/server/csv';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, url, fetch, locals }) => {
  if (!isReportName(params.report)) {
    error(404, 'Report not found.');
  }

  const query = new URLSearchParams();
  for (const key of ['from', 'to', 'status']) {
    const value = url.searchParams.get(key);
    if (value) {
      query.set(key, value);
    }
  }
  try {
    const csv = await adminApi<string>(
      fetch,
      `/admin/v1/reports/${params.report}?${query}`,
      locals.adminToken,
      { headers: { accept: 'text/csv' } },
    );
    return {
      report: params.report,
      generatedAt: new Date().toISOString(),
      payload: parseCsv(csv),
    };
  } catch (caught) {
    if (caught instanceof AdminApiError) {
      error(caught.status, caught.message);
    }
    error(502, 'Printable report failed.');
  }
};
