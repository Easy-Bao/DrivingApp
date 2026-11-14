<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { ModalDialog } from '@/shared'
import { buildDocumentPreviewSvg } from '@/features/documents'

export interface ApplicationViewerDocument {
  docId: string
  title: string
  subtitle: string
  category: 'license' | 'photo' | 'vehicle' | 'clearance'
  filename: string
  backFilename?: string
  imageUrl?: string
  meta: { label: string; value: string }[]
}

const props = defineProps<{
  document: ApplicationViewerDocument | null
  applicantName: string
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const docSide = ref<'front' | 'back'>('front')

watch(
  () => props.document,
  () => {
    docSide.value = 'front'
  },
)

const displayedFilename = computed(() => {
  if (!props.document) return ''
  if (props.document.category === 'license' && docSide.value === 'back') {
    return props.document.backFilename ?? props.document.filename
  }
  return props.document.filename
})

const previewSrc = computed(() => {
  if (!props.document) return ''
  if (props.document.imageUrl) return props.document.imageUrl
  return buildDocumentPreviewSvg({
    docId: props.document.docId,
    title: props.document.title,
    subtitle: props.document.subtitle,
    holder: props.applicantName,
    authority: 'Pagadian City Compliance File',
    plateOrRef: displayedFilename.value,
    side:
      props.document.category === 'license'
        ? docSide.value === 'front'
          ? 'Front'
          : 'Back'
        : undefined,
  })
})
</script>

<template>
  <ModalDialog
    :open="Boolean(document)"
    :title="document?.title ?? ''"
    :subtitle="document?.subtitle"
    size="lg"
    close-label="Close modal"
    @update:open="!$event && emit('close')"
  >
    <div v-if="document" class="space-y-4">
      <div
        v-if="document.category === 'license'"
        class="flex items-center justify-between gap-2 pb-1"
      >
        <div class="inline-flex border border-neutral-200 bg-neutral-100 p-0.5 text-xs">
          <button
            type="button"
            class="px-3 py-1 font-semibold transition-colors cursor-pointer"
            :class="
              docSide === 'front'
                ? 'bg-neutral-900 text-white'
                : 'text-neutral-600 hover:text-neutral-900'
            "
            @click="docSide = 'front'"
          >
            Front Side
          </button>
          <button
            type="button"
            class="px-3 py-1 font-semibold transition-colors cursor-pointer"
            :class="
              docSide === 'back'
                ? 'bg-neutral-900 text-white'
                : 'text-neutral-600 hover:text-neutral-900'
            "
            @click="docSide = 'back'"
          >
            Back Side
          </button>
        </div>
        <span class="text-[11px] font-mono text-neutral-500 truncate">{{ displayedFilename }}</span>
      </div>

      <div
        v-else
        class="flex items-center justify-between gap-2 text-xs text-neutral-600 bg-neutral-50 border border-neutral-200 px-3 py-2"
      >
        <span class="font-medium">Submitted File Reference</span>
        <span class="font-mono font-semibold text-neutral-900 truncate">{{
          displayedFilename
        }}</span>
      </div>

      <div
        class="bg-neutral-100 border border-neutral-200 p-4 flex flex-col items-center justify-center min-h-[240px]"
      >
        <img
          :src="previewSrc"
          :alt="`${document.title} preview for ${applicantName}`"
          class="max-h-72 object-contain border border-neutral-200 bg-white shadow-xs"
        />
        <div class="mt-2 inline-flex items-center gap-1.5 text-[11px] text-neutral-500 font-medium">
          <Icon icon="lucide:shield-check" class="text-emerald-700" />
          <span>Encrypted compliance scan · {{ displayedFilename }}</span>
        </div>
      </div>

      <div
        class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs bg-neutral-50 border border-neutral-200 p-4"
      >
        <div v-for="entry in document.meta" :key="entry.label">
          <div class="text-[11px] text-neutral-500 font-medium">{{ entry.label }}</div>
          <div class="font-semibold text-neutral-900 mt-0.5 break-all">{{ entry.value }}</div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end">
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="emit('close')"
        >
          Done
        </button>
      </div>
    </template>
  </ModalDialog>
</template>
