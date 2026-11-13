import { createRouter, createWebHistory } from 'vue-router'
import { handleHotUpdate, routes } from 'vue-router/auto-routes'

const DEFAULT_TITLE = 'EasyRide — Transparent Taxicle & TukTuk Rides in Pagadian City'

const ROUTE_TITLES: Record<string, string> = {
  '/': 'EasyRide — Pagadian Taxicle & TukTuk Rides with Upfront Fares',
  '/drive': 'Drive & Earn with EasyRide — Pagadian Driver Wallet & Tiers',
  '/safety': 'Safety & Verification — EasyRide Pagadian Dispatch',
  '/download': 'Download EasyRide Apps — Passenger & Driver Builds',
  '/architecture': 'Platform Architecture — EasyRide Dispatch & Realtime Stack',
}

const applicationRouter = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, _from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }
    if (to.hash) {
      return {
        el: to.hash,
        top: 84,
        behavior: 'smooth',
      }
    }
    return { top: 0 }
  },
})

if (import.meta.hot?.data) {
  handleHotUpdate(applicationRouter)
}

applicationRouter.afterEach((to) => {
  if (typeof document === 'undefined') {
    return
  }
  const mappedTitle = ROUTE_TITLES[to.path]
  const routeTitle = to.meta?.title
  document.title =
    mappedTitle ??
    (typeof routeTitle === 'string' && routeTitle.length > 0 ? routeTitle : DEFAULT_TITLE)
})

export default applicationRouter
