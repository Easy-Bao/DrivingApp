<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  SAFETY_CATEGORY_LABELS,
  useSafetyReports,
  type ReportSeverity,
  type ReportStatus,
  type SafetyReportRecord,
} from '@/features/trips'
import {
  BaseSelect,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  exportToCsv,
  useDataTable,
} from '@/shared'

const {
  reports,
  criticalOpenCount,
  safetySeverityTone,
  safetyStatusTone,
  formatSafetyStatusLabel,
  moderateReport,
} = useSafetyReports()

const searchQuery = ref('')
const severityFilter = ref<'all' | ReportSeverity>('all')
const statusFilter = ref<'all' | ReportStatus>('all')

const inspectedReport = ref<SafetyReportRecord | null>(null)
const draftStatus = ref<ReportStatus>('under_review')
const moderationNote = ref('')
const modalError = ref<string | null>(null)
const toastMessage = ref<string | null>(null)

const filteredReports = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return reports.value.filter((item) => {
    const matchesSeverity = severityFilter.value === 'all' || item.severity === severityFilter.value
    const matchesStatus = statusFilter.value === 'all' || item.status === statusFilter.value
    const matchesSearch =
      !query ||
      item.id.toLowerCase().includes(query) ||
      item.tripId.toLowerCase().includes(query) ||
      item.reporterName.toLowerCase().includes(query) ||
      item.reportedParty.toLowerCase().includes(query) ||
      SAFETY_CATEGORY_LABELS[item.category].toLowerCase().includes(query)
    return matchesSeverity && matchesStatus && matchesSearch
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value !== '' || severityFilter.value !== 'all' || statusFilter.value !== 'all',
)

function resetFilters() {
  searchQuery.value = ''
  severityFilter.value = 'all'
  statusFilter.value = 'all'
}

const {
  currentPage,
  itemsPerPage,
  paginatedItems: paginatedReports,
} = useDataTable(filteredReports, {
  initialPageSize: 10,
  resetDeps: [searchQuery, severityFilter, statusFilter],
})

const openModerationModal = (report: SafetyReportRecord) => {
  inspectedReport.value = report
  draftStatus.value = report.status === 'submitted' ? 'under_review' : report.status
  moderationNote.value = report.moderationNote ?? ''
  modalError.value = null
}

const closeModerationModal = () => {
  inspectedReport.value = null
  modalError.value = null
}

const saveModerationDecision = () => {
  if (!inspectedReport.value) return
  const targetId = inspectedReport.value.id
  const result = moderateReport(targetId, {
    status: draftStatus.value,
    moderationNote: moderationNote.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  toastMessage.value = `${targetId} updated to ${formatSafetyStatusLabel(draftStatus.value)}.`
  closeModerationModal()
}

const exportReports = () => {
  exportToCsv(
    'pagadian-safety-reports.csv',
    [
      'Report ID',
      'Trip ID',
      'Role',
      'Reporter',
      'Reported Party',
      'Category',
      'Severity',
      'Status',
    ],
    filteredReports.value.map((report) => [
      report.id,
      report.tripId,
      report.reporterRole,
      report.reporterName,
      report.reportedParty,
      SAFETY_CATEGORY_LABELS[report.category],
      report.severity,
      report.status,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Safety Reports"
      description="Review passenger and driver safety incidents and moderation actions."
    />

    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-200 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <div class="w-full md:max-w-sm">
          <SearchField
            v-model="searchQuery"
            placeholder="Search report ID, trip ID, reporter, driver, or category..."
            aria-label="Search safety reports"
          />
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <span
            v-if="criticalOpenCount > 0"
            class="px-2.5 py-1 bg-neutral-50 border border-neutral-300 text-[11px] font-semibold text-neutral-800 tabular-nums"
          >
            Critical: {{ criticalOpenCount }}
          </span>
          <BaseSelect
            v-model="severityFilter"
            aria-label="Filter safety reports by severity"
            :options="[
              { label: 'All Severities', value: 'all' },
              { label: 'Critical', value: 'critical' },
              { label: 'High', value: 'high' },
              { label: 'Standard', value: 'standard' },
            ]"
          />
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter safety reports by status"
            :options="[
              { label: 'All Statuses', value: 'all' },
              { label: 'Submitted', value: 'submitted' },
              { label: 'Under Review', value: 'under_review' },
              { label: 'Resolved', value: 'resolved' },
              { label: 'Dismissed', value: 'dismissed' },
            ]"
          />
          <button
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="exportReports"
          >
            Export
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left border-collapse">
          <thead>
            <tr
              class="border-b border-neutral-200 bg-neutral-50/70 text-[11px] font-semibold uppercase tracking-wider text-neutral-500"
            >
              <th class="py-3 px-4">Report &amp; Trip</th>
              <th class="py-3 px-4">Reporter</th>
              <th class="py-3 px-4">Category &amp; Party</th>
              <th class="py-3 px-4">Severity</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-xs">
            <tr
              v-for="item in paginatedReports"
              :key="item.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-mono font-semibold text-neutral-900">{{ item.id }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">
                  {{ item.tripId }} · {{ item.submittedAt }}
                </div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-medium text-neutral-900">
                  {{ item.reporterName }}
                  <span class="text-[10px] uppercase font-mono text-neutral-500 ml-1">
                    ({{ item.reporterRole }})
                  </span>
                </div>
                <div class="text-[11px] text-neutral-500 font-mono">{{ item.reporterPhone }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-semibold text-neutral-900">
                  {{ SAFETY_CATEGORY_LABELS[item.category] }}
                </div>
                <div class="text-[11px] text-neutral-600">{{ item.reportedParty }}</div>
                <div class="text-[11px] text-neutral-400">{{ item.corridor }}</div>
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="item.severity.toUpperCase()"
                  :tone="safetySeverityTone(item.severity)"
                />
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="formatSafetyStatusLabel(item.status)"
                  :tone="safetyStatusTone(item.status)"
                />
              </td>
              <td class="py-3.5 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
                  @click="openModerationModal(item)"
                >
                  Review &amp; Moderate
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedReports.length === 0"
              :colspan="6"
              title="No safety reports match your selected filters"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredReports.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedReport)"
      :title="inspectedReport ? `Safety Report Moderation · ${inspectedReport.id}` : ''"
      :subtitle="
        inspectedReport
          ? `${SAFETY_CATEGORY_LABELS[inspectedReport.category]} · Trip ${inspectedReport.tripId}`
          : undefined
      "
      size="lg"
      close-label="Close modal"
      @update:open="(open) => !open && closeModerationModal()"
    >
      <template #header-meta>
        <StatusBadge
          v-if="inspectedReport"
          :label="inspectedReport.severity.toUpperCase()"
          :tone="safetySeverityTone(inspectedReport.severity)"
        />
      </template>

      <div v-if="inspectedReport" class="space-y-3 text-xs">
        <div
          class="grid grid-cols-1 sm:grid-cols-2 gap-3 bg-neutral-50 border border-neutral-200 p-3"
        >
          <div>
            <div class="text-neutral-500">Filed By ({{ inspectedReport.reporterRole }})</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ inspectedReport.reporterName }}
            </div>
            <div class="font-mono text-neutral-500">{{ inspectedReport.reporterPhone }}</div>
          </div>
          <div>
            <div class="text-neutral-500">Reported Party</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ inspectedReport.reportedParty }}
            </div>
            <div class="text-neutral-500">{{ inspectedReport.corridor }}</div>
          </div>
        </div>

        <div>
          <div class="text-neutral-500 font-medium mb-1">Incident Narrative</div>
          <div class="border border-neutral-200 bg-white p-3 text-neutral-800">
            {{ inspectedReport.narrative }}
          </div>
        </div>

        <div>
          <label class="block text-xs font-medium text-neutral-700 mb-1">
            Updated Moderation Status
          </label>
          <BaseSelect
            v-model="draftStatus"
            aria-label="Updated moderation status"
            :full-width="true"
            :options="[
              { label: 'Submitted (Unassigned)', value: 'submitted' },
              { label: 'Under Review', value: 'under_review' },
              { label: 'Resolved & Action Taken', value: 'resolved' },
              { label: 'Dismiss Report', value: 'dismissed' },
            ]"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-neutral-700 mb-1">
            Investigation &amp; Disposition Note
          </label>
          <textarea
            v-model="moderationNote"
            rows="3"
            placeholder="Record evidence review, suspension outcome, or passenger callback note..."
            class="w-full px-3 py-2 border border-neutral-300 text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>

        <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="closeModerationModal"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
            @click="saveModerationDecision"
          >
            Save Decision
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
