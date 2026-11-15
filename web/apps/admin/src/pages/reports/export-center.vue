<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { Icon } from '@iconify/vue'
import {
  useExportCenter,
  type GeneratedExportRecord,
  type ScheduledExportFormat,
  type ScheduledReport,
} from '@/features/reports'
import {
  BaseSelect,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
} from '@/shared'

const {
  scheduledReports,
  recentExports,
  activeScheduleCount,
  toggleSchedule,
  createSchedule,
  downloadGeneratedExport,
} = useExportCenter()

const actionToast = ref<string | null>(null)
const showScheduleModal = ref(false)
const newName = ref('')
const newFrequency = ref<ScheduledReport['frequency']>('Weekly')
const newFormat = ref<ScheduledExportFormat>('CSV')
const newRecipients = ref('')
const newWindow = ref('Every Monday at 08:00 AM PHT')
const scheduleError = ref<string | null>(null)
let toastTimer: ReturnType<typeof setTimeout> | null = null

onBeforeUnmount(() => {
  if (toastTimer !== null) clearTimeout(toastTimer)
})

function showToast(msg: string) {
  actionToast.value = msg
  if (toastTimer !== null) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    actionToast.value = null
    toastTimer = null
  }, 4000)
}

function handleToggleSchedule(schedule: ScheduledReport) {
  const result = toggleSchedule(schedule.id)
  if (!result.ok) {
    showToast(result.error)
    return
  }
  showToast(`Schedule "${schedule.name}" is now ${schedule.isActive ? 'Active' : 'Paused'}.`)
}

function handleDownloadExport(record: GeneratedExportRecord) {
  downloadGeneratedExport(record)
  showToast(`Downloaded CSV export ${record.filename}.`)
}

function openCreateModal() {
  newName.value = ''
  newFrequency.value = 'Weekly'
  newFormat.value = 'CSV'
  newRecipients.value = 'ops@easyride.ph'
  newWindow.value = 'Every Monday at 08:00 AM PHT'
  scheduleError.value = null
  showScheduleModal.value = true
}

function submitSchedule() {
  const result = createSchedule({
    name: newName.value,
    frequency: newFrequency.value,
    format: newFormat.value,
    recipients: newRecipients.value,
    timeSchedule: newWindow.value,
  })
  if (!result.ok) {
    scheduleError.value = result.error
    return
  }
  showToast(`Created scheduled export: ${newName.value.trim()}.`)
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
          <StatusBadge :label="`${activeScheduleCount} Active Schedules`" tone="neutral" />
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
                  @click="handleToggleSchedule(schedule)"
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
                  icon="lucide:file-text"
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
                  @click="handleDownloadExport(exportItem)"
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
            @click="submitSchedule"
          >
            Save Schedule
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
