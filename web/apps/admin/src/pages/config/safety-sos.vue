<script setup lang="ts">
import { ref, watch } from 'vue'
import {
  DEFAULT_SAFETY_POLICY,
  useSafetyConfig,
  validateSafetyPolicy,
  type EmergencyHotline,
  type SafetyPolicyConfig,
} from '@/features/settings'
import {
  ConfirmDialog,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  useToast,
} from '@/shared'

const {
  policy,
  hotlines,
  primaryHotlineLabel,
  commitSafetyPolicy,
  resetSafetyDefaults,
  saveHotline,
  toggleHotline,
} = useSafetyConfig()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

// Section 1: Escalation Rules
const draft = ref<SafetyPolicyConfig>({ ...policy.value })
watch(
  policy,
  (next) => {
    draft.value = { ...next }
  },
  { deep: true },
)

const confirmOpen = ref(false)
const auditReason = ref('')

function requestSavePolicy() {
  const error = validateSafetyPolicy(draft.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  auditReason.value = ''
  confirmOpen.value = true
}

function confirmSavePolicy() {
  const result = commitSafetyPolicy(draft.value, auditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  confirmOpen.value = false
  auditReason.value = ''
  showToast(result.message ?? 'Saved safety policy.', 'success')
}

function handleResetDefaults() {
  resetSafetyDefaults()
  draft.value = { ...DEFAULT_SAFETY_POLICY }
  showToast('Restored default emergency SOS & safety rules.', 'success')
}

// Section 2: Emergency Hotlines
const showHotlineModal = ref(false)
const editingHotlineId = ref<string | null>(null)
const draftLabel = ref('')
const draftAgency = ref('')
const draftPhone = ref('')
const draftCoverage = ref('')
const draftIsPrimary = ref(false)
const hotlineError = ref<string | null>(null)

function openCreateHotline() {
  editingHotlineId.value = null
  draftLabel.value = ''
  draftAgency.value = ''
  draftPhone.value = ''
  draftCoverage.value = 'Pagadian City (7016)'
  draftIsPrimary.value = false
  hotlineError.value = null
  showHotlineModal.value = true
}

function openEditHotline(hotline: EmergencyHotline) {
  editingHotlineId.value = hotline.id
  draftLabel.value = hotline.label
  draftAgency.value = hotline.agency
  draftPhone.value = hotline.phone
  draftCoverage.value = hotline.coverageArea
  draftIsPrimary.value = hotline.isPrimary
  hotlineError.value = null
  showHotlineModal.value = true
}

function submitHotline() {
  const result = saveHotline(editingHotlineId.value, {
    label: draftLabel.value,
    agency: draftAgency.value,
    phone: draftPhone.value,
    coverageArea: draftCoverage.value,
    isPrimary: draftIsPrimary.value,
  })
  if (!result.ok) {
    hotlineError.value = result.error
    return
  }
  showHotlineModal.value = false
  showToast(result.message ?? 'Saved emergency hotline.', 'success')
}

function handleToggleHotline(hotline: EmergencyHotline) {
  const result = toggleHotline(hotline.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated emergency hotline status.', 'info')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Safety & SOS Config"
      description="Configure emergency responder hotlines, SOS auto-escalation timers, and critical incident moderation defaults."
    >
      <template #actions>
        <span
          class="px-2.5 py-1.5 text-xs font-mono border border-neutral-200 bg-white text-neutral-700"
        >
          Primary: {{ primaryHotlineLabel }}
        </span>
        <button
          id="reset-safety-defaults"
          type="button"
          class="px-3 py-1.5 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-safety-policy"
          type="button"
          class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="requestSavePolicy"
        >
          Save Safety Policy
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <!-- 1. SOS Escalation Rules -->
    <section class="bg-white border border-neutral-200 p-5 space-y-4">
      <div class="pb-3 border-b border-neutral-100">
        <h2 class="font-bold text-sm text-neutral-900">SOS Response &amp; Moderation Escalation</h2>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 text-xs">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="sos-auto-escalate" class="block text-neutral-700 font-medium mb-1">
              Auto-Escalate Timer (Seconds)
            </label>
            <input
              id="sos-auto-escalate"
              v-model.number="draft.sosAutoEscalateSeconds"
              type="number"
              min="15"
              max="300"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Escalates unacknowledged SOS alerts to senior dispatch supervisors
            </p>
          </div>
          <div>
            <label for="sos-ping-interval" class="block text-neutral-700 font-medium mb-1">
              SOS GPS Beacon Interval (Seconds)
            </label>
            <input
              id="sos-ping-interval"
              v-model.number="draft.sosLocationPingSeconds"
              type="number"
              min="2"
              max="30"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              High-frequency GPS location capture rate during active SOS incidents
            </p>
          </div>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between py-1.5 border-b border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Auto-Notify Responders on Critical SOS</div>
              <div class="text-[11px] text-neutral-500">
                Alert primary CDRRMO/PNP dispatch desk immediately for Critical alerts
              </div>
            </div>
            <input
              v-model="draft.autoNotifyRespondersOnCritical"
              aria-label="Auto-Notify Responders on Critical SOS"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
          <div class="flex items-center justify-between py-1.5 border-b border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Require Mandatory Resolution Note</div>
              <div class="text-[11px] text-neutral-500">
                Operators must document party safety verification before closing an alert
              </div>
            </div>
            <input
              v-model="draft.requireResolutionNote"
              aria-label="Require Mandatory Resolution Note"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
          <div class="flex items-center justify-between py-1.5">
            <div>
              <div class="font-medium text-neutral-900">Auto-Suspend on Critical Safety Report</div>
              <div class="text-[11px] text-neutral-500">
                Temporarily lock driver dispatch pending safety investigation hearing
              </div>
            </div>
            <input
              v-model="draft.autoSuspendOnCriticalReport"
              aria-label="Auto-Suspend on Critical Safety Report"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
        </div>
      </div>
    </section>

    <!-- 2. Emergency Hotlines Directory -->
    <section class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <h2 class="font-bold text-sm text-neutral-900">Regional Emergency Hotlines</h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Primary hotline is displayed directly on the live SOS Alerts operations desk.
          </p>
        </div>
        <button
          type="button"
          class="self-start sm:self-auto px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateHotline"
        >
          + Add Hotline
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[800px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Code</th>
              <th class="py-3 px-4">Responder &amp; Agency</th>
              <th class="py-3 px-4">Hotline Number</th>
              <th class="py-3 px-4">Coverage Area</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr v-for="hotline in hotlines" :key="hotline.id" class="hover:bg-neutral-50/70">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ hotline.id }}</td>
              <td class="py-3 px-4">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-semibold text-neutral-900">{{ hotline.label }}</span>
                  <StatusBadge v-if="hotline.isPrimary" label="Primary" tone="info" />
                </div>
                <div class="text-[11px] text-neutral-500">{{ hotline.agency }}</div>
              </td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900">
                {{ hotline.phone }}
              </td>
              <td class="py-3 px-4 text-neutral-700">{{ hotline.coverageArea }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="hotline.isActive ? 'Active' : 'Paused'"
                  :tone="hotline.isActive ? 'success' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap space-x-2">
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                  @click="openEditHotline(hotline)"
                >
                  Edit
                </button>
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
                  @click="handleToggleHotline(hotline)"
                >
                  {{ hotline.isActive ? 'Pause' : 'Activate' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <ModalDialog
      v-model:open="showHotlineModal"
      :title="editingHotlineId ? `Edit Hotline · ${editingHotlineId}` : 'Add Emergency Hotline'"
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="hotline-label" class="block font-medium text-neutral-700 mb-1">
            Short Display Label
          </label>
          <input
            id="hotline-label"
            v-model="draftLabel"
            type="text"
            placeholder="e.g., ZDS Provincial Rescue"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div>
          <label for="hotline-agency" class="block font-medium text-neutral-700 mb-1">
            Responding Agency
          </label>
          <input
            id="hotline-agency"
            v-model="draftAgency"
            type="text"
            placeholder="e.g., Zamboanga del Sur PDRRMO"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="hotline-phone" class="block font-medium text-neutral-700 mb-1">
              Hotline Phone
            </label>
            <input
              id="hotline-phone"
              v-model="draftPhone"
              type="text"
              placeholder="062-925-0911"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="hotline-coverage" class="block font-medium text-neutral-700 mb-1">
              Coverage Area
            </label>
            <input
              id="hotline-coverage"
              v-model="draftCoverage"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
            />
          </div>
        </div>
        <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
          <input v-model="draftIsPrimary" type="checkbox" class="h-4 w-4 accent-neutral-900" />
          Set as primary responder displayed on the SOS Alerts desk
        </label>
        <p v-if="hotlineError" role="alert" class="text-rose-700 font-medium">
          {{ hotlineError }}
        </p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showHotlineModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="submitHotline"
        >
          Save Hotline
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish Safety & SOS Policy"
      description="Changes apply to live emergency alert escalation timers and critical safety moderation rules."
      confirm-label="Apply Safety Policy"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Tightened SOS auto-escalation SLA for night dispatch shift..."
      @confirm="confirmSavePolicy"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
