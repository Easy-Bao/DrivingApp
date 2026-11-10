<script setup lang="ts">
import ApplicationShellLayout from '@web/ui/templates/ApplicationShellLayout.vue'
import NavigationHeader from '@web/ui/organisms/NavigationHeader.vue'
import AdminSidebar from '@/shared/components/AdminSidebar.vue'
</script>

<template>
  <ApplicationShellLayout class="min-h-screen bg-neutral-50 flex">
    <AdminSidebar />
    <div class="flex-1 flex flex-col min-w-0">
      <NavigationHeader class="border-b border-neutral-200 bg-white px-6 py-4">
        <div class="flex items-center justify-between">
          <span class="font-bold text-lg text-neutral-900">EasyRide Admin Portal</span>
          <nav class="flex items-center space-x-4 text-sm text-neutral-600">
            <span class="font-medium text-neutral-900">Operations Control</span>
          </nav>
        </div>
      </NavigationHeader>
      <main class="flex-1 overflow-y-auto">
        <slot />
      </main>
    </div>
  </ApplicationShellLayout>
</template>
