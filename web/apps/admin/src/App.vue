<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, RouterView } from 'vue-router'
import AdminLayout from '@/app/layouts/AdminLayout.vue'

const router = useRouter()
const transitionName = ref<'slide-left' | 'slide-right'>('slide-left')

router.beforeEach((to, from) => {
  const toDepth = to.path.split('/').filter(Boolean).length
  const fromDepth = from.path.split('/').filter(Boolean).length
  if (toDepth < fromDepth) {
    transitionName.value = 'slide-right'
  } else {
    transitionName.value = 'slide-left'
  }
})
</script>

<template>
  <AdminLayout>
    <RouterView v-slot="{ Component, route }">
      <Transition :name="transitionName" mode="out-in">
        <component :is="Component" :key="route.path" />
      </Transition>
    </RouterView>
  </AdminLayout>
</template>
