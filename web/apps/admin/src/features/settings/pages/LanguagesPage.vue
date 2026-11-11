<script setup lang="ts">
import { ref } from 'vue'

const supportedLanguages = ref([
  {
    code: 'en-US',
    name: 'English (United States)',
    isDefault: true,
    completion: '100%',
    activeUsers: '78%',
  },
  {
    code: 'es-ES',
    name: 'Español (Latin America & Spain)',
    isDefault: false,
    completion: '98%',
    activeUsers: '16%',
  },
  {
    code: 'zh-CN',
    name: '中文 (Simplified Chinese)',
    isDefault: false,
    completion: '94%',
    activeUsers: '4%',
  },
  {
    code: 'fr-FR',
    name: 'Français (French)',
    isDefault: false,
    completion: '92%',
    activeUsers: '2%',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Localization & Multi-Language Settings
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage translation keys, language catalogs, and passenger/driver mobile app locales.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <span>Add Locale Package</span>
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Supported App Locales</h2>
        <span class="text-xs text-neutral-400">Total string keys: 1,840</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Language Code</th>
            <th class="py-3 px-4">Display Name</th>
            <th class="py-3 px-4">Translation Coverage</th>
            <th class="py-3 px-4">Active User Base</th>
            <th class="py-3 px-4 text-right">Default System Locale</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="l in supportedLanguages"
            :key="l.code"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ l.code }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ l.name }}</td>
            <td class="py-3 px-4">
              <div class="flex items-center space-x-2">
                <div class="w-24 bg-neutral-100 h-1.5 rounded-full overflow-hidden">
                  <div
                    class="bg-emerald-500 h-full rounded-full"
                    :style="{ width: l.completion }"
                  />
                </div>
                <span class="font-mono text-neutral-600 font-medium">{{ l.completion }}</span>
              </div>
            </td>
            <td class="py-3 px-4 text-neutral-700 font-medium">{{ l.activeUsers }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  l.isDefault ? 'bg-neutral-900 text-white' : 'bg-neutral-100 text-neutral-600'
                "
              >
                {{ l.isDefault ? 'Primary Default' : 'Supported' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
