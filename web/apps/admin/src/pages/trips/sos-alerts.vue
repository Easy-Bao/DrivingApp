<script setup lang="ts">
import { computed, ref } from 'vue'
import { SosLocationModal, useSosAlerts, type SosIncident } from '@/features/trips'
import { useSafetyConfig } from '@/features/settings'
import {
  ConfirmDialog,
  PageHeader,
  SegmentedToggle,
  StatusBadge,
  ToastBanner,
  useToast,
} from '@/shared'

const { alerts, activeAlertsCount, resolvedAlertsCount, notifyResponders, resolveAlert } =
  useSosAlerts()
const { primaryHotlineLabel } = useSafetyConfig()

const statusFilter = ref<'all' | 'Active' | 'Resolved'>('all')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('info')
const resolvingAlert = ref<SosIncident | null>(null)
const resolveModalOpen = ref(false)
const resolutionNote = ref('')
const locationAlert = ref<SosIncident | null>(null)

const filterOptions = computed(
  () =>
    [
      { label: `All (${alerts.value.length})`, value: 'all' },
      { label: `Active (${activeAlertsCount.value})`, value: 'Active' },
      { label: `Resolved (${resolvedAlertsCount.value})`, value: 'Resolved' },
    ] as const,
)

const filteredAlerts = computed(() => {
  if (statusFilter.value === 'all') return alerts.value
  return alerts.value.filter((alert) => alert.status === statusFilter.value)
})

const handleNotifyResponders = (alert: SosIncident) => {
  const result = notifyResponders(alert.id)
  if (!result.ok) {
    showToast(result.error)
    return
  }
  showToast(`Escalated ${alert.id} to 911.`)
}

const logContactAttempt = (role: 'Driver' | 'Passenger', phone: string) => {
  showToast(`Calling ${role} · ${phone}`)
}

const openResolveDialog = (alert: SosIncident) => {
  resolvingAlert.value = alert
  resolutionNote.value = ''
  resolveModalOpen.value = true
}

const confirmResolution = () => {
  if (!resolvingAlert.value) return
  const targetId = resolvingAlert.value.id
  const result = resolveAlert(targetId, resolutionNote.value)
  if (!result.ok) {
    showToast(result.error)
    return
  }
  showToast(`${targetId} resolved.`)
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
        <span
          class="px-2 py-1 text-xs font-mono border border-neutral-200 bg-neutral-50 text-neutral-700"
        >
          {{ primaryHotlineLabel }}
        </span>
        <SegmentedToggle
          v-model="statusFilter"
          aria-label="Filter SOS alerts by status"
          :options="filterOptions"
        />
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

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
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-300 text-neutral-700 text-xs font-medium hover:bg-neutral-50 transition-colors cursor-pointer"
              @click="locationAlert = alert"
            >
              View Map
            </button>
            <button
              v-if="alert.status === 'Active' && !alert.responderNotified"
              type="button"
              class="px-3 py-1.5 bg-white border border-neutral-900 text-neutral-900 text-xs font-medium hover:bg-neutral-100 transition-colors cursor-pointer"
              @click="handleNotifyResponders(alert)"
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
              @click="logContactAttempt('Passenger', alert.riderPhone)"
            >
              Call Passenger
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
            <div class="text-neutral-700 font-mono mt-0.5">Passenger: {{ alert.riderPhone }}</div>
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

    <SosLocationModal :incident="locationAlert" @close="locationAlert = null" />
  </div>
</template>
