<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

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
    triggeredBy: 'Passenger (Althea Mae Villanueva)',
    driverName: 'Rodelio Cruz',
    driverPhone: '+63 917 482 1903',
    driverPlate: 'ZDS-4821 · TODA-0412',
    riderName: 'Althea Mae Villanueva',
    riderPhone: '+63 917 842 9103',
    corridor: 'Brgy. Santiago Rotunda · Rizal Ave Extension, Pagadian City',
    coords: '7.8257° N, 123.4370° E',
    timeTriggered: '2 mins ago',
    severity: 'Critical',
    status: 'Active',
    responderNotified: false,
  },
  {
    id: 'SOS-7016-103',
    tripId: 'TRP-7016-8905',
    triggeredBy: 'Driver (Danilo Mendoza)',
    driverName: 'Danilo Mendoza',
    driverPhone: '+63 918 654 2219',
    driverPlate: 'ZDS-3019 · TODA-0194',
    riderName: 'Maricar Santos',
    riderPhone: '+63 928 519 4402',
    corridor: 'National Highway · Integrated Bus Terminal Gate, Brgy. Bulatok',
    coords: '7.8342° N, 123.4285° E',
    timeTriggered: '14 mins ago',
    severity: 'High',
    status: 'Active',
    responderNotified: true,
  },
  {
    id: 'SOS-7016-102',
    tripId: 'TRP-7016-8840',
    triggeredBy: 'Passenger (Kevin Lloyd Tan)',
    driverName: 'Reynaldo Bautista',
    driverPhone: '+63 917 773 8810',
    driverPlate: 'ZDS-1944 · TODA-0277',
    riderName: 'Kevin Lloyd Tan',
    riderPhone: '+63 927 310 6621',
    corridor: 'Dao Provincial Capitol Junction, Pagadian City',
    coords: '7.8391° N, 123.4418° E',
    timeTriggered: '4 hours ago',
    severity: 'High',
    status: 'Resolved',
    responderNotified: true,
    resolutionSummary:
      'Pagadian CDRRMO patrol checked taxicle unit at Dao Junction; minor mechanical blowout, passenger transferred safely.',
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

const filteredAlerts = computed(() => {
  if (statusFilter.value === 'all') return alerts.value
  return alerts.value.filter((alert) => alert.status === statusFilter.value)
})

const notifyResponders = (alert: SosIncident) => {
  alert.responderNotified = true
  toastMessage.value = `Escalated ${alert.id} (${alert.coords}) to PH 911 & Pagadian CDRRMO (062-925-0911).`
}

const logContactAttempt = (role: 'Driver' | 'Passenger', name: string, phone: string) => {
  toastMessage.value = `Initiating recorded dispatcher call to ${role} ${name} (${phone}).`
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
  toastMessage.value = `${resolvingAlert.value.id} closed with mandatory incident summary.`
  resolveModalOpen.value = false
  resolvingAlert.value = null
  resolutionNote.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="warning"
      @dismiss="toastMessage = null"
    />

    <div
      :class="
        activeAlertsCount > 0
          ? 'bg-rose-50/70 border border-rose-200 rounded-md p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between'
          : 'bg-emerald-50/70 border border-emerald-200 rounded-md p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between'
      "
    >
      <div class="flex items-start gap-3">
        <span
          :class="
            activeAlertsCount > 0
              ? 'inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-rose-100 text-rose-700'
              : 'inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-emerald-100 text-emerald-700'
          "
        >
          <Icon
            :icon="activeAlertsCount > 0 ? 'lucide:siren' : 'lucide:shield-check'"
            class="h-4 w-4"
          />
        </span>
        <div>
          <h2
            :class="
              activeAlertsCount > 0
                ? 'text-sm font-semibold text-rose-900'
                : 'text-sm font-semibold text-emerald-900'
            "
          >
            {{
              activeAlertsCount > 0
                ? `${activeAlertsCount} Active Emergency Alert${activeAlertsCount === 1 ? '' : 's'} — Pagadian City Operations`
                : 'All Pagadian City SOS Alerts Resolved'
            }}
          </h2>
          <p
            :class="
              activeAlertsCount > 0
                ? 'text-xs text-rose-700 mt-0.5'
                : 'text-xs text-emerald-700 mt-0.5'
            "
          >
            Direct coordination with National 911, Pagadian City CDRRMO (062-925-0911), and PNP
            Pagadian City Police Station.
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2 shrink-0">
        <button
          v-for="tab in ['all', 'Active', 'Resolved'] as const"
          :key="tab"
          type="button"
          class="px-3 py-1.5 text-xs font-medium rounded-sm border transition-colors"
          :class="
            statusFilter === tab
              ? 'bg-neutral-900 text-white border-neutral-900'
              : 'bg-white text-neutral-700 border-neutral-300 hover:bg-neutral-50'
          "
          @click="statusFilter = tab"
        >
          {{ tab === 'all' ? 'All Incidents' : tab }}
        </button>
      </div>
    </div>

    <div class="space-y-4">
      <div
        v-for="alert in filteredAlerts"
        :key="alert.id"
        :class="
          alert.status === 'Active'
            ? 'bg-white border-2 border-rose-300 rounded-md p-5'
            : 'bg-white border border-neutral-200 rounded-md p-5 opacity-90'
        "
      >
        <div
          class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-neutral-100 pb-4 mb-4"
        >
          <div class="flex flex-wrap items-center gap-2.5">
            <span class="text-sm font-bold text-neutral-900 font-mono">{{ alert.id }}</span>
            <StatusBadge
              :label="alert.severity"
              :tone="alert.severity === 'Critical' ? 'danger' : 'warning'"
            />
            <StatusBadge
              :label="alert.status"
              :tone="alert.status === 'Active' ? 'danger' : 'success'"
            />
            <StatusBadge v-if="alert.responderNotified" label="CDRRMO / 911 Notified" tone="info" />
            <span class="text-xs text-neutral-500 font-mono">
              Trip {{ alert.tripId }} · Triggered {{ alert.timeTriggered }}
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              v-if="alert.status === 'Active' && !alert.responderNotified"
              type="button"
              class="px-3 py-1.5 bg-rose-600 text-white rounded-sm text-xs font-medium hover:bg-rose-700"
              @click="notifyResponders(alert)"
            >
              Escalate to 911 / CDRRMO
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-300 text-neutral-700 rounded-sm text-xs font-medium hover:bg-neutral-50"
              @click="logContactAttempt('Driver', alert.driverName, alert.driverPhone)"
            >
              Call Driver
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-300 text-neutral-700 rounded-sm text-xs font-medium hover:bg-neutral-50"
              @click="logContactAttempt('Passenger', alert.riderName, alert.riderPhone)"
            >
              Call Passenger
            </button>
            <button
              v-if="alert.status === 'Active'"
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-sm text-xs font-medium hover:bg-neutral-800"
              @click="openResolveDialog(alert)"
            >
              Resolve Incident
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-500 uppercase tracking-wider mb-1">Triggered By</div>
            <div class="font-semibold text-neutral-900">{{ alert.triggeredBy }}</div>
            <div class="text-neutral-500 mt-0.5">
              Driver: {{ alert.driverName }} ({{ alert.driverPlate }})
            </div>
          </div>

          <div>
            <div class="text-neutral-500 uppercase tracking-wider mb-1">
              Last Known Pagadian Location
            </div>
            <div class="font-semibold text-neutral-900">{{ alert.corridor }}</div>
            <div class="font-mono text-neutral-500 mt-0.5">GPS: {{ alert.coords }}</div>
          </div>

          <div>
            <div class="text-neutral-500 uppercase tracking-wider mb-1">Direct Contacts</div>
            <div class="text-neutral-700 font-mono">Driver: {{ alert.driverPhone }}</div>
            <div class="text-neutral-700 font-mono mt-0.5">Passenger: {{ alert.riderPhone }}</div>
          </div>
        </div>

        <div
          v-if="alert.resolutionSummary"
          class="mt-4 rounded-sm bg-emerald-50 border border-emerald-200 px-3 py-2 text-xs text-emerald-900"
        >
          <span class="font-semibold">Resolution Summary:</span> {{ alert.resolutionSummary }}
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="resolveModalOpen"
      v-model:reason="resolutionNote"
      :title="`Close SOS Incident · ${resolvingAlert?.id ?? ''}`"
      description="Confirm safety of both passenger and taxicle driver before closing this active emergency record."
      confirm-label="Mark Resolved"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Incident Resolution Summary"
      reason-placeholder="Document CDRRMO/PNP response, party verification, and follow-up action..."
      @confirm="confirmResolution"
    />
  </div>
</template>
