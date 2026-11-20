<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { RouterView, useRoute, useRouter } from 'vue-router'
import ConsoleLayout from '@/app/layouts/ConsoleLayout.vue'

interface RouteTransitionTarget {
  meta?: Record<string, unknown>
  name?: unknown
  path?: string
  params?: Record<string, unknown>
}

const currentRoute = useRoute()
const router = useRouter()
const transitionName = ref<'slide-left' | 'slide-right' | ''>('')

function isDetailRoute(route: RouteTransitionTarget): boolean {
  return (
    route.meta?.isDetail === true ||
    String(route.name || '').endsWith('/[id]') ||
    String(route.name || '').endsWith('-details') ||
    Boolean(route.params && Object.keys(route.params).length > 0 && route.params.id)
  )
}

function normalizeRoutePath(rawPath?: string): string {
  return ((rawPath || '').split('?')[0] ?? '').replace(/\/+$/, '')
}

const unregisterTransitionGuard = router.beforeEach((to, from) => {
  const destinationIsDetail = isDetailRoute(to)
  const originIsDetail = isDetailRoute(from)
  const destinationPath = normalizeRoutePath(to.path)
  const originPath = normalizeRoutePath(from.path)

  if (destinationIsDetail && !originIsDetail) {
    transitionName.value = 'slide-left'
  } else if (!destinationIsDetail && originIsDetail && originPath.startsWith(destinationPath)) {
    transitionName.value = 'slide-right'
  } else {
    transitionName.value = ''
  }
})

onBeforeUnmount(() => {
  if (typeof unregisterTransitionGuard === 'function') {
    unregisterTransitionGuard()
  }
})
</script>

<template>
  <RouterView v-if="currentRoute.meta?.hideChrome === true" v-slot="{ Component, route }">
    <component :is="Component" :key="route.path" />
  </RouterView>
  <ConsoleLayout v-else>
    <RouterView v-slot="{ Component, route }">
      <Transition
        :name="transitionName"
        :css="Boolean(transitionName)"
        :mode="transitionName ? 'out-in' : undefined"
      >
        <component :is="Component" :key="route.path" />
      </Transition>
    </RouterView>
  </ConsoleLayout>
</template>
