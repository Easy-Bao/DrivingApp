<script setup lang="ts">
import { ref } from 'vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface LegalDocument {
  id: string
  title: string
  audience: 'Passenger & Driver' | 'Driver Fleet' | 'All Platform Users'
  versionMajor: number
  versionMinor: number
  lastUpdated: string
  markdownBody: string
}

const documents = ref<LegalDocument[]>([
  {
    id: 'DOC-TOS-PH',
    title: 'Passenger Terms of Service (Pagadian City Operations)',
    audience: 'Passenger & Driver',
    versionMajor: 2,
    versionMinor: 1,
    lastUpdated: 'Nov 02, 2026',
    markdownBody:
      '# EasyRide Pagadian Terms of Service\n\nAll fares agreed during real-time taxicle bidding are payable directly in Philippine Pesos (PHP) cash upon arrival. Standard cancellation fees (PHP 15.00) apply only outside the 3-minute grace window.',
  },
  {
    id: 'DOC-TODA-CHARTER',
    title: 'Taxicle Driver Partner & TODA Franchise Agreement',
    audience: 'Driver Fleet',
    versionMajor: 1,
    versionMinor: 8,
    lastUpdated: 'Oct 28, 2026',
    markdownBody:
      '# Driver Partner Charter\n\nDrivers must maintain an active LTO Professional License, Pagadian TODA MTOP franchise permit, and at least PHP 50.00 in prepaid commission credits to receive bid requests.',
  },
  {
    id: 'DOC-DPA-10173',
    title: 'Data Privacy Act (RA 10173) Location & KYC Notice',
    audience: 'All Platform Users',
    versionMajor: 1,
    versionMinor: 4,
    lastUpdated: 'Oct 15, 2026',
    markdownBody:
      '# Philippine Data Privacy Act Compliance\n\nGPS telemetry, emergency SOS coordinates, and government license images are processed exclusively for dispatch safety, identity verification, and settlement auditing.',
  },
])

const editingDoc = ref<LegalDocument | null>(null)
const draftTitle = ref('')
const draftBody = ref('')
const bumpMinor = ref(true)
const toastMessage = ref<string | null>(null)

const openEditor = (doc: LegalDocument) => {
  editingDoc.value = doc
  draftTitle.value = doc.title
  draftBody.value = doc.markdownBody
  bumpMinor.value = true
}

const saveDocument = () => {
  if (!editingDoc.value || !draftTitle.value.trim() || !draftBody.value.trim()) return
  editingDoc.value.title = draftTitle.value.trim()
  editingDoc.value.markdownBody = draftBody.value.trim()
  if (bumpMinor.value) {
    editingDoc.value.versionMinor += 1
  }
  editingDoc.value.lastUpdated = 'Updated Just Now'
  toastMessage.value = `Published ${editingDoc.value.id} v${editingDoc.value.versionMajor}.${editingDoc.value.versionMinor}.`
  editingDoc.value = null
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

    <div class="bg-white border border-neutral-200 rounded-md p-4">
      <h2 class="text-sm font-semibold text-neutral-900">
        Platform Legal Notices &amp; Philippine Policy Texts
      </h2>
      <p class="text-xs text-neutral-500 mt-0.5">
        Maintain live policy documents displayed inside the Passenger and Driver mobile clients
        under RA 10173 and LTO guidelines.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-[760px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Document Code</th>
              <th class="py-3 px-4">Title</th>
              <th class="py-3 px-4">Scope</th>
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
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold"
                  @click="openEditor(doc)"
                >
                  Edit Policy Text
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="editingDoc"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="editingDoc = null"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-xl bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3 flex items-center justify-between">
            <div>
              <h3 class="text-sm font-bold text-neutral-900">Edit Policy · {{ editingDoc.id }}</h3>
              <p class="text-xs text-neutral-500 mt-0.5">
                Current live version: v{{ editingDoc.versionMajor }}.{{ editingDoc.versionMinor }}
              </p>
            </div>
            <StatusBadge :label="editingDoc.audience" tone="info" />
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Document Heading</label>
              <input
                v-model="draftTitle"
                type="text"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
              />
            </div>

            <div>
              <label class="block font-medium text-neutral-700 mb-1">Policy Content</label>
              <textarea
                v-model="draftBody"
                rows="7"
                class="w-full px-3 py-2 border border-neutral-300 rounded-none font-mono text-xs bg-white text-neutral-900"
              />
            </div>

            <label
              class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800"
            >
              <input
                v-model="bumpMinor"
                type="checkbox"
                class="h-4 w-4 accent-neutral-900 rounded-none"
              />
              Increment minor revision number (requires app acceptance on next launch)
            </label>
          </div>

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
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
        </div>
      </div>
    </Teleport>
  </div>
</template>
