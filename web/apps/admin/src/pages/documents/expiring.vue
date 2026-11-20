<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  BaseSelect,
  EmptyTableRow,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  useDataTable,
  useToast,
  type BadgeTone,
} from '@/shared'
import { useExpiringDocuments, type ExpiryStatus } from '@/features/documents'

const { expiringDocs, sendUrgentReminder, broadcastCriticalReminders } = useExpiringDocuments()

const searchQuery = ref('')
const statusFilter = ref<'ALL' | 'CRITICAL' | ExpiryStatus>('ALL')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('info')

const filteredExpiring = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return expiringDocs.value.filter((documentRecord) => {
    if (statusFilter.value === 'CRITICAL' && documentRecord.daysLeft > 14) return false
    if (
      statusFilter.value !== 'ALL' &&
      statusFilter.value !== 'CRITICAL' &&
      documentRecord.status !== statusFilter.value
    ) {
      return false
    }
    if (!query) return true
    return (
      documentRecord.id.toLowerCase().includes(query) ||
      documentRecord.driver.toLowerCase().includes(query) ||
      documentRecord.docType.toLowerCase().includes(query) ||
      documentRecord.city.toLowerCase().includes(query)
    )
  })
})

const criticalCount = computed(
  () => expiringDocs.value.filter((documentRecord) => documentRecord.daysLeft <= 14).length,
)

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || statusFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredExpiring, {
  initialPageSize: 10,
  resetDeps: [searchQuery, statusFilter],
})

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
}

function getStatusTone(status: ExpiryStatus): BadgeTone {
  if (status === 'Action Required') return 'danger'
  if (status === 'Notice Sent') return 'warning'
  return 'info'
}

function handleSendReminder(id: string) {
  const result = sendUrgentReminder(id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message, 'info')
}

function handleBroadcastCritical() {
  const result = broadcastCriticalReminders()
  showToast(result.message, 'success')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Expiring"
      description="Monitor upcoming regulatory document expirations and send driver renewal reminders."
    >
      <template #actions>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
          @click="handleBroadcastCritical"
        >
          Notify Critical ({{ criticalCount }})
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search driver, document, area..."
              aria-label="Search expiring documents"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter expiring documents"
            :options="[
              { label: 'All Statuses', value: 'ALL' },
              { label: 'Critical (<= 14 Days)', value: 'CRITICAL' },
              { label: 'Action Required', value: 'Action Required' },
              { label: 'Notice Sent', value: 'Notice Sent' },
              { label: 'Grace Period', value: 'Grace Period' },
            ]"
          />
        </div>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Tracked: {{ filteredExpiring.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[780px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Area</th>
              <th class="py-3 px-4">Expiry Date</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="doc in paginatedItems" :key="doc.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ doc.driverPhone }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-900">{{ doc.docType }}</td>
              <td class="py-3 px-4 text-neutral-600">{{ doc.city }}</td>
              <td class="py-3 px-4 font-mono whitespace-nowrap">
                <span :class="doc.daysLeft <= 14 ? 'text-rose-700 font-bold' : 'text-neutral-800'">
                  {{ doc.expiryDate }}
                </span>
                <span class="text-[11px] text-neutral-500 ml-1">({{ doc.daysLeft }}d)</span>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="doc.status" :tone="getStatusTone(doc.status)" />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-900 text-xs font-semibold cursor-pointer"
                  @click="handleSendReminder(doc.id)"
                >
                  Send SMS
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No matching expiring documents"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredExpiring.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
