<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter, RouterView } from 'vue-router'
import AdminLayout from '@/app/layouts/AdminLayout.vue'

const currentRoute = useRoute()
const router = useRouter()
const transitionName = ref<'slide-left' | 'slide-right' | ''>('')

const isDetailsRoute = (route: {
  meta?: Record<string, unknown>
  name?: unknown
  path?: string
  params?: Record<string, unknown>
}) => {
  return (
    route.meta?.isDetail === true ||
    String(route.name || '').endsWith('/[id]') ||
    String(route.name || '').endsWith('-details') ||
    Boolean(route.params && Object.keys(route.params).length > 0 && route.params.id)
  )
}

const normalizePath = (p?: string) => ((p || '').split('?')[0] ?? '').replace(/\/+$/, '')

router.beforeEach((to, from) => {
  const toIsDetail = isDetailsRoute(to)
  const fromIsDetail = isDetailsRoute(from)
  const toPath = normalizePath(to.path)
  const fromPath = normalizePath(from.path)

  if (toIsDetail && !fromIsDetail) {
    transitionName.value = 'slide-left'
  } else if (!toIsDetail && fromIsDetail && fromPath.startsWith(toPath)) {
    transitionName.value = 'slide-right'
  } else {
    transitionName.value = ''
  }
})
</script>

<template>
  <RouterView v-if="currentRoute.meta?.hideChrome === true" v-slot="{ Component, route }">
    <component :is="Component" :key="route.path" />
  </RouterView>
  <AdminLayout v-else>
    <RouterView v-slot="{ Component, route }">
      <Transition
        :name="transitionName"
        :css="Boolean(transitionName)"
        :mode="transitionName ? 'out-in' : undefined"
      >
        <component :is="Component" :key="route.path" />
      </Transition>
    </RouterView>
  </AdminLayout>
</template>
