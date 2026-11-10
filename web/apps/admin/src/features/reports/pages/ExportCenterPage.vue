<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

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
    name: 'Weekly Executive Financial & Commission Summary',
    frequency: 'Weekly',
    format: 'Excel',
    recipients: 'finance@easyride.io, executive@easyride.io',
    timeSchedule: 'Every Monday at 08:00 AM UTC',
    isActive: true,
  },
  {
    id: 'SCH-02',
    name: 'Daily Driver Payout & Top-Up Audit Roster',
    frequency: 'Daily',
    format: 'CSV',
    recipients: 'accounting@easyride.io, audit@easyride.io',
    timeSchedule: 'Daily at 00:00 Midnight UTC',
    isActive: true,
  },
  {
    id: 'SCH-03',
    name: 'Monthly Municipal Mobility Demand & Tax Filing',
    frequency: 'Monthly',
    format: 'PDF',
    recipients: 'legal@easyride.io, compliance@easyride.io',
    timeSchedule: '1st day of every month at 06:00 AM UTC',
    isActive: true,
  },
  {
    id: 'SCH-04',
    name: 'Weekly Driver Performance & Safety Compliance Log',
    frequency: 'Weekly',
    format: 'PDF',
    recipients: 'safety-ops@easyride.io',
    timeSchedule: 'Every Friday at 17:00 PM UTC',
    isActive: false,
  },
])

const recentExports = ref([
  {
    id: 'EXP-401',
    filename: 'trips_report_october_metro_central.csv',
    reportCategory: 'Trip Reports',
    format: 'CSV',
    size: '2.4 MB',
    generatedAt: '12 minutes ago',
    generatedBy: 'Admin User',
  },
  {
    id: 'EXP-402',
    filename: 'executive_revenue_summary_q3.xlsx',
    reportCategory: 'Revenue Reports',
    format: 'Excel',
    size: '1.8 MB',
    generatedAt: '2 hours ago',
    generatedBy: 'Super Admin',
  },
  {
    id: 'EXP-403',
    filename: 'driver_document_compliance_audit.pdf',
    reportCategory: 'Document Expiry Report',
    format: 'PDF',
    size: '4.1 MB',
    generatedAt: 'Yesterday',
    generatedBy: 'Compliance Lead',
  },
])

const actionToast = ref<string | null>(null)

function toggleSchedule(sch: ScheduledReport) {
  sch.isActive = !sch.isActive
  actionToast.value = `Automated report ${sch.name} is now ${sch.isActive ? 'Active (Scheduled)' : 'Paused'}.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}

function downloadFile(filename: string) {
  actionToast.value = `Downloading ${filename}... Export file ready in downloads.`
  setTimeout(() => {
    actionToast.value = null
  }, 3500)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Export & Automated Delivery Center
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Generate on-demand CSV, PDF, and Excel reports or configure recurring scheduled emails
          (Daily, Weekly, Monthly).
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
        @click="actionToast = 'Scheduled report creation wizard opened.'"
      >
        <Icon icon="lucide:plus" />
        <span>Create Scheduled Report</span>
      </button>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <!-- Section 1: Scheduled Reports (Auto-emailed) -->
    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div>
          <h2 class="font-bold text-sm text-neutral-900">
            Scheduled Automated Reports (Auto-Emailed)
          </h2>
          <p class="text-xs text-neutral-400 mt-0.5">
            Dispatched automatically via background cron engine to recipient inboxes
          </p>
        </div>
        <span
          class="px-2.5 py-1 bg-neutral-100 rounded-full text-xs font-semibold text-neutral-800"
        >
          {{ scheduledReports.filter((s) => s.isActive).length }} Active Schedules
        </span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Report Name</th>
            <th class="py-3 px-4">Frequency</th>
            <th class="py-3 px-4">Export Format</th>
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
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  sch.frequency === 'Daily'
                    ? 'bg-blue-100 text-blue-800'
                    : sch.frequency === 'Weekly'
                      ? 'bg-purple-100 text-purple-800'
                      : 'bg-emerald-100 text-emerald-800'
                "
              >
                {{ sch.frequency }}
              </span>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-md text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
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
                class="px-2.5 py-1 rounded-md text-xs font-semibold transition-colors"
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

    <!-- Section 2: Recent Export Downloads History -->
    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div>
          <h2 class="font-bold text-sm text-neutral-900">Recent Generated Exports</h2>
          <p class="text-xs text-neutral-400 mt-0.5">
            Files remain available for secure download for 14 days
          </p>
        </div>
      </div>

      <table class="w-full text-left text-xs">
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
            <td
              class="py-3 px-4 font-mono font-medium text-neutral-900 flex items-center space-x-2"
            >
              <Icon
                :icon="
                  exp.format === 'CSV'
                    ? 'lucide:file-text'
                    : exp.format === 'PDF'
                      ? 'lucide:file-down'
                      : 'lucide:file-spreadsheet'
                "
                class="text-neutral-500 text-base shrink-0"
              />
              <span>{{ exp.filename }}</span>
            </td>
            <td class="py-3 px-4 text-neutral-700 font-medium">{{ exp.reportCategory }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-md text-[10px] font-mono font-bold bg-neutral-100 text-neutral-800"
              >
                {{ exp.format }}
              </span>
            </td>
            <td class="py-3 px-4 font-mono text-neutral-500">{{ exp.size }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ exp.generatedAt }}</td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors inline-flex items-center space-x-1.5"
                @click="downloadFile(exp.filename)"
              >
                <Icon icon="lucide:download" class="text-xs" />
                <span>Download</span>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
