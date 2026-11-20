<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ModalDialog, SegmentedToggle } from '@/shared'
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

const DOCUMENT_SIDE_OPTIONS = [
  { label: 'Front Side', value: 'front' },
  { label: 'Back Side', value: 'back' },
] as const

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
    authority: 'Compliance Document',
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
    close-label="Close"
    @update:open="!$event && emit('close')"
  >
    <div v-if="document" class="space-y-4">
      <div
        v-if="document.category === 'license'"
        class="flex items-center justify-between gap-2 pb-1"
      >
        <SegmentedToggle
          v-model="docSide"
          aria-label="License scan side"
          :options="DOCUMENT_SIDE_OPTIONS"
        />
        <span class="text-[11px] font-mono text-neutral-500 truncate">{{ displayedFilename }}</span>
      </div>

      <div
        v-else
        class="flex items-center justify-between gap-2 text-xs text-neutral-600 bg-neutral-50 border border-neutral-200 px-3 py-2"
      >
        <span class="font-medium">File</span>
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
      <button
        type="button"
        class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
        @click="emit('close')"
      >
        Done
      </button>
    </template>
  </ModalDialog>
</template>
