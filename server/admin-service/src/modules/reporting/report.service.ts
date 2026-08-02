import { HTTPException } from 'hono/http-exception';
import {
  AUDIT_OUTCOMES,
  AuditOutcome,
  CASE_STATUSES,
  CaseStatus,
} from '../../db/schema/index.ts';
import { AuditService } from '../audit-log/audit.service.ts';
import { CaseService } from '../case-management/case.service.ts';
import { REPORT_TYPES } from './report.schema.ts';

export type ReportType = typeof REPORT_TYPES[number];

function csvCell(value: unknown): string {
  if (value == null) return '';
  const text = typeof value === 'object' ? JSON.stringify(value) : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export function rowsToCsv(rows: Array<Record<string, unknown>>): string {
  if (rows.length === 0) return '\uFEFF';
  const headers = [...new Set(rows.flatMap((row) => Object.keys(row)))];
  const records = rows.map((row) => (
    headers.map((header) => csvCell(row[header])).join(',')
  ));
  return `\uFEFF${headers.map(csvCell).join(',')}\r\n${records.join('\r\n')}\r\n`;
}

/**
 * Admin report exporter: turns the same filtered case and audit records shown in
 * the portal into spreadsheet-safe CSV without creating a second reporting data
 * store or exposing credentials.
 *
 * The requested report type first selects its typed status vocabulary, delegates
 * date filtering to the owning service, and retrieves a bounded snapshot before
 * escaping every CSV cell. Case and audit exports therefore follow the same
 * validation and UTC timestamp contracts as their list screens.
 *
 * Inputs contain `type`, optional status, and optional ISO-8601 date bounds; the
 * output is a UTF-8 CSV string with a byte-order mark for spreadsheet clients.
 * Concurrent exports are read-only and do not block Admin mutations.
 */
export class ReportService {
  constructor(
    private readonly caseService: CaseService = new CaseService(),
    private readonly auditService: AuditService = new AuditService(),
  ) {}

  async export(
    type: ReportType,
    query: { status?: string; from?: string; to?: string },
  ): Promise<string> {
    if (type === 'cases') {
      const status = query.status as CaseStatus | undefined;
      if (status && !CASE_STATUSES.includes(status)) {
        throw new HTTPException(400, { message: 'INVALID_CASE_STATUS' });
      }
      const result = await this.caseService.list(
        status,
        10_000,
        0,
        query.from,
        query.to,
      );
      return rowsToCsv(result.items as Array<Record<string, unknown>>);
    }

    const status = query.status as AuditOutcome | undefined;
    if (status && !AUDIT_OUTCOMES.includes(status)) {
      throw new HTTPException(400, { message: 'INVALID_AUDIT_OUTCOME' });
    }
    const result = await this.auditService.list(
      10_000,
      0,
      status,
      query.from,
      query.to,
    );
    return rowsToCsv(result.items as Array<Record<string, unknown>>);
  }
}
