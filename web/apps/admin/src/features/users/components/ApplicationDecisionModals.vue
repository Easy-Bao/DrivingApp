<script setup lang="ts">
import { ref, watch } from 'vue'
import { BaseSelect, ModalDialog } from '@/shared'
import type { DriverApplication } from '@/features/users/types'

const REJECTION_REASON_OPTIONS = [
  'Blurred or unreadable LTO license scan',
  'Expired LTO Official Receipt or MTOP permit',
  'Mismatch between applicant identity and clearance record',
  'Incomplete two-sided submission',
  'Other compliance deficiency',
]

const props = defineProps<{
  application: DriverApplication | null
  showApprove: boolean
  showReject: boolean
}>()

const emit = defineEmits<{
  (e: 'update:showApprove', value: boolean): void
  (e: 'update:showReject', value: boolean): void
  (e: 'confirmApprove'): void
  (e: 'confirmReject', reason: string): void
}>()

const selectedReason = ref(REJECTION_REASON_OPTIONS[0]!)
const notes = ref('')

watch(
  () => props.showReject,
  (open) => {
    if (open) {
      selectedReason.value = REJECTION_REASON_OPTIONS[0]!
      notes.value = ''
    }
  },
)

function submitReject() {
  const combined = notes.value.trim()
    ? `${selectedReason.value}: ${notes.value.trim()}`
    : selectedReason.value
  emit('confirmReject', combined)
}
</script>

<template>
  <ModalDialog
    :open="showApprove && Boolean(application)"
    title="Approve Driver Application"
    :subtitle="application ? `Application ${application.id} · ${application.applicant}` : undefined"
    size="md"
    close-label="Close"
    @update:open="emit('update:showApprove', $event)"
  >
    <div v-if="application" class="space-y-4 text-xs">
      <p class="text-neutral-700 leading-relaxed">
        Approve this application to activate the driver account, grant dispatch access, and send SMS
        confirmation to
        <span class="font-mono font-bold text-neutral-900">{{ application.phone }}</span
        >.
      </p>

      <div class="p-3 bg-neutral-50 border border-neutral-200 text-xs space-y-1">
        <div class="font-semibold text-neutral-900">Summary</div>
        <ul class="text-neutral-700 space-y-0.5 text-[11px] list-disc list-inside">
          <li>
            LTO License: {{ application.licenseNumber }} (Code {{ application.licenseCodes }})
          </li>
          <li>
            Vehicle: {{ application.vehicle.year }} {{ application.vehicle.make }}
            {{ application.vehicle.model }} ({{ application.vehicle.plate }})
          </li>
          <li>TODA &amp; MTOP: {{ application.vehicle.todaFranchise }}</li>
          <li>
            Address: {{ application.barangay }}, {{ application.city }},
            {{ application.province }}
          </li>
          <li>Clearance: {{ application.clearanceType }} ({{ application.backgroundStatus }})</li>
        </ul>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-end space-x-2">
        <button
          type="button"
          class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
          @click="emit('update:showApprove', false)"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
          @click="emit('confirmApprove')"
        >
          Confirm &amp; Activate Driver
        </button>
      </div>
    </template>
  </ModalDialog>

  <ModalDialog
    :open="showReject && Boolean(application)"
    title="Reject Driver Application"
    :subtitle="application ? `Application ${application.id} · ${application.applicant}` : undefined"
    size="md"
    close-label="Close"
    @update:open="emit('update:showReject', $event)"
  >
    <div v-if="application" class="space-y-4 text-xs">
      <p class="text-neutral-600 leading-relaxed">
        Select the regulatory or verification reason for declining this application. The applicant
        will be notified via SMS with corrective instructions.
      </p>

      <div>
        <label class="block text-[11px] font-semibold uppercase text-neutral-500 mb-1.5">
          Reason
        </label>
        <BaseSelect
          v-model="selectedReason"
          aria-label="Reason"
          :options="REJECTION_REASON_OPTIONS.map((item) => ({ label: item, value: item }))"
        />
      </div>

      <div>
        <label class="block text-[11px] font-semibold uppercase text-neutral-500 mb-1.5">
          Notes (Optional)
        </label>
        <textarea
          v-model="notes"
          rows="3"
          placeholder="Specify any missing stamps, plate discrepancies, or required re-uploads..."
          class="w-full px-3 py-2 border border-neutral-300 text-xs focus:outline-none focus:border-neutral-900"
        ></textarea>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-end space-x-2">
        <button
          type="button"
          class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
          @click="emit('update:showReject', false)"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold transition-colors cursor-pointer"
          @click="submitReject"
        >
          Confirm Rejection
        </button>
      </div>
    </template>
  </ModalDialog>
</template>
