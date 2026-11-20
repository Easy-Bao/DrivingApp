<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import {
  BaseSelect,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  useDataTable,
  useToast,
} from '@/shared'
import {
  buildDocumentPreviewSvg,
  isDocumentExpired,
  useVerificationDocuments,
  type PendingDocument,
  type VerificationChecklist,
} from '@/features/documents'

const REJECTION_GROUNDS = [
  'Image blurred or unreadable official seal',
  'Name or plate mismatch against franchise',
  'Expired regulatory document',
  'Missing two-sided capture or reverse barcode',
]

const { pendingDocs, verifyDocument, rejectDocument } = useVerificationDocuments()

const searchQuery = ref('')
const docTypeFilter = ref('ALL')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const inspectingDoc = ref<PendingDocument | null>(null)
const docSide = ref<'front' | 'back'>('front')
const rejectingMode = ref(false)
const rejectionGround = ref('')
const checklist = reactive<VerificationChecklist>({
  clearScan: false,
  sealVerified: false,
  nameMatches: false,
  validExpiry: false,
})

const filteredDocs = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return pendingDocs.value.filter((documentRecord) => {
    if (docTypeFilter.value === 'EXPIRED' && !isDocumentExpired(documentRecord.expiryDate)) {
      return false
    }
    if (docTypeFilter.value === 'TWO_SIDED' && !documentRecord.hasTwoSides) return false
    if (!query) return true
    return (
      documentRecord.id.toLowerCase().includes(query) ||
      documentRecord.driver.toLowerCase().includes(query) ||
      documentRecord.docType.toLowerCase().includes(query) ||
      documentRecord.issuingAgency.toLowerCase().includes(query)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || docTypeFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredDocs, {
  initialPageSize: 10,
  resetDeps: [searchQuery, docTypeFilter],
})

const allChecked = computed(
  () =>
    checklist.clearScan && checklist.sealVerified && checklist.nameMatches && checklist.validExpiry,
)

const previewImageSrc = computed(() => {
  const doc = inspectingDoc.value
  if (!doc) return ''
  const activeFile =
    doc.hasTwoSides && docSide.value === 'back'
      ? (doc.backScanUrl ?? doc.docImageUrl)
      : (doc.frontScanUrl ?? doc.docImageUrl)
  return buildDocumentPreviewSvg({
    docId: doc.id,
    title: doc.docType,
    holder: doc.driver,
    authority: doc.issuingAgency,
    plateOrRef: activeFile,
    side: doc.hasTwoSides ? (docSide.value === 'front' ? 'Front' : 'Back') : undefined,
  })
})

function resetFilters() {
  searchQuery.value = ''
  docTypeFilter.value = 'ALL'
}

function openReview(doc: PendingDocument) {
  inspectingDoc.value = doc
  docSide.value = 'front'
  rejectingMode.value = false
  rejectionGround.value = ''
  checklist.clearScan = false
  checklist.sealVerified = false
  checklist.nameMatches = false
  checklist.validExpiry = false
}

function closeReview() {
  inspectingDoc.value = null
  rejectingMode.value = false
}

function approveCurrent() {
  if (!inspectingDoc.value) return
  const result = verifyDocument(inspectingDoc.value.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message, 'success')
  closeReview()
}

function rejectCurrent() {
  if (!inspectingDoc.value) return
  const result = rejectDocument(inspectingDoc.value.id, rejectionGround.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message, 'warning')
  closeReview()
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Verification"
      description="Review and verify submitted driver compliance documents and renewals."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search ID, driver, authority..."
              aria-label="Search verification queue"
            />
          </div>
          <BaseSelect
            v-model="docTypeFilter"
            aria-label="Filter verification documents"
            :options="[
              { label: 'All Submissions', value: 'ALL' },
              { label: 'Two-Sided Scans Only', value: 'TWO_SIDED' },
              { label: 'Expired Dates Flagged', value: 'EXPIRED' },
            ]"
          />
        </div>

        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Pending Queue: {{ filteredDocs.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[820px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Authority</th>
              <th class="py-3 px-4">Expires</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="doc in paginatedItems" :key="doc.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ doc.driverPhone }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ doc.docType }}</div>
                <span
                  v-if="doc.hasTwoSides"
                  class="inline-block mt-1 px-1.5 py-0.5 text-[10px] font-semibold bg-neutral-100 border border-neutral-200 text-neutral-700"
                >
                  2-Sided
                </span>
              </td>
              <td class="py-3 px-4 text-neutral-600">{{ doc.issuingAgency }}</td>
              <td class="py-3 px-4 font-mono whitespace-nowrap">
                <span
                  :class="
                    isDocumentExpired(doc.expiryDate)
                      ? 'text-rose-700 font-bold'
                      : 'text-neutral-700'
                  "
                >
                  {{ doc.expiryDate }}
                </span>
                <span
                  v-if="isDocumentExpired(doc.expiryDate)"
                  class="ml-1.5 px-1.5 py-0.5 text-[10px] font-semibold bg-rose-50 text-rose-700 border border-rose-200"
                >
                  Expired
                </span>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="doc.status" tone="warning" />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="openReview(doc)"
                >
                  Review Document
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No documents awaiting verification"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredDocs.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectingDoc)"
      :title="inspectingDoc ? `Compliance Review · ${inspectingDoc.id}` : ''"
      :subtitle="inspectingDoc ? `${inspectingDoc.driver} · ${inspectingDoc.docType}` : undefined"
      size="lg"
      close-label="Close"
      @update:open="!$event && closeReview()"
    >
      <div v-if="inspectingDoc" class="space-y-4 text-xs">
        <div v-if="inspectingDoc.hasTwoSides" class="flex items-center justify-between">
          <div class="inline-flex border border-neutral-200 bg-neutral-100 p-0.5">
            <button
              type="button"
              class="px-3 py-1 font-semibold cursor-pointer"
              :class="docSide === 'front' ? 'bg-neutral-900 text-white' : 'text-neutral-600'"
              @click="docSide = 'front'"
            >
              Front Side
            </button>
            <button
              type="button"
              class="px-3 py-1 font-semibold cursor-pointer"
              :class="docSide === 'back' ? 'bg-neutral-900 text-white' : 'text-neutral-600'"
              @click="docSide = 'back'"
            >
              Back Side
            </button>
          </div>
          <span class="font-mono text-[11px] text-neutral-500"
            >Submitted {{ inspectingDoc.submittedAt }}</span
          >
        </div>

        <div class="bg-neutral-100 border border-neutral-200 p-3 flex justify-center">
          <img
            :src="previewImageSrc"
            :alt="inspectingDoc.docType"
            class="max-h-60 object-contain border border-neutral-200 bg-white"
          />
        </div>

        <div
          class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 bg-neutral-50 border border-neutral-200 p-3"
        >
          <label class="flex items-center space-x-2 cursor-pointer">
            <input v-model="checklist.clearScan" type="checkbox" class="accent-neutral-900" />
            <span class="text-neutral-800">High-resolution scan without glare</span>
          </label>
          <label class="flex items-center space-x-2 cursor-pointer">
            <input v-model="checklist.sealVerified" type="checkbox" class="accent-neutral-900" />
            <span class="text-neutral-800">Official seal &amp; watermark intact</span>
          </label>
          <label class="flex items-center space-x-2 cursor-pointer">
            <input v-model="checklist.nameMatches" type="checkbox" class="accent-neutral-900" />
            <span class="text-neutral-800">Holder name matches driver profile</span>
          </label>
          <label class="flex items-center space-x-2 cursor-pointer">
            <input v-model="checklist.validExpiry" type="checkbox" class="accent-neutral-900" />
            <span class="text-neutral-800">Expiration date valid for operation</span>
          </label>
        </div>

        <div v-if="rejectingMode" class="p-3 bg-rose-50 border border-rose-200 space-y-2">
          <label class="block text-[11px] font-semibold uppercase text-rose-900">
            Regulatory Rejection Ground
          </label>
          <BaseSelect
            v-model="rejectionGround"
            aria-label="Regulatory rejection ground"
            placeholder="Select regulatory rejection ground..."
            :options="REJECTION_GROUNDS.map((reason) => ({ label: reason, value: reason }))"
          />
        </div>
      </div>

      <template #footer>
        <div class="flex flex-wrap items-center justify-between gap-2">
          <button
            v-if="!rejectingMode"
            type="button"
            class="px-3 py-2 border border-rose-300 text-rose-700 hover:bg-rose-50 text-xs font-semibold cursor-pointer"
            @click="rejectingMode = true"
          >
            Reject Document
          </button>
          <button
            v-else
            type="button"
            class="px-3 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-50 text-xs font-semibold cursor-pointer"
            @click="rejectingMode = false"
          >
            Back to Approval
          </button>

          <div class="flex items-center gap-2">
            <button
              type="button"
              class="px-3 py-2 bg-white border border-neutral-300 text-neutral-700 text-xs font-semibold cursor-pointer"
              @click="closeReview"
            >
              Cancel
            </button>
            <button
              v-if="rejectingMode"
              type="button"
              :disabled="!rejectionGround.trim()"
              class="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-40 text-white text-xs font-semibold cursor-pointer"
              @click="rejectCurrent"
            >
              Confirm Rejection
            </button>
            <button
              v-else
              type="button"
              :disabled="!allChecked"
              class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 disabled:opacity-40 text-white text-xs font-semibold cursor-pointer"
              @click="approveCurrent"
            >
              Approve &amp; Validate
            </button>
          </div>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
