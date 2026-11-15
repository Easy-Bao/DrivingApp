<script setup lang="ts">
import { ref } from 'vue'
import { useLegalPolicies, type LegalDocument } from '@/features/settings'
import { ModalDialog, PageHeader, StatusBadge, ToastBanner } from '@/shared'

const { documents, publishDocument } = useLegalPolicies()

const editingDoc = ref<LegalDocument | null>(null)
const draftTitle = ref('')
const draftBody = ref('')
const bumpMinor = ref(true)
const modalError = ref<string | null>(null)
const toastMessage = ref<string | null>(null)

const openEditor = (doc: LegalDocument) => {
  editingDoc.value = doc
  draftTitle.value = doc.title
  draftBody.value = doc.markdownBody
  bumpMinor.value = true
  modalError.value = null
}

const saveDocument = () => {
  if (!editingDoc.value) return
  const result = publishDocument(editingDoc.value.id, {
    title: draftTitle.value,
    markdownBody: draftBody.value,
    bumpMinor: bumpMinor.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  toastMessage.value = result.message ?? 'Published policy revision.'
  editingDoc.value = null
  modalError.value = null
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <PageHeader
      title="Policies"
      description="Maintain policy documents displayed in the passenger and driver apps."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-[760px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Document Code</th>
              <th class="py-3 px-4">Title</th>
              <th class="py-3 px-4">Audience</th>
              <th class="py-3 px-4">Version</th>
              <th class="py-3 px-4">Last Revised</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="doc in documents"
              :key="doc.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3.5 px-4 font-semibold text-neutral-900">{{ doc.title }}</td>
              <td class="py-3.5 px-4">
                <StatusBadge :label="doc.audience" tone="info" />
              </td>
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-800">
                v{{ doc.versionMajor }}.{{ doc.versionMinor }}
              </td>
              <td class="py-3.5 px-4 text-neutral-500">{{ doc.lastUpdated }}</td>
              <td class="py-3.5 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer"
                  @click="openEditor(doc)"
                >
                  Edit Policy
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      :open="Boolean(editingDoc)"
      :title="editingDoc ? `Edit Policy · ${editingDoc.id}` : ''"
      :subtitle="
        editingDoc
          ? `Current live version: v${editingDoc.versionMajor}.${editingDoc.versionMinor}`
          : ''
      "
      size="lg"
      @update:open="(open) => !open && (editingDoc = null)"
    >
      <template #header-meta>
        <StatusBadge v-if="editingDoc" :label="editingDoc.audience" tone="info" />
      </template>

      <div class="space-y-3 text-xs">
        <div>
          <label for="policy-title" class="block font-medium text-neutral-700 mb-1"> Title </label>
          <input
            id="policy-title"
            v-model="draftTitle"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div>
          <label for="policy-body" class="block font-medium text-neutral-700 mb-1">
            Policy Content
          </label>
          <textarea
            id="policy-body"
            v-model="draftBody"
            rows="7"
            class="w-full px-3 py-2 border border-neutral-300 rounded-none font-mono text-xs bg-white text-neutral-900"
          />
        </div>

        <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
          <input
            v-model="bumpMinor"
            type="checkbox"
            class="h-4 w-4 accent-neutral-900 rounded-none"
          />
          Increment minor revision number (requires app acceptance on next launch)
        </label>

        <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="editingDoc = null"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="saveDocument"
          >
            Publish Revision
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
