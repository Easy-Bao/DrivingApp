<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
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
    recipients: 'treasury@pagadian-taxicle.ph, ops@pagadian-taxicle.ph',
    timeSchedule: 'Every Monday at 08:00 AM PHT',
    isActive: true,
  },
  {
    id: 'SCH-02',
    name: 'Daily Driver Prepaid Top-Up & QRPh Reconciliation Roster',
    frequency: 'Daily',
    format: 'CSV',
    recipients: 'accounting@pagadian-taxicle.ph',
    timeSchedule: 'Daily at 11:59 PM PHT',
    isActive: true,
  },
  {
    id: 'SCH-03',
    name: 'Monthly LGU & TODA Franchise Dispatch Activity Audit',
    frequency: 'Monthly',
    format: 'PDF',
    recipients: 'compliance@pagadian-taxicle.ph',
    timeSchedule: '1st day of month at 07:00 AM PHT',
    isActive: true,
  },
  {
    id: 'SCH-04',
    name: 'Weekly Driver Safety Report & Rating QA Summary',
    frequency: 'Weekly',
    format: 'CSV',
    recipients: 'safety@pagadian-taxicle.ph',
    timeSchedule: 'Every Friday at 05:00 PM PHT',
    isActive: false,
  },
])

const recentExports = ref([
  {
    id: 'EXP-401',
    filename: 'pagadian_taxicle_trips_nov_week1.csv',
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
  newRecipients.value = 'ops@pagadian-taxicle.ph'
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

    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Export &amp; Automated Delivery Center
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Download regional CSV ledgers or manage scheduled Pagadian City operational briefings.
        </p>
      </div>
      <button
        type="button"
        class="self-start sm:self-auto px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors"
        @click="openCreateModal"
      >
        + Create Scheduled Report
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div>
          <h2 class="font-bold text-sm text-neutral-900">Scheduled Automated Reports</h2>
          <p class="text-xs text-neutral-400 mt-0.5">
            Dispatched automatically in Philippine Standard Time (PHT / UTC+8)
          </p>
        </div>
        <StatusBadge
          :label="`${scheduledReports.filter((s) => s.isActive).length} Active Schedules`"
          tone="success"
        />
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
              v-for="sch in scheduledReports"
              :key="sch.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ sch.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ sch.id }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="sch.frequency"
                  :tone="
                    sch.frequency === 'Daily'
                      ? 'info'
                      : sch.frequency === 'Weekly'
                        ? 'warning'
                        : 'success'
                  "
                />
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
                >
                  .{{ sch.format.toLowerCase() }}
                </span>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-mono text-[11px] max-w-xs truncate">
                {{ sch.recipients }}
              </td>
              <td class="py-3 px-4 text-neutral-500 font-medium">{{ sch.timeSchedule }}</td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-2.5 py-1 text-xs font-semibold rounded-none transition-colors"
                  :class="
                    sch.isActive
                      ? 'bg-emerald-100 hover:bg-emerald-200 text-emerald-800'
                      : 'bg-neutral-100 hover:bg-neutral-200 text-neutral-600'
                  "
                  @click="toggleSchedule(sch)"
                >
                  {{ sch.isActive ? 'Active (Auto-Email)' : 'Paused' }}
                </button>
              </td>
            </tr>
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
              v-for="exp in recentExports"
              :key="exp.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-medium text-neutral-900 flex items-center gap-2">
                <Icon
                  :icon="
                    exp.format === 'CSV'
                      ? 'lucide:file-text'
                      : exp.format === 'PDF'
                        ? 'lucide:file-down'
                        : 'lucide:file-spreadsheet'
                  "
                  class="text-neutral-500 text-base shrink-0"
                  aria-hidden="true"
                />
                <span>{{ exp.filename }}</span>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-medium">{{ exp.reportCategory }}</td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
                >
                  {{ exp.format }}
                </span>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-500">{{ exp.size }}</td>
              <td class="py-3 px-4 text-neutral-500">{{ exp.generatedAt }}</td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors"
                  @click="downloadFile(exp.filename, exp.reportCategory)"
                >
                  Download
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="showScheduleModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="showScheduleModal = false"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-md bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">Create Scheduled Export</h3>
            <p class="text-xs text-neutral-500 mt-0.5">
              Configure recurring automated email delivery for operations or finance teams.
            </p>
          </div>

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

            <div class="grid grid-cols-2 gap-3">
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

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
              @click="showScheduleModal = false"
            >
              Cancel
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
              @click="createSchedule"
            >
              Save Schedule
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
