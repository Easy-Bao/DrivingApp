import type { RouteRecordRaw } from 'vue-router'
import TicketsPage from '@/features/support/pages/TicketsPage.vue'
import RatingsReviewsPage from '@/features/support/pages/RatingsReviewsPage.vue'
import LostFoundPage from '@/features/support/pages/LostFoundPage.vue'
import FaqsPage from '@/features/support/pages/FaqsPage.vue'

export const supportRoutes: RouteRecordRaw[] = [
  { path: '/support', redirect: '/support/tickets' },
  { path: '/support/tickets', name: 'support-tickets', component: TicketsPage },
  {
    path: '/support/ratings-reviews',
    name: 'support-ratings-reviews',
    component: RatingsReviewsPage,
  },
  { path: '/support/lost-found', name: 'support-lost-found', component: LostFoundPage },
  { path: '/support/faqs', name: 'support-faqs', component: FaqsPage },
]
