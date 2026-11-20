import { navigationGroups } from '@/app/navigation/menu'

interface BreadcrumbMeta {
  section: string
  sectionTo: string
  item: string
}

export interface BreadcrumbItem {
  label: string
  to?: string
}

const ROUTE_BREADCRUMB_LOOKUP: Record<string, BreadcrumbMeta> = {
  '/account/profile': { section: 'Account', sectionTo: '/account/profile', item: 'Profile' },
  '/unauthorized': {
    section: 'Security',
    sectionTo: '/dashboard/overview',
    item: 'Restricted Access',
  },
}

for (const group of navigationGroups) {
  const sectionTo = group.items[0]?.path ?? '/dashboard/overview'
  for (const item of group.items) {
    ROUTE_BREADCRUMB_LOOKUP[item.path] = {
      section: group.title,
      sectionTo,
      item: item.label,
    }
  }
}

export function resolveBreadcrumbs(
  path: string,
  params: Record<string, unknown> = {},
): BreadcrumbItem[] {
  const exactMatch = ROUTE_BREADCRUMB_LOOKUP[path]
  if (exactMatch) {
    if (exactMatch.item === exactMatch.section) {
      return [{ label: exactMatch.section }]
    }
    return [{ label: exactMatch.section, to: exactMatch.sectionTo }, { label: exactMatch.item }]
  }

  const segments = path.split('/').filter(Boolean)
  if (segments.length >= 3) {
    const parentPath = `/${segments[0]}/${segments[1]}`
    const parentMatch = ROUTE_BREADCRUMB_LOOKUP[parentPath]
    const paramId = 'id' in params && params.id !== undefined ? String(params.id) : ''
    const detailId = paramId || segments.slice(2).join('/')
    if (parentMatch) {
      return [
        { label: parentMatch.section, to: parentMatch.sectionTo },
        { label: parentMatch.item, to: parentPath },
        { label: `#${detailId}` },
      ]
    }
  }

  const sectionLabel = segments[0]
    ? segments[0].charAt(0).toUpperCase() + segments[0].slice(1)
    : 'Dashboard'
  const itemLabel = segments[1]
    ? segments[1].replace(/-/g, ' ').replace(/\b\w/g, (character) => character.toUpperCase())
    : 'Overview'

  if (sectionLabel === itemLabel) {
    return [{ label: sectionLabel }]
  }

  return [
    { label: sectionLabel, to: `/${segments[0] || 'dashboard/overview'}` },
    { label: itemLabel },
  ]
}
