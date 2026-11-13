<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { exportToCsv } from '@/shared/utils/format'

type ReporterRole = 'passenger' | 'driver'
type ReportCategory =
  | 'unsafe_driving'
  | 'fare_dispute'
  | 'driver_identity_mismatch'
  | 'vehicle_mismatch'
  | 'harassment'
  | 'threat_or_violence'
  | 'route_issue'
  | 'fraud'
  | 'accident'
  | 'other'
type ReportSeverity = 'standard' | 'high' | 'critical'
type ReportStatus = 'submitted' | 'under_review' | 'resolved' | 'dismissed'

interface SafetyReportRecord {
  id: string
  tripId: string
  reporterRole: ReporterRole
  reporterName: string
  reporterPhone: string
  reportedParty: string
  corridor: string
  category: ReportCategory
  severity: ReportSeverity
  status: ReportStatus
  narrative: string
  moderationNote?: string
  submittedAt: string
}

const categoryLabels: Record<ReportCategory, string> = {
  unsafe_driving: 'Unsafe Driving',
  fare_dispute: 'Fare Dispute',
  driver_identity_mismatch: 'Driver Identity Mismatch',
  vehicle_mismatch: 'Vehicle / Plate Mismatch',
  harassment: 'Harassment',
  threat_or_violence: 'Threat or Violence',
  route_issue: 'Route Deviation',
  fraud: 'Suspected Fraud',
  accident: 'Traffic Accident',
  other: 'Other Safety Concern',
}

const reports = ref<SafetyReportRecord[]>([
  {
    id: 'RPT-7016-409',
    tripId: 'TRP-7016-8918',
    reporterRole: 'passenger',
    reporterName: 'Clarisse Joy Tagupa',
    reporterPhone: '+63 917 611 4320',
    reportedParty: 'Ernesto Villafuerte (ZDS-6120 · TODA-0318)',
    corridor: 'Pagadian Public Market (Agora) -> Brgy. San Pedro',
    category: 'driver_identity_mismatch',
    severity: 'critical',
    status: 'submitted',
    narrative:
      'Passenger reported the driver operating the unit did not match the verified profile photo attached to TODA-0318.',
    submittedAt: '18 mins ago',
  },
  {
    id: 'RPT-7016-408',
    tripId: 'TRP-7016-8914',
    reporterRole: 'passenger',
    reporterName: 'Jayson Lim',
    reporterPhone: '+63 928 409 1185',
    reportedParty: 'Arnel Cabug (ZDS-4402 · TODA-0122)',
    corridor: 'Gaisano Capital Pagadian -> Brgy. Tuburan',
    category: 'unsafe_driving',
    severity: 'high',
    status: 'under_review',
    narrative: 'Overtook along the downhill Rizal Ave bend while speeding in wet road conditions.',
    moderationNote: 'Requested telemetry speed log from trip session.',
    submittedAt: '1 hour ago',
  },
  {
    id: 'RPT-7016-407',
    tripId: 'TRP-7016-8899',
    reporterRole: 'driver',
    reporterName: 'Danilo Mendoza',
    reporterPhone: '+63 918 654 2219',
    reportedParty: 'Passenger (Rafael Dominguiano)',
    corridor: 'Integrated Bus Terminal -> Brgy. Tiguma',
    category: 'fare_dispute',
    severity: 'standard',
    status: 'submitted',
    narrative:
      'Passenger contested agreed ₱115.00 winning bid fare upon drop-off and attempted to pay ₱80.00 only.',
    submittedAt: '3 hours ago',
  },
  {
    id: 'RPT-7016-406',
    tripId: 'TRP-7016-8872',
    reporterRole: 'passenger',
    reporterName: 'Mae Ann Sabellano',
    reporterPhone: '+63 917 905 2241',
    reportedParty: 'Lito Evangelista (ZDS-1988 · TODA-0501)',
    corridor: 'Dao Medical Center -> Brgy. Buenavista',
    category: 'harassment',
    severity: 'critical',
    status: 'resolved',
    narrative: 'Inappropriate verbal remarks during evening trip along provincial road.',
    moderationNote: 'Driver account suspended pending mandatory safety hearing.',
    submittedAt: 'Yesterday, 07:45 PM',
  },
])

const searchQuery = ref('')
const severityFilter = ref<'all' | ReportSeverity>('all')
const statusFilter = ref<'all' | ReportStatus>('all')
const currentPage = ref(1)
const itemsPerPage = 10

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
      categoryLabels[item.category].toLowerCase().includes(query)
    return matchesSeverity && matchesStatus && matchesSearch
  })
})

watch([searchQuery, severityFilter, statusFilter], () => {
  currentPage.value = 1
})

const hasActiveFilters = computed(
  () => searchQuery.value !== '' || severityFilter.value !== 'all' || statusFilter.value !== 'all',
)

function resetFilters() {
  searchQuery.value = ''
  severityFilter.value = 'all'
  statusFilter.value = 'all'
  currentPage.value = 1
}

const paginatedReports = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredReports.value.slice(start, start + itemsPerPage)
})

const criticalOpenCount = computed(
  () =>
    reports.value.filter(
      (item) =>
        item.severity === 'critical' &&
        (item.status === 'submitted' || item.status === 'under_review'),
    ).length,
)

const severityTone = (severity: ReportSeverity) => {
  if (severity === 'critical') return 'danger'
  if (severity === 'high') return 'warning'
  return 'neutral'
}

const statusTone = (status: ReportStatus) => {
  if (status === 'resolved') return 'success'
  if (status === 'under_review') return 'warning'
  if (status === 'submitted') return 'danger'
  return 'neutral'
}

const formatStatusLabel = (status: ReportStatus) => {
  switch (status) {
    case 'submitted':
      return 'Submitted'
    case 'under_review':
      return 'Under Review'
    case 'resolved':
      return 'Resolved'
    case 'dismissed':
      return 'Dismissed'
  }
}

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
  if (!moderationNote.value.trim()) {
    modalError.value = 'Enter an internal safety investigation note before saving.'
    return
  }
  inspectedReport.value.status = draftStatus.value
  inspectedReport.value.moderationNote = moderationNote.value.trim()
  toastMessage.value = `${inspectedReport.value.id} updated to ${formatStatusLabel(draftStatus.value)}.`
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
      categoryLabels[report.category],
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
                  {{ categoryLabels[item.category] }}
                </div>
                <div class="text-[11px] text-neutral-600">{{ item.reportedParty }}</div>
                <div class="text-[11px] text-neutral-400">{{ item.corridor }}</div>
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="item.severity.toUpperCase()"
                  :tone="severityTone(item.severity)"
                />
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="formatStatusLabel(item.status)"
                  :tone="statusTone(item.status)"
                />
              </td>
              <td class="py-3.5 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800"
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
          ? `${categoryLabels[inspectedReport.category]} · Trip ${inspectedReport.tripId}`
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
          :tone="severityTone(inspectedReport.severity)"
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
