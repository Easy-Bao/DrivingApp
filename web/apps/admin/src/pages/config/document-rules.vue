<script setup lang="ts">
import { ref, watch } from 'vue'
import {
  DEFAULT_COMPLIANCE_POLICY,
  useComplianceRules,
  validateCompliancePolicy,
  type CompliancePolicyConfig,
  type DocumentRequirementRule,
  type DocumentScope,
} from '@/features/settings'
import {
  BaseSelect,
  ConfirmDialog,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  useToast,
} from '@/shared'

const {
  policy,
  requirements,
  commitCompliancePolicy,
  resetComplianceDefaults,
  saveDocumentRequirement,
  toggleDocumentRequirement,
} = useComplianceRules()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

// Global gate form
const draft = ref<CompliancePolicyConfig>({ ...policy.value })
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
  const error = validateCompliancePolicy(draft.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  auditReason.value = ''
  confirmOpen.value = true
}

function confirmSavePolicy() {
  const result = commitCompliancePolicy(draft.value, auditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  confirmOpen.value = false
  auditReason.value = ''
  showToast(result.message ?? 'Saved compliance policy.', 'success')
}

function handleResetDefaults() {
  resetComplianceDefaults()
  draft.value = { ...DEFAULT_COMPLIANCE_POLICY }
  showToast('Restored default document compliance rules.', 'success')
}

// Document checklist CRUD
const showDocModal = ref(false)
const editingDocId = ref<string | null>(null)
const draftDocName = ref('')
const draftDocScope = ref<DocumentScope>('Driver')
const draftDocAuthority = ref('')
const draftDocMandatory = ref(true)
const draftDocTwoSides = ref(false)
const draftDocTracksExpiry = ref(true)
const docModalError = ref<string | null>(null)

function openCreateDocModal() {
  editingDocId.value = null
  draftDocName.value = ''
  draftDocScope.value = 'Driver'
  draftDocAuthority.value = ''
  draftDocMandatory.value = true
  draftDocTwoSides.value = false
  draftDocTracksExpiry.value = true
  docModalError.value = null
  showDocModal.value = true
}

function openEditDocModal(rule: DocumentRequirementRule) {
  editingDocId.value = rule.id
  draftDocName.value = rule.name
  draftDocScope.value = rule.scope
  draftDocAuthority.value = rule.issuingAuthority
  draftDocMandatory.value = rule.mandatory
  draftDocTwoSides.value = rule.requiresTwoSides
  draftDocTracksExpiry.value = rule.tracksExpiry
  docModalError.value = null
  showDocModal.value = true
}

function saveDocChanges() {
  const result = saveDocumentRequirement(editingDocId.value, {
    name: draftDocName.value,
    scope: draftDocScope.value,
    issuingAuthority: draftDocAuthority.value,
    mandatory: draftDocMandatory.value,
    requiresTwoSides: draftDocTwoSides.value,
    tracksExpiry: draftDocTracksExpiry.value,
  })
  if (!result.ok) {
    docModalError.value = result.error
    return
  }
  showDocModal.value = false
  showToast(result.message ?? 'Saved document rule.', 'success')
}

function handleToggleDoc(rule: DocumentRequirementRule) {
  const result = toggleDocumentRequirement(rule.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated document rule status.', 'info')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Document Rules"
      description="Configure mandatory LTO, TODA/MTOP, and clearance requirements, expiry warning windows, and dispatch compliance gates."
    >
      <template #actions>
        <button
          id="reset-compliance-defaults"
          type="button"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-compliance-policy"
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="requestSavePolicy"
        >
          Save Gate Policy
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <!-- 1. Global Compliance Gate -->
    <section class="bg-white border border-neutral-200 p-5 space-y-4">
      <div class="pb-3 border-b border-neutral-100">
        <h2 class="font-bold text-sm text-neutral-900">Expiry Enforcement &amp; Dispatch Gate</h2>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 text-xs">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label for="doc-warning-days" class="block text-neutral-700 font-medium mb-1">
              Warning Lead (Days)
            </label>
            <input
              id="doc-warning-days"
              v-model.number="draft.expiryWarningLeadDays"
              type="number"
              min="7"
              max="90"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="doc-critical-days" class="block text-neutral-700 font-medium mb-1">
              Critical Alert (Days)
            </label>
            <input
              id="doc-critical-days"
              v-model.number="draft.criticalExpiryDays"
              type="number"
              min="1"
              max="30"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="doc-grace-days" class="block text-neutral-700 font-medium mb-1">
              Grace Period (Days)
            </label>
            <input
              id="doc-grace-days"
              v-model.number="draft.expiryGracePeriodDays"
              type="number"
              min="0"
              max="14"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
          </div>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between py-1.5 border-b border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Enforce LTO &amp; TODA Document Gate</div>
              <div class="text-[11px] text-neutral-500">
                Block dispatch when driver license, OR/CR, or MTOP expires
              </div>
            </div>
            <input
              v-model="draft.enforceDocumentGate"
              aria-label="Enforce LTO and TODA Document Gate"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
          <div class="flex items-center justify-between py-1.5">
            <div>
              <div class="font-medium text-neutral-900">Auto-Suspend Expired Mandatory Docs</div>
              <div class="text-[11px] text-neutral-500">
                Suspend driver dispatch status automatically after the grace period elapses
              </div>
            </div>
            <input
              v-model="draft.autoSuspendOnExpiry"
              aria-label="Auto-Suspend Expired Mandatory Docs"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
        </div>
      </div>
    </section>

    <!-- 2. Document Requirement Matrix -->
    <section class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <h2 class="font-bold text-sm text-neutral-900">
            Required Onboarding &amp; Renewal Documents
          </h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Checklist enforced during Driver Application review and ongoing compliance verification.
          </p>
        </div>
        <button
          type="button"
          class="self-start sm:self-auto px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateDocModal"
        >
          + Add Document Rule
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Rule Code</th>
              <th class="py-3 px-4">Document &amp; Authority</th>
              <th class="py-3 px-4">Scope</th>
              <th class="py-3 px-4">Enforcement</th>
              <th class="py-3 px-4">Capture Format</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr v-for="doc in requirements" :key="doc.id" class="hover:bg-neutral-50/70">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ doc.name }}</div>
                <div class="text-[11px] text-neutral-500">{{ doc.issuingAuthority }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="doc.scope" tone="info" />
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="doc.mandatory ? 'Mandatory' : 'Optional'"
                  :tone="doc.mandatory ? 'warning' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 text-neutral-700">
                {{ doc.requiresTwoSides ? 'Front + Back' : 'Single Capture' }}
                <span class="text-neutral-400">·</span>
                {{ doc.tracksExpiry ? 'Tracks Expiry' : 'No Expiry' }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="doc.isActive ? 'Active' : 'Archived'"
                  :tone="doc.isActive ? 'success' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap space-x-2">
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                  @click="openEditDocModal(doc)"
                >
                  Edit
                </button>
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
                  @click="handleToggleDoc(doc)"
                >
                  {{ doc.isActive ? 'Archive' : 'Activate' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <ModalDialog
      v-model:open="showDocModal"
      :title="editingDocId ? `Edit Document Rule · ${editingDocId}` : 'Add Document Requirement'"
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="doc-rule-name" class="block font-medium text-neutral-700 mb-1">
            Document Title
          </label>
          <input
            id="doc-rule-name"
            v-model="draftDocName"
            type="text"
            placeholder="e.g., Barangay Business Residency Certificate"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <div class="font-medium text-neutral-700 mb-1">Compliance Scope</div>
            <BaseSelect
              v-model="draftDocScope"
              :full-width="true"
              aria-label="Document compliance scope"
              :options="['Driver', 'Vehicle', 'Franchise']"
            />
          </div>
          <div>
            <label for="doc-rule-authority" class="block font-medium text-neutral-700 mb-1">
              Issuing Authority
            </label>
            <input
              id="doc-rule-authority"
              v-model="draftDocAuthority"
              type="text"
              placeholder="e.g., Pagadian LGU"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
            />
          </div>
        </div>
        <div class="space-y-2 pt-1">
          <label class="flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
            <input v-model="draftDocMandatory" type="checkbox" class="h-4 w-4 accent-neutral-900" />
            Mandatory for driver approval and active dispatch
          </label>
          <label class="flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
            <input v-model="draftDocTwoSides" type="checkbox" class="h-4 w-4 accent-neutral-900" />
            Require two-sided capture (front &amp; back scan)
          </label>
          <label class="flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
            <input
              v-model="draftDocTracksExpiry"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900"
            />
            Track expiration date for automated renewal alerts
          </label>
        </div>
        <p v-if="docModalError" role="alert" class="text-rose-700 font-medium">
          {{ docModalError }}
        </p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showDocModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="saveDocChanges"
        >
          Save Document Rule
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish Document Compliance Gate"
      description="Changes apply to live LTO/TODA document checks and expiry enforcement."
      confirm-label="Apply Gate Policy"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Adjusted renewal alert window for annual MTOP cycle..."
      @confirm="confirmSavePolicy"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
