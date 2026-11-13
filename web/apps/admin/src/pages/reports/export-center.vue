<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { exportToCsv } from '@/shared/utils/format'

interface ScheduledReport {
  id: string
  name: string
  frequency: 'Daily' | 'Weekly' | 'Monthly'
  format: 'CSV' | 'PDF' | 'Excel'
  recipients: string
  timeSchedule: string
  isActive: boolean
}

const scheduledReports = ref<ScheduledReport[]>([
  {
    id: 'SCH-01',
    name: 'Weekly Pagadian Cash Commission & Settlement Summary',
    frequency: 'Weekly',
    format: 'Excel',
    recipients: 'treasury@easyride.ph, ops@easyride.ph',
    timeSchedule: 'Every Monday at 08:00 AM PHT',
    isActive: true,
  },
  {
    id: 'SCH-02',
    name: 'Daily Driver Prepaid Top-Up & QRPh Reconciliation Roster',
    frequency: 'Daily',
    format: 'CSV',
    recipients: 'accounting@easyride.ph',
    timeSchedule: 'Daily at 11:59 PM PHT',
    isActive: true,
  },
  {
    id: 'SCH-03',
    name: 'Monthly LGU & TODA Franchise Dispatch Activity Audit',
    frequency: 'Monthly',
    format: 'PDF',
    recipients: 'compliance@easyride.ph',
    timeSchedule: '1st day of month at 07:00 AM PHT',
    isActive: true,
  },
  {
    id: 'SCH-04',
    name: 'Weekly Driver Safety Report & Rating QA Summary',
    frequency: 'Weekly',
    format: 'CSV',
    recipients: 'safety@easyride.ph',
    timeSchedule: 'Every Friday at 05:00 PM PHT',
    isActive: false,
  },
])

const recentExports = ref([
  {
    id: 'EXP-401',
    filename: 'pagadian_trips_nov_week1.csv',
    reportCategory: 'Trip Reports',
    format: 'CSV',
    size: '1.4 MB',
    generatedAt: '12 minutes ago',
  },
  {
    id: 'EXP-402',
    filename: 'pagadian_commission_settlements_oct.csv',
    reportCategory: 'Revenue Reports',
    format: 'Excel',
    size: '980 KB',
    generatedAt: '2 hours ago',
  },
  {
    id: 'EXP-403',
    filename: 'toda_document_expiry_forecast.csv',
    reportCategory: 'Document Expiry Report',
    format: 'PDF',
    size: '1.1 MB',
    generatedAt: 'Yesterday',
  },
])

const actionToast = ref<string | null>(null)
const showScheduleModal = ref(false)
const newName = ref('')
const newFrequency = ref<ScheduledReport['frequency']>('Weekly')
const newFormat = ref<ScheduledReport['format']>('CSV')
const newRecipients = ref('')
const newWindow = ref('Every Monday at 08:00 AM PHT')
const scheduleError = ref<string | null>(null)

const toggleSchedule = (sch: ScheduledReport) => {
  sch.isActive = !sch.isActive
  actionToast.value = `Schedule "${sch.name}" is now ${sch.isActive ? 'Active' : 'Paused'}.`
}

const downloadFile = (filename: string, category: string) => {
  exportToCsv(
    filename.replace(/\.(xlsx|pdf)$/i, '.csv'),
    ['Filename', 'Report Category', 'Generated Region', 'Currency'],
    [[filename, category, 'Pagadian City, Zamboanga del Sur', 'PHP']],
  )
  actionToast.value = `Downloaded snapshot export for ${filename}.`
}

const openCreateModal = () => {
  newName.value = ''
  newFrequency.value = 'Weekly'
  newFormat.value = 'CSV'
  newRecipients.value = 'ops@easyride.ph'
  newWindow.value = 'Every Monday at 08:00 AM PHT'
  scheduleError.value = null
  showScheduleModal.value = true
}

const createSchedule = () => {
  if (!newName.value.trim() || !newRecipients.value.trim()) {
    scheduleError.value = 'Enter a schedule title and at least one recipient email.'
    return
  }
  scheduledReports.value.unshift({
    id: `SCH-0${scheduledReports.value.length + 1}`,
    name: newName.value.trim(),
    frequency: newFrequency.value,
    format: newFormat.value,
    recipients: newRecipients.value.trim(),
    timeSchedule: newWindow.value.trim() || 'Daily at 08:00 AM PHT',
    isActive: true,
  })
  actionToast.value = `Created scheduled export: ${newName.value.trim()}.`
  showScheduleModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="actionToast"
      :message="actionToast"
      tone="success"
      @dismiss="actionToast = null"
    />

    <PageHeader
      title="Exports"
      description="Download regional CSV reports and manage scheduled deliveries."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <h2 class="font-bold text-sm text-neutral-900">Scheduled Automated Reports</h2>
          <p class="text-xs text-neutral-400 mt-0.5">
            Dispatched automatically in Philippine Standard Time (PHT / UTC+8)
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <StatusBadge
            :label="`${scheduledReports.filter((schedule) => schedule.isActive).length} Active Schedules`"
            tone="neutral"
          />
          <button
            type="button"
            class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors cursor-pointer shrink-0"
            @click="openCreateModal"
          >
            + Schedule Report
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Report Name</th>
              <th class="py-3 px-4">Frequency</th>
              <th class="py-3 px-4">Format</th>
              <th class="py-3 px-4">Email Recipients</th>
              <th class="py-3 px-4">Execution Window</th>
              <th class="py-3 px-4 text-right">Status / Toggle</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="schedule in scheduledReports"
              :key="schedule.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ schedule.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ schedule.id }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="schedule.frequency"
                  :tone="
                    schedule.frequency === 'Daily'
                      ? 'info'
                      : schedule.frequency === 'Weekly'
                        ? 'warning'
                        : 'success'
                  "
                />
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
                >
                  .{{ schedule.format.toLowerCase() }}
                </span>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-mono text-[11px] max-w-xs truncate">
                {{ schedule.recipients }}
              </td>
              <td class="py-3 px-4 text-neutral-500 font-medium">{{ schedule.timeSchedule }}</td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-2.5 py-1 text-xs font-semibold rounded-none transition-colors cursor-pointer"
                  :class="
                    schedule.isActive
                      ? 'bg-neutral-900 hover:bg-neutral-800 text-white'
                      : 'bg-neutral-100 hover:bg-neutral-200 text-neutral-600'
                  "
                  @click="toggleSchedule(schedule)"
                >
                  {{ schedule.isActive ? 'Active (Auto-Email)' : 'Paused' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="scheduledReports.length === 0"
              :colspan="6"
              title="No automated report schedules configured"
              description="Create a schedule to dispatch automated Pagadian City operational briefings."
              :show-reset="false"
            />
          </tbody>
        </table>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100">
        <h2 class="font-bold text-sm text-neutral-900">Recent Generated Exports</h2>
        <p class="text-xs text-neutral-400 mt-0.5">
          Download recent generated regional snapshots directly as local CSV records
        </p>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[760px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Filename</th>
              <th class="py-3 px-4">Report Type</th>
              <th class="py-3 px-4">Format</th>
              <th class="py-3 px-4">Size</th>
              <th class="py-3 px-4">Generated At</th>
              <th class="py-3 px-4 text-right">Download</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="exportItem in recentExports"
              :key="exportItem.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-medium text-neutral-900 flex items-center gap-2">
                <Icon
                  :icon="
                    exportItem.format === 'CSV'
                      ? 'lucide:file-text'
                      : exportItem.format === 'PDF'
                        ? 'lucide:file-down'
                        : 'lucide:file-spreadsheet'
                  "
                  class="text-neutral-500 text-base shrink-0"
                  aria-hidden="true"
                />
                <span>{{ exportItem.filename }}</span>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-medium">
                {{ exportItem.reportCategory }}
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
                >
                  {{ exportItem.format }}
                </span>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-500">{{ exportItem.size }}</td>
              <td class="py-3 px-4 text-neutral-500">{{ exportItem.generatedAt }}</td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors cursor-pointer"
                  @click="downloadFile(exportItem.filename, exportItem.reportCategory)"
                >
                  Download
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="recentExports.length === 0"
              :colspan="6"
              title="No recent exports available"
              description="Generated snapshot downloads will appear here once processed."
              :show-reset="false"
            />
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      v-model:open="showScheduleModal"
      title="Create Scheduled Export"
      subtitle="Configure recurring automated email delivery for operations or finance teams."
      size="sm"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Schedule Title</label>
          <input
            v-model="newName"
            type="text"
            placeholder="e.g., Weekly Toda Cash Settlement Reconciliation"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Frequency</label>
            <BaseSelect
              v-model="newFrequency"
              :full-width="true"
              aria-label="Export frequency"
              :options="['Daily', 'Weekly', 'Monthly']"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Format</label>
            <BaseSelect
              v-model="newFormat"
              :full-width="true"
              aria-label="Export file format"
              :options="['CSV', 'PDF', 'Excel']"
            />
          </div>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Recipient Emails</label>
          <input
            v-model="newRecipients"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Execution Window</label>
          <input
            v-model="newWindow"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <p v-if="scheduleError" class="text-xs font-medium text-rose-700">
          {{ scheduleError }}
        </p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="showScheduleModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 cursor-pointer"
            @click="createSchedule"
          >
            Save Schedule
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
