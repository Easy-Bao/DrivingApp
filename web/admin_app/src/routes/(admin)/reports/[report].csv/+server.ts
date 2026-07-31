import { error, type RequestHandler } from '@sveltejs/kit';
import { isReportName } from '$lib/admin';
import { AdminApiError, adminApi } from '$lib/server/admin-api';

export const GET: RequestHandler = async ({ params, url, fetch, locals }) => {
  const report = params.report;
  if (!report || !isReportName(report)) {
    error(404, 'Report not found.');
  }

  const query = new URLSearchParams();
  for (const key of ['from', 'to', 'status']) {
    const value = url.searchParams.get(key);
    if (value) {
      query.set(key, value);
    }
  }
  query.set('format', 'csv');

  try {
    const csv = await adminApi<string>(
      fetch,
      `/admin/v1/reports/${report}?${query}`,
      locals.adminToken,
      { headers: { accept: 'text/csv' } },
    );
    return new Response(csv, {
      headers: {
        'content-type': 'text/csv; charset=utf-8',
        'content-disposition': `attachment; filename="easyride-${report}.csv"`,
        'cache-control': 'private, no-store',
      },
    });
  } catch (caught) {
    if (caught instanceof AdminApiError) {
      error(caught.status, caught.message);
    }
    error(502, 'Report export failed.');
  }
};
