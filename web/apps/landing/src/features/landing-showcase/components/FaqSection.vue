<script setup lang="ts">
import { computed, ref } from 'vue'
import { FAQ_ITEMS } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'

type AudienceFilter = 'all' | 'passenger' | 'driver'

const activeFilter = ref<AudienceFilter>('all')
const openId = ref<string | null>(FAQ_ITEMS[0]?.id ?? null)

const filteredFaqs = computed(() => {
  if (activeFilter.value === 'all') {
    return FAQ_ITEMS
  }
  return FAQ_ITEMS.filter((item) => item.audience === activeFilter.value)
})

const toggleItem = (id: string) => {
  openId.value = openId.value === id ? null : id
}
</script>

<template>
  <section id="faq" class="border-t border-slate-200/80 bg-slate-50 py-16 sm:py-24">
    <div class="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
        <div>
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Common Questions
          </p>
          <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16]">
            Clear answers for Pagadian riders &amp; drivers
          </h2>
        </div>

        <div
          role="group"
          aria-label="Filter frequently asked questions"
          class="inline-flex rounded-full border border-slate-200 bg-white p-1 shadow-2xs"
        >
          <button
            type="button"
            class="rounded-full px-4 py-1.5 text-xs font-bold transition-colors"
            :class="
              activeFilter === 'all'
                ? 'bg-[#090d16] text-white'
                : 'text-slate-600 hover:text-[#090d16]'
            "
            @click="activeFilter = 'all'"
          >
            All
          </button>
          <button
            type="button"
            class="rounded-full px-4 py-1.5 text-xs font-bold transition-colors"
            :class="
              activeFilter === 'passenger'
                ? 'bg-emerald-700 text-white'
                : 'text-slate-600 hover:text-[#090d16]'
            "
            @click="activeFilter = 'passenger'"
          >
            Passengers
          </button>
          <button
            type="button"
            class="rounded-full px-4 py-1.5 text-xs font-bold transition-colors"
            :class="
              activeFilter === 'driver'
                ? 'bg-emerald-700 text-white'
                : 'text-slate-600 hover:text-[#090d16]'
            "
            @click="activeFilter = 'driver'"
          >
            Drivers
          </button>
        </div>
      </div>

      <div class="mt-8 space-y-3">
        <div
          v-for="item in filteredFaqs"
          :key="item.id"
          class="overflow-hidden rounded-2xl border border-slate-200 bg-white transition-colors"
          :class="openId === item.id ? 'border-emerald-300 shadow-xs' : ''"
        >
          <button
            type="button"
            class="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
            :aria-expanded="openId === item.id"
            :aria-controls="`faq-panel-${item.id}`"
            @click="toggleItem(item.id)"
          >
            <span class="flex items-center gap-3">
              <span
                class="hidden rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider sm:inline-flex"
                :class="
                  item.audience === 'passenger'
                    ? 'bg-emerald-50 text-emerald-800'
                    : 'bg-amber-50 text-amber-800'
                "
              >
                {{ item.audience }}
              </span>
              <span class="text-sm font-bold text-[#090d16] sm:text-base">{{ item.question }}</span>
            </span>

            <UiIcon
              name="chevron-down"
              size-class="h-5 w-5 text-slate-500 transition-transform duration-200"
              :class="openId === item.id ? 'rotate-180 text-emerald-700' : ''"
            />
          </button>

          <div
            v-if="openId === item.id"
            :id="`faq-panel-${item.id}`"
            class="border-t border-slate-100 px-5 py-4 text-sm leading-relaxed text-slate-600"
          >
            {{ item.answer }}
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
