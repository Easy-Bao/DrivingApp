import type { RouteRecordRaw } from 'vue-router'

export const documentsRoutes: RouteRecordRaw[] = [
  { path: '/documents', redirect: '/documents/verification' },
  {
    path: '/documents/verification',
    name: 'documents-verification',
    component: () => import('@/features/documents/pages/DocumentVerificationPage.vue'),
  },
  {
    path: '/documents/expiring',
    name: 'documents-expiring',
    component: () => import('@/features/documents/pages/ExpiringDocumentsPage.vue'),
  },
  {
    path: '/documents/rejected',
    name: 'documents-rejected',
    component: () => import('@/features/documents/pages/RejectedDocumentsPage.vue'),
  },
]
