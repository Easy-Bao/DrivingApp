<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import { exportToCsv } from '@/shared/utils/format'

interface AuditLogEntry {
  id: string
  actor: string
  role: string
  action: string
  targetEntity: string
  ipAddress: string
  severity: 'Critical' | 'Warning' | 'Info'
  timestamp: string
  payloadDiff: string
}

const logs = ref<AuditLogEntry[]>([
  {
    id: 'AUD-7016-8904',
    actor: 'Maria Elena Santos',
    role: 'Operations Lead',
    action: 'WALLET_TOPUP_VERIFIED',
    targetEntity: 'TOP-8921 (Rodelio Cruz · +₱200.00)',
    ipAddress: '103.164.28.41 (Pagadian Ops)',
    severity: 'Info',
    timestamp: 'Today, 09:45 AM PHT',
    payloadDiff: '{"status": "Verified", "wallet_balance_php": 218.5, "ref": "QR-TXN-8829104"}',
  },
  {
    id: 'AUD-7016-8903',
    actor: 'Carlo Reyes',
    role: 'Safety & Compliance Officer',
    action: 'DRIVER_SUSPENDED',
    targetEntity: 'DRV-7016-501 (Lito Evangelista)',
    ipAddress: '103.164.28.44 (Pagadian Ops)',
    severity: 'Critical',
    timestamp: 'Today, 08:20 AM PHT',
    payloadDiff:
      '{"status": "Suspended", "report_id": "RPT-7016-406", "reason": "Pending safety hearing"}',
  },
  {
    id: 'AUD-7016-8902',
    actor: 'Lorna Dela Cruz',
    role: 'Finance Lead',
    action: 'SURGE_OVERRIDE_UPDATED',
    targetEntity: 'ZN-PAG-02 (Integrated Bus Terminal)',
    ipAddress: '103.164.28.50 (Pagadian Ops)',
    severity: 'Warning',
    timestamp: 'Yesterday, 06:15 PM PHT',
    payloadDiff: '{"previous_surge": "1.4x", "new_surge": "1.8x", "ceiling": "2.5x"}',
  },
  {
    id: 'AUD-7016-8901',
    actor: 'Maria Elena Santos',
    role: 'Operations Lead',
    action: 'QRPH_IMAGE_ROTATED',
    targetEntity: 'ACC-QR-GCASH (QRPH-PAG-8801)',
    ipAddress: '103.164.28.41 (Pagadian Ops)',
    severity: 'Info',
    timestamp: 'Nov 09, 2026 · 04:05 PM PHT',
    payloadDiff: '{"channel": "GCash Business (QRPh)", "merchant_code": "QRPH-PAG-8801"}',
  },
])

const searchQuery = ref('')
const severityFilter = ref<'All' | AuditLogEntry['severity']>('All')
const currentPage = ref(1)
const itemsPerPage = 10
const inspectedLog = ref<AuditLogEntry | null>(null)

const filteredLogs = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return logs.value.filter((log) => {
    const matchesSeverity = severityFilter.value === 'All' || log.severity === severityFilter.value
    const matchesSearch =
      !query ||
      log.id.toLowerCase().includes(query) ||
      log.actor.toLowerCase().includes(query) ||
      log.action.toLowerCase().includes(query) ||
      log.targetEntity.toLowerCase().includes(query)
    return matchesSeverity && matchesSearch
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || severityFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  severityFilter.value = 'All'
}

watch([searchQuery, severityFilter], () => {
  currentPage.value = 1
})

const paginatedLogs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredLogs.value.slice(start, start + itemsPerPage)
})

const exportAuditLogs = () => {
  exportToCsv(
    'pagadian-admin-audit-logs.csv',
    ['Event ID', 'Timestamp', 'Operator', 'Role', 'Action', 'Target', 'Severity', 'IP'],
    filteredLogs.value.map((log) => [
      log.id,
      log.timestamp,
      log.actor,
      log.role,
      log.action,
      log.targetEntity,
      log.severity,
      log.ipAddress,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Audit Logs"
      description="Inspect role updates, wallet adjustments, suspensions, and tariff changes."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search event ID, operator, action, or target entity..."
          aria-label="Search audit logs"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="severityFilter"
            aria-label="Filter by audit severity"
            :options="[
              { label: 'All Severities', value: 'All' },
              { label: 'Critical', value: 'Critical' },
              { label: 'Warning', value: 'Warning' },
              { label: 'Info', value: 'Info' },
            ]"
          />
          <button
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer shrink-0"
            @click="exportAuditLogs"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Event &amp; Time</th>
              <th class="py-3 px-4">Operator</th>
              <th class="py-3 px-4">Mutation Action</th>
              <th class="py-3 px-4">Target Entity</th>
              <th class="py-3 px-4">Severity</th>
              <th class="py-3 px-4 text-right">Payload</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="log in paginatedLogs"
              :key="log.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ log.id }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ log.timestamp }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ log.actor }}</div>
                <div class="text-[11px] text-neutral-500">{{ log.role }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-800">{{ log.action }}</td>
              <td class="py-3 px-4 text-neutral-700">{{ log.targetEntity }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="log.severity"
                  :tone="
                    log.severity === 'Critical'
                      ? 'danger'
                      : log.severity === 'Warning'
                        ? 'warning'
                        : 'info'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                  @click="inspectedLog = log"
                >
                  Inspect Payload
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedLogs.length === 0"
              :colspan="6"
              title="No audit log entries match your current filter"
              description="Adjust the severity filter or search query to inspect immutable admin records."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredLogs.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="inspectedLog !== null"
      :title="inspectedLog ? `Audit Payload · ${inspectedLog.id}` : ''"
      :subtitle="inspectedLog?.timestamp"
      size="md"
      @update:open="
        (open) => {
          if (!open) inspectedLog = null
        }
      "
    >
      <template v-if="inspectedLog" #header-meta>
        <StatusBadge
          :label="inspectedLog.severity"
          :tone="
            inspectedLog.severity === 'Critical'
              ? 'danger'
              : inspectedLog.severity === 'Warning'
                ? 'warning'
                : 'info'
          "
        />
      </template>

      <div v-if="inspectedLog" class="space-y-2 text-xs">
        <div>
          <span class="text-neutral-500">Operator:</span> {{ inspectedLog.actor }} ({{
            inspectedLog.role
          }})
        </div>
        <div>
          <span class="text-neutral-500">Source IP:</span>
          <span class="font-mono">{{ inspectedLog.ipAddress }}</span>
        </div>
        <div>
          <span class="text-neutral-500">Action:</span>
          <span class="font-mono font-bold">{{ inspectedLog.action }}</span>
        </div>
        <div>
          <div class="text-neutral-500 mb-1">Recorded State Diff</div>
          <pre
            class="bg-neutral-950 text-emerald-300 p-3 rounded-none font-mono text-[11px] overflow-x-auto"
            >{{ inspectedLog.payloadDiff }}</pre>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end">
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 cursor-pointer"
            @click="inspectedLog = null"
          >
            Close
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
