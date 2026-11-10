<script setup lang="ts">
import ApplicationShellLayout from '@web/ui/templates/ApplicationShellLayout.vue'
import NavigationHeader from '@web/ui/organisms/NavigationHeader.vue'
import { RouterLink } from 'vue-router'
</script>

<template>
  <ApplicationShellLayout class="min-h-screen bg-neutral-50 flex flex-col font-sans">
    <NavigationHeader class="border-b border-neutral-200 bg-white px-6 py-4">
      <div class="flex items-center justify-between max-w-6xl mx-auto w-full">
        <RouterLink to="/" class="font-bold text-lg text-neutral-900">EasyRide</RouterLink>
        <nav class="flex items-center space-x-6 text-sm">
          <RouterLink to="/" class="text-neutral-600 hover:text-neutral-900 font-medium"
            >Home</RouterLink
          >
          <RouterLink to="/architecture" class="text-neutral-600 hover:text-neutral-900 font-medium"
            >Architecture</RouterLink
          >
        </nav>
      </div>
    </NavigationHeader>
    <main class="flex-1 max-w-6xl mx-auto w-full px-6 py-8">
      <slot />
    </main>
  </ApplicationShellLayout>
</template>
