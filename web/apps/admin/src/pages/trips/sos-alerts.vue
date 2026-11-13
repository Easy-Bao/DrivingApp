<script setup lang="ts">
import { computed, ref } from 'vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

interface SosIncident {
  id: string
  tripId: string
  triggeredBy: string
  driverName: string
  driverPhone: string
  driverPlate: string
  riderName: string
  riderPhone: string
  corridor: string
  coords: string
  timeTriggered: string
  severity: 'Critical' | 'High'
  status: 'Active' | 'Resolved'
  responderNotified: boolean
  resolutionSummary?: string
}

const alerts = ref<SosIncident[]>([
  {
    id: 'SOS-7016-104',
    tripId: 'TRP-7016-8921',
    triggeredBy: 'Passenger · Althea Mae Villanueva',
    driverName: 'Rodelio Cruz',
    driverPhone: '+63 917 482 1903',
    driverPlate: 'ZDS-4821 · TODA-0412',
    riderName: 'Althea Mae Villanueva',
    riderPhone: '+63 917 842 9103',
    corridor: 'Brgy. Santiago Rotunda, Pagadian',
    coords: '7.8257° N, 123.4370° E',
    timeTriggered: '2m ago',
    severity: 'Critical',
    status: 'Active',
    responderNotified: false,
  },
  {
    id: 'SOS-7016-103',
    tripId: 'TRP-7016-8905',
    triggeredBy: 'Driver · Danilo Mendoza',
    driverName: 'Danilo Mendoza',
    driverPhone: '+63 918 654 2219',
    driverPlate: 'ZDS-3019 · TODA-0194',
    riderName: 'Maricar Santos',
    riderPhone: '+63 928 519 4402',
    corridor: 'Bus Terminal Gate, Brgy. Bulatok',
    coords: '7.8342° N, 123.4285° E',
    timeTriggered: '14m ago',
    severity: 'High',
    status: 'Active',
    responderNotified: true,
  },
  {
    id: 'SOS-7016-102',
    tripId: 'TRP-7016-8840',
    triggeredBy: 'Passenger · Kevin Lloyd Tan',
    driverName: 'Reynaldo Bautista',
    driverPhone: '+63 917 773 8810',
    driverPlate: 'ZDS-1944 · TODA-0277',
    riderName: 'Kevin Lloyd Tan',
    riderPhone: '+63 927 310 6621',
    corridor: 'Dao Capitol Junction, Pagadian',
    coords: '7.8391° N, 123.4418° E',
    timeTriggered: '4h ago',
    severity: 'High',
    status: 'Resolved',
    responderNotified: true,
    resolutionSummary: 'CDRRMO patrol assisted unit at Dao Junction; rider transferred safely.',
  },
])

const statusFilter = ref<'all' | 'Active' | 'Resolved'>('all')
const toastMessage = ref<string | null>(null)
const resolvingAlert = ref<SosIncident | null>(null)
const resolveModalOpen = ref(false)
const resolutionNote = ref('')

const activeAlertsCount = computed(
  () => alerts.value.filter((alert) => alert.status === 'Active').length,
)

const resolvedAlertsCount = computed(
  () => alerts.value.filter((alert) => alert.status === 'Resolved').length,
)

const filterTabs = computed(() => [
  { key: 'all' as const, label: 'All', count: alerts.value.length },
  { key: 'Active' as const, label: 'Active', count: activeAlertsCount.value },
  { key: 'Resolved' as const, label: 'Resolved', count: resolvedAlertsCount.value },
])

const filteredAlerts = computed(() => {
  if (statusFilter.value === 'all') return alerts.value
  return alerts.value.filter((alert) => alert.status === statusFilter.value)
})

const notifyResponders = (alert: SosIncident) => {
  alert.responderNotified = true
  toastMessage.value = `Escalated ${alert.id} to 911.`
}

const logContactAttempt = (role: 'Driver' | 'Rider', phone: string) => {
  toastMessage.value = `Calling ${role} · ${phone}`
}

const openResolveDialog = (alert: SosIncident) => {
  resolvingAlert.value = alert
  resolutionNote.value = ''
  resolveModalOpen.value = true
}

const confirmResolution = () => {
  if (!resolvingAlert.value || !resolutionNote.value.trim()) return
  resolvingAlert.value.status = 'Resolved'
  resolvingAlert.value.resolutionSummary = resolutionNote.value.trim()
  toastMessage.value = `${resolvingAlert.value.id} resolved.`
  resolveModalOpen.value = false
  resolvingAlert.value = null
  resolutionNote.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="SOS Alerts"
      description="Monitor emergency alerts and coordinate rapid dispatch response."
    >
      <template #actions>
        <div class="flex flex-wrap items-center gap-1.5">
          <span
            class="px-2 py-1 text-xs font-mono border border-neutral-200 bg-neutral-50 text-neutral-700"
          >
            911 · CDRRMO (062-925-0911)
          </span>
          <span
            class="px-2 py-1 text-xs font-semibold tabular-nums border border-neutral-300 bg-white text-neutral-900"
          >
            {{ activeAlertsCount }} Active
          </span>
          <button
            v-for="tab in filterTabs"
            :key="tab.key"
            type="button"
            class="px-3 py-1.5 text-xs font-medium tabular-nums border transition-colors cursor-pointer"
            :class="
              statusFilter === tab.key
                ? 'bg-neutral-900 text-white border-neutral-900'
                : 'bg-white text-neutral-700 border-neutral-300 hover:bg-neutral-50'
            "
            @click="statusFilter = tab.key"
          >
            {{ tab.label }} ({{ tab.count }})
          </button>
        </div>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" tone="info" @dismiss="toastMessage = null" />

    <div class="space-y-3">
      <div
        v-if="filteredAlerts.length === 0"
        class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500"
      >
        No SOS alerts match the selected filter.
      </div>
      <div
        v-for="alert in filteredAlerts"
        :key="alert.id"
        :class="
          alert.status === 'Active'
            ? 'bg-white border border-neutral-300 border-l-2 border-l-neutral-900 p-4'
            : 'bg-white border border-neutral-200 p-4'
        "
      >
        <div
          class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-neutral-100 pb-3 mb-3"
        >
          <div class="flex flex-wrap items-center gap-2">
            <span class="text-sm font-bold text-neutral-900 font-mono">{{ alert.id }}</span>
            <StatusBadge
              :label="alert.severity"
              :tone="alert.severity === 'Critical' ? 'danger' : 'warning'"
            />
            <StatusBadge
              :label="alert.status"
              :tone="alert.status === 'Active' ? 'danger' : 'success'"
            />
            <span
              v-if="alert.responderNotified"
              class="px-2 py-0.5 text-[11px] font-medium border border-neutral-200 bg-neutral-50 text-neutral-700"
            >
              911 Notified
            </span>
            <span class="text-xs text-neutral-500 font-mono">
              {{ alert.tripId }} · {{ alert.timeTriggered }}
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              v-if="alert.status === 'Active' && !alert.responderNotified"
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-900 text-neutral-900 text-xs font-medium hover:bg-neutral-100 transition-colors cursor-pointer"
              @click="notifyResponders(alert)"
            >
              Notify 911
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-300 text-neutral-700 text-xs font-medium hover:bg-neutral-50 transition-colors cursor-pointer"
              @click="logContactAttempt('Driver', alert.driverPhone)"
            >
              Call Driver
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-300 text-neutral-700 text-xs font-medium hover:bg-neutral-50 transition-colors cursor-pointer"
              @click="logContactAttempt('Rider', alert.riderPhone)"
            >
              Call Rider
            </button>
            <button
              v-if="alert.status === 'Active'"
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 transition-colors cursor-pointer"
              @click="openResolveDialog(alert)"
            >
              Resolve
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-[11px] text-neutral-500 uppercase tracking-wider mb-1">Source</div>
            <div class="font-semibold text-neutral-900">{{ alert.triggeredBy }}</div>
            <div class="text-neutral-500 mt-0.5">
              {{ alert.driverName }} · {{ alert.driverPlate }}
            </div>
          </div>

          <div>
            <div class="text-[11px] text-neutral-500 uppercase tracking-wider mb-1">Location</div>
            <div class="font-semibold text-neutral-900">{{ alert.corridor }}</div>
            <div class="font-mono text-neutral-500 mt-0.5">{{ alert.coords }}</div>
          </div>

          <div>
            <div class="text-[11px] text-neutral-500 uppercase tracking-wider mb-1">Contacts</div>
            <div class="text-neutral-700 font-mono">Driver: {{ alert.driverPhone }}</div>
            <div class="text-neutral-700 font-mono mt-0.5">Rider: {{ alert.riderPhone }}</div>
          </div>
        </div>

        <div
          v-if="alert.resolutionSummary"
          class="mt-3 bg-neutral-50 border border-neutral-200 px-3 py-2 text-xs text-neutral-700"
        >
          <span class="font-semibold text-neutral-900">Note:</span> {{ alert.resolutionSummary }}
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="resolveModalOpen"
      v-model:reason="resolutionNote"
      :title="`Resolve ${resolvingAlert?.id ?? ''}`"
      description="Confirm party safety before closing."
      confirm-label="Resolve"
      tone="neutral"
      :require-reason="true"
      reason-label="Resolution Note"
      reason-placeholder="Brief response and handoff summary..."
      @confirm="confirmResolution"
    />
  </div>
</template>
