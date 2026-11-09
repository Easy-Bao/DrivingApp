import { createRouter, createWebHistory } from 'vue-router'
import LandingHomePage from '@/features/marketing-home/presentation/LandingHomePage.vue'

const applicationRouter = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'landing-home',
      component: LandingHomePage,
    },
  ],
})

export default applicationRouter
