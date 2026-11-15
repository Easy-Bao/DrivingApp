<script setup lang="ts">
import { computed, ref } from 'vue'
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
  type ToastTone,
} from '@/shared'
import { useRejectedDocuments, type RejectedDocument } from '@/features/documents'

const { rejectedDocs, queueForReReview } = useRejectedDocuments()

const searchQuery = ref('')
const resubmissionFilter = ref<'ALL' | 'RESUBMITTED' | 'AWAITING'>('ALL')
const inspectingDoc = ref<RejectedDocument | null>(null)
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')

const filteredRejected = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return rejectedDocs.value.filter((doc) => {
    if (resubmissionFilter.value === 'RESUBMITTED' && !doc.resubmitted) return false
    if (resubmissionFilter.value === 'AWAITING' && doc.resubmitted) return false
    if (!q) return true
    return (
      doc.id.toLowerCase().includes(q) ||
      doc.driver.toLowerCase().includes(q) ||
      doc.docType.toLowerCase().includes(q) ||
      doc.rejectionReason.toLowerCase().includes(q)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || resubmissionFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredRejected, {
  initialPageSize: 10,
  resetDeps: [searchQuery, resubmissionFilter],
})

function resetFilters() {
  searchQuery.value = ''
  resubmissionFilter.value = 'ALL'
}

function handleReopen(id: string) {
  const result = queueForReReview(id)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = result.message
  inspectingDoc.value = null
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Rejected"
      description="Inspect declined compliance files and re-open resubmitted scans for verification."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search ID, driver, reason..."
              aria-label="Search rejected documents"
            />
          </div>
          <BaseSelect
            v-model="resubmissionFilter"
            aria-label="Filter rejected documents"
            :options="[
              { label: 'All Rejections', value: 'ALL' },
              { label: 'Resubmitted Only', value: 'RESUBMITTED' },
              { label: 'Awaiting Driver Re-upload', value: 'AWAITING' },
            ]"
          />
        </div>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Rejected: {{ filteredRejected.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[820px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Rejection Reason</th>
              <th class="py-3 px-4">Rejected By</th>
              <th class="py-3 px-4">Resubmitted</th>
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
              <td class="py-3 px-4 font-medium text-neutral-900">{{ doc.docType }}</td>
              <td class="py-3 px-4 max-w-xs truncate text-neutral-600">
                {{ doc.rejectionReason }}
              </td>
              <td class="py-3 px-4">
                <div>{{ doc.rejectedBy }}</div>
                <div class="text-[11px] text-neutral-400">{{ doc.rejectedAt }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="doc.resubmitted ? 'Resubmitted' : 'Awaiting Upload'"
                  :tone="doc.resubmitted ? 'info' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-900 text-xs font-semibold cursor-pointer"
                  @click="inspectingDoc = doc"
                >
                  Inspect
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No matching rejected documents"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredRejected.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectingDoc)"
      :title="inspectingDoc ? `Rejection Details · ${inspectingDoc.id}` : ''"
      :subtitle="inspectingDoc ? `${inspectingDoc.driver} · ${inspectingDoc.docType}` : undefined"
      size="md"
      close-label="Close"
      @update:open="!$event && (inspectingDoc = null)"
    >
      <div v-if="inspectingDoc" class="space-y-3 text-xs">
        <div class="p-3 bg-neutral-50 border border-neutral-200 space-y-1">
          <div class="text-[11px] font-semibold uppercase text-neutral-500">Rejection Reason</div>
          <p class="text-neutral-900 font-medium">{{ inspectingDoc.rejectionReason }}</p>
        </div>
        <div class="grid grid-cols-2 gap-3 bg-neutral-50 border border-neutral-200 p-3">
          <div>
            <div class="text-[11px] text-neutral-500">Reviewed By</div>
            <div class="font-semibold text-neutral-900">{{ inspectingDoc.rejectedBy }}</div>
          </div>
          <div>
            <div class="text-[11px] text-neutral-500">Timestamp</div>
            <div class="font-semibold text-neutral-900">{{ inspectingDoc.rejectedAt }}</div>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-2 border border-neutral-300 text-neutral-700 text-xs font-semibold cursor-pointer"
            @click="inspectingDoc = null"
          >
            Close
          </button>
          <button
            v-if="inspectingDoc"
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
            @click="handleReopen(inspectingDoc.id)"
          >
            Re-Open for Verification
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
