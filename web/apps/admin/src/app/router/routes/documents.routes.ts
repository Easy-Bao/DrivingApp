import type { RouteRecordRaw } from 'vue-router'
import DocumentVerificationPage from '@/features/documents/pages/DocumentVerificationPage.vue'
import ExpiringDocumentsPage from '@/features/documents/pages/ExpiringDocumentsPage.vue'
import RejectedDocumentsPage from '@/features/documents/pages/RejectedDocumentsPage.vue'

export const documentsRoutes: RouteRecordRaw[] = [
  { path: '/documents', redirect: '/documents/verification' },
  {
    path: '/documents/verification',
    name: 'documents-verification',
    component: DocumentVerificationPage,
  },
  { path: '/documents/expiring', name: 'documents-expiring', component: ExpiringDocumentsPage },
  { path: '/documents/rejected', name: 'documents-rejected', component: RejectedDocumentsPage },
]
