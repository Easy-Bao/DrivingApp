<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const faqArticles = ref([
  {
    id: 'FAQ-101',
    category: 'Driver Wallet & Top-Up',
    title: 'How do drivers top up their dispatch wallet via Company QR?',
    summary:
      'Drivers scan company QR or transfer to bank account, submit reference code and receipt photo in driver app. Admin verifies and credits balance.',
    views: 4820,
    updatedAt: '2 days ago',
  },
  {
    id: 'FAQ-102',
    category: 'Passenger Fares & Billing',
    title: 'How are airport tolls and surcharges calculated?',
    summary:
      'Airport gate fees and highway tolls are added to final invoice based on GPS toll gantry traversal points without extra commission.',
    views: 3190,
    updatedAt: '1 week ago',
  },
  {
    id: 'FAQ-103',
    category: 'Driver Onboarding & Regulatory',
    title: 'What documents are required to activate driver account?',
    summary:
      'Requires valid Commercial Driver License, comprehensive vehicle insurance, annual roadworthiness inspection, and clear background check.',
    views: 6240,
    updatedAt: '3 days ago',
  },
])

const actionToast = ref<string | null>(null)
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Help Center & FAQ Knowledge Base
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage public self-service help articles, in-app FAQ categories, and driver
          troubleshooting guides.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
        @click="actionToast = 'New article composer opened.'"
      >
        <Icon icon="lucide:plus" />
        <span>Create Knowledge Article</span>
      </button>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div
        v-for="faq in faqArticles"
        :key="faq.id"
        class="bg-white border border-neutral-200 rounded-xl p-5 shadow-2xs space-y-3 flex flex-col justify-between"
      >
        <div>
          <span
            class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-neutral-100 text-neutral-800"
          >
            {{ faq.category }}
          </span>
          <h3 class="font-bold text-sm text-neutral-900 mt-2.5">{{ faq.title }}</h3>
          <p class="text-xs text-neutral-500 mt-1.5 leading-relaxed">{{ faq.summary }}</p>
        </div>

        <div
          class="pt-3 border-t border-neutral-100 flex items-center justify-between text-xs text-neutral-400"
        >
          <span>{{ faq.views.toLocaleString() }} readers</span>
          <span class="font-mono text-[11px]">{{ faq.updatedAt }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
