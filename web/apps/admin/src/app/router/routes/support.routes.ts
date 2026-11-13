import type { RouteRecordRaw } from 'vue-router'

export const supportRoutes: RouteRecordRaw[] = [
  { path: '/support', redirect: '/support/tickets' },
  {
    path: '/support/tickets',
    name: 'support-tickets',
    component: () => import('@/features/support/pages/TicketsPage.vue'),
  },
  {
    path: '/support/ratings-reviews',
    name: 'support-ratings-reviews',
    component: () => import('@/features/support/pages/RatingsReviewsPage.vue'),
  },
  {
    path: '/support/lost-found',
    name: 'support-lost-found',
    component: () => import('@/features/support/pages/LostFoundPage.vue'),
  },
  {
    path: '/support/faqs',
    name: 'support-faqs',
    component: () => import('@/features/support/pages/FaqsPage.vue'),
  },
]
