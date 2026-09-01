export const ADMIN_SECTIONS = [
  { slug: 'overview', label: 'Overview', shortLabel: 'Home', icon: 'O' },
  { slug: 'cases', label: 'Complaint cases', shortLabel: 'Cases', icon: 'C' },
  { slug: 'reports', label: 'Reports', shortLabel: 'Reports', icon: 'R' },
  { slug: 'audit', label: 'Audit log', shortLabel: 'Audit', icon: 'A' },
] as const;

export const REPORTS = [
  { slug: 'cases', label: 'Complaint cases' },
  { slug: 'audits', label: 'Audit events' },
] as const;

export type AdminSection = (typeof ADMIN_SECTIONS)[number]['slug'];
export type ReportName = (typeof REPORTS)[number]['slug'];
export type AdminRecord = Record<string, unknown>;

export function isAdminSection(value: string): value is AdminSection {
  return ADMIN_SECTIONS.some((section) => section.slug === value);
}

export function isReportName(value: string): value is ReportName {
  return REPORTS.some((report) => report.slug === value);
}

export function isRecord(value: unknown): value is AdminRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function unwrapData(value: unknown): unknown {
  return isRecord(value) && 'data' in value ? value.data : value;
}

export function recordsFrom(value: unknown): AdminRecord[] {
  const body = unwrapData(value);
  if (Array.isArray(body)) return body.filter(isRecord);
  if (!isRecord(body)) return [];
  const items = body.items;
  return Array.isArray(items) ? items.filter(isRecord) : [];
}

export function nestedRecord(value: unknown, key: string): AdminRecord {
  const body = unwrapData(value);
  return isRecord(body) && isRecord(body[key]) ? body[key] : {};
}

export function textFrom(record: AdminRecord, ...keys: string[]): string {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === 'string' && value.trim()) return value;
    if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  }
  return '—';
}

export function numberFrom(record: AdminRecord, ...keys: string[]): number {
  for (const key of keys) {
    const value = Number(record[key]);
    if (Number.isFinite(value)) return value;
  }
  return 0;
}

export function formatManila(value: unknown): string {
  if (typeof value !== 'string' && typeof value !== 'number' && !(value instanceof Date)) {
    return '—';
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return new Intl.DateTimeFormat('en-PH', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Manila',
  }).format(date);
}

export function statusClass(value: unknown): string {
  const status = String(value ?? '').toLowerCase();
  if (['resolved', 'succeeded'].includes(status)) return 'positive';
  if (['dismissed', 'failed'].includes(status)) return 'negative';
  return 'warning';
}
