<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import TablePagination from '@/app/components/TablePagination.vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
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
    role: 'Super Admin',
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
    role: 'Super Admin',
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
  const q = searchQuery.value.trim().toLowerCase()
  return logs.value.filter((log) => {
    const matchesSeverity = severityFilter.value === 'All' || log.severity === severityFilter.value
    const matchesSearch =
      !q ||
      log.id.toLowerCase().includes(q) ||
      log.actor.toLowerCase().includes(q) ||
      log.action.toLowerCase().includes(q) ||
      log.targetEntity.toLowerCase().includes(q)
    return matchesSeverity && matchesSearch
  })
})

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
    filteredLogs.value.map((l) => [
      l.id,
      l.timestamp,
      l.actor,
      l.role,
      l.action,
      l.targetEntity,
      l.severity,
      l.ipAddress,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div
      class="bg-white border border-neutral-200 rounded-md p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">
          Security Audit Trail &amp; Operator Mutations
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Immutable log of role updates, wallet adjustments, suspension events, and runtime tariff
          changes.
        </p>
      </div>
      <button
        type="button"
        class="self-start sm:self-auto px-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
        @click="exportAuditLogs"
      >
        Export Audit CSV
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search event ID, operator, action, or target entity..."
          class="w-full md:w-80 px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
        />

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
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                  @click="inspectedLog = log"
                >
                  Inspect Payload
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredLogs.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="inspectedLog"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="inspectedLog = null"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-lg bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3 flex items-center justify-between">
            <div>
              <h3 class="text-sm font-bold text-neutral-900">
                Audit Payload · {{ inspectedLog.id }}
              </h3>
              <p class="text-xs font-mono text-neutral-500 mt-0.5">{{ inspectedLog.timestamp }}</p>
            </div>
            <StatusBadge
              :label="inspectedLog.severity"
              :tone="inspectedLog.severity === 'Critical' ? 'danger' : 'info'"
            />
          </div>

          <div class="space-y-2 text-xs">
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

          <div class="flex justify-end border-t border-neutral-100 pt-3">
            <button
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
              @click="inspectedLog = null"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
