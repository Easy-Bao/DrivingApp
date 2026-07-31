export const ADMIN_SECTIONS = [
  { slug: 'overview', label: 'Overview', shortLabel: 'Home', icon: '⌂' },
  { slug: 'drivers', label: 'Drivers & documents', shortLabel: 'Drivers', icon: 'D' },
  { slug: 'dispatch', label: 'Live dispatch', shortLabel: 'Dispatch', icon: 'M' },
  { slug: 'finance', label: 'Credits & pricing', shortLabel: 'Finance', icon: '₱' },
  { slug: 'zones', label: 'Service zones', shortLabel: 'Zones', icon: 'Z' },
  { slug: 'cases', label: 'Cases & restrictions', shortLabel: 'Cases', icon: 'C' },
  { slug: 'reports', label: 'Reports & audit', shortLabel: 'Reports', icon: 'R' },
] as const;

export type AdminSection = (typeof ADMIN_SECTIONS)[number]['slug'];
export type AdminRecord = Record<string, unknown>;

export const REPORTS = [
  { slug: 'trips', label: 'Trips' },
  { slug: 'commissions', label: 'Commissions' },
  { slug: 'topups', label: 'Top-ups' },
  { slug: 'compliance', label: 'Driver compliance' },
  { slug: 'cases', label: 'Cases' },
] as const;

export type ReportName = (typeof REPORTS)[number]['slug'];

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

export function recordsFrom(value: unknown, ...keys: string[]): AdminRecord[] {
  const body = unwrapData(value);
  if (Array.isArray(body)) {
    return body.filter(isRecord);
  }

  if (!isRecord(body)) {
    return [];
  }

  for (const key of [...keys, 'items', 'records', 'results']) {
    const candidate = body[key];
    if (Array.isArray(candidate)) {
      return candidate.filter(isRecord);
    }
  }

  return [];
}

export function nestedRecord(value: unknown, key: string): AdminRecord {
  const body = unwrapData(value);
  return isRecord(body) && isRecord(body[key]) ? body[key] : {};
}

export function textFrom(record: AdminRecord, ...keys: string[]): string {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === 'string' && value.trim()) {
      return value;
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
      return String(value);
    }
  }
  return '—';
}

export function numberFrom(record: AdminRecord, ...keys: string[]): number {
  for (const key of keys) {
    const value = Number(record[key]);
    if (Number.isFinite(value)) {
      return value;
    }
  }
  return 0;
}

export function formatManila(value: unknown): string {
  if (typeof value !== 'string' && typeof value !== 'number' && !(value instanceof Date)) {
    return '—';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }

  return new Intl.DateTimeFormat('en-PH', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Manila',
  }).format(date);
}

export function formatCentavos(value: unknown): string {
  const centavos = Number(value);
  if (!Number.isFinite(centavos)) {
    return '₱0.00';
  }

  return new Intl.NumberFormat('en-PH', {
    style: 'currency',
    currency: 'PHP',
  }).format(centavos / 100);
}

export function statusClass(value: unknown): string {
  const status = String(value ?? '').toLowerCase();
  if (['approved', 'active', 'completed', 'verified', 'resolved', 'paid'].includes(status)) {
    return 'positive';
  }
  if (['rejected', 'restricted', 'suspended', 'expired', 'failed', 'cancelled'].includes(status)) {
    return 'negative';
  }
  return 'warning';
}
