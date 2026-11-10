<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const contentPages = ref([
  {
    slug: 'terms-of-service',
    title: 'EasyRide Rider Terms of Service',
    category: 'Legal Contract',
    version: 'v4.2',
    lastPublished: 'October 12, 2026',
    status: 'Live',
  },
  {
    slug: 'driver-partner-agreement',
    title: 'Independent Driver Partner Master Agreement',
    category: 'Legal Contract',
    version: 'v3.8',
    lastPublished: 'September 01, 2026',
    status: 'Live',
  },
  {
    slug: 'privacy-policy',
    title: 'Customer & Telemetry Privacy Policy',
    category: 'Data Protection & GDPR',
    version: 'v5.0',
    lastPublished: 'August 18, 2026',
    status: 'Live',
  },
  {
    slug: 'community-guidelines',
    title: 'EasyRide Zero Tolerance Community Guidelines',
    category: 'Trust & Safety',
    version: 'v2.4',
    lastPublished: 'November 01, 2026',
    status: 'Live',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Content Pages & Legal Terms CMS
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Publish and version Terms of Service, Privacy Policies, Driver Agreements, and community
          rules.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <Icon icon="lucide:plus" />
        <span>Create New Legal Page</span>
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Published Legal Agreements</h2>
        <span class="text-xs text-neutral-400">Requires passenger acceptance on version bump</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Document Title</th>
            <th class="py-3 px-4">URL Slug</th>
            <th class="py-3 px-4">Category</th>
            <th class="py-3 px-4">Active Version</th>
            <th class="py-3 px-4">Last Published</th>
            <th class="py-3 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="p in contentPages"
            :key="p.slug"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ p.title }}</td>
            <td class="py-3 px-4 font-mono text-neutral-500 text-[11px]">/legal/{{ p.slug }}</td>
            <td class="py-3 px-4 text-neutral-700">{{ p.category }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-md text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
              >
                {{ p.version }}
              </span>
            </td>
            <td class="py-3 px-4 text-neutral-500">{{ p.lastPublished }}</td>
            <td class="py-3 px-4 text-right">
              <button type="button" class="text-xs text-neutral-900 font-semibold hover:underline">
                Edit Markdown
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
