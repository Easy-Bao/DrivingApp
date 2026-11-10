import { createRouter, createWebHistory } from 'vue-router'
import LandingHomePage from '@/pages/LandingHomePage.vue'
import PlatformArchitecturePage from '@/pages/PlatformArchitecturePage.vue'

const applicationRouter = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'landing-home',
      component: LandingHomePage,
    },
    {
      path: '/architecture',
      name: 'platform-architecture',
      component: PlatformArchitecturePage,
    },
  ],
})

export default applicationRouter
