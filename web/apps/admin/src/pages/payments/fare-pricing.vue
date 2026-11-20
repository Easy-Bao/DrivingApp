<script setup lang="ts">
import { ref } from 'vue'
import { formatCentavos, ModalDialog, PageHeader, ToastBanner, useToast } from '@/shared'
import { useFarePricing } from '@/features/payments'
import type { FareTierRule } from '@/features/payments'

const { rules, saveFareRule } = useFarePricing()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')
const showEditModal = ref(false)
const editRuleId = ref('')
const editTierTitle = ref('')
const editCorridorScope = ref('')
const editBaseFarePhp = ref(25)
const editPerKmPhp = ref(12)
const editPerMinutePhp = ref(2)
const editMinimumFarePhp = ref(25)
const editCancellationFeePhp = ref(15)
const editMaxSurgeCap = ref(2.5)
const editRatingBonus = ref(1.05)
const modalError = ref<string | null>(null)

function openEditModal(rule: FareTierRule) {
  editRuleId.value = rule.id
  editTierTitle.value = rule.tier
  editCorridorScope.value = rule.corridorScope
  editBaseFarePhp.value = rule.baseFareCentavos / 100
  editPerKmPhp.value = rule.perKmCentavos / 100
  editPerMinutePhp.value = rule.perMinuteCentavos / 100
  editMinimumFarePhp.value = rule.minimumFareCentavos / 100
  editCancellationFeePhp.value = rule.cancellationFeeCentavos / 100
  editMaxSurgeCap.value = rule.maxBiddingSurgeCap
  editRatingBonus.value = rule.highRatingDriverBonus
  modalError.value = null
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  modalError.value = null
}

function saveRuleChanges() {
  const result = saveFareRule({
    id: editRuleId.value,
    tier: editTierTitle.value,
    corridorScope: editCorridorScope.value,
    baseFareCentavos: Math.round(Number(editBaseFarePhp.value) * 100),
    perKmCentavos: Math.round(Number(editPerKmPhp.value) * 100),
    perMinuteCentavos: Math.round(Number(editPerMinutePhp.value) * 100),
    minimumFareCentavos: Math.round(Number(editMinimumFarePhp.value) * 100),
    cancellationFeeCentavos: Math.round(Number(editCancellationFeePhp.value) * 100),
    maxBiddingSurgeCap: Number(editMaxSurgeCap.value),
    highRatingDriverBonus: Number(editRatingBonus.value),
  })

  if (!result.ok) {
    modalError.value = result.error
    return
  }

  closeEditModal()
  showToast(result.message ?? `Saved tariff updates for ${editTierTitle.value}`, 'success')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Tariff Rates"
      description="Configure corridor base fares, distance increments, cancellation fees, and bidding ceilings."
    >
      <template #actions>
        <span
          class="inline-flex items-center border border-neutral-200 bg-white px-3 py-1.5 text-xs font-medium text-neutral-700"
        >
          Server-computed fare calculation
        </span>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <div
        v-for="rule in rules"
        :key="rule.id"
        class="bg-white border border-neutral-200 p-5 space-y-4"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <h2 class="text-sm font-bold text-neutral-900">{{ rule.tier }}</h2>
            <p class="text-xs text-neutral-500 mt-0.5">{{ rule.corridorScope }}</p>
          </div>
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer shrink-0"
            @click="openEditModal(rule)"
          >
            Edit Tariff
          </button>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 text-xs border-t border-neutral-100 pt-3">
          <div>
            <div class="text-neutral-500">Base Fare (1st km)</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ formatCentavos(rule.baseFareCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Per Km Increment</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ formatCentavos(rule.perKmCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Per Minute Rate</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ formatCentavos(rule.perMinuteCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Minimum Fare</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ formatCentavos(rule.minimumFareCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Cancellation Fee</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ formatCentavos(rule.cancellationFeeCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Bidding Surge Cap</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              Up to {{ rule.maxBiddingSurgeCap }}x ({{ rule.highRatingDriverBonus }}x VIP)
            </div>
          </div>
        </div>
      </div>
    </div>

    <ModalDialog
      v-model:open="showEditModal"
      :title="`Edit Tariff · ${editTierTitle}`"
      subtitle="Configure tariff parameters in PHP; persisted internally in exact integer centavos."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Corridor Scope</label>
          <input
            v-model="editCorridorScope"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Base Fare (PHP)</label>
            <input
              v-model.number="editBaseFarePhp"
              type="number"
              min="1"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Per Km (PHP)</label>
            <input
              v-model.number="editPerKmPhp"
              type="number"
              min="1"
              step="0.5"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Per Minute (PHP)</label>
            <input
              v-model.number="editPerMinutePhp"
              type="number"
              min="0"
              step="0.5"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Minimum Fare (PHP)</label>
            <input
              v-model.number="editMinimumFarePhp"
              type="number"
              min="1"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Cancellation Fee (PHP)</label>
            <input
              v-model.number="editCancellationFeePhp"
              type="number"
              min="0"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Max Surge Multiplier</label>
            <input
              v-model.number="editMaxSurgeCap"
              type="number"
              min="1"
              max="2.5"
              step="0.1"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
        </div>
      </div>

      <p v-if="modalError" class="mt-3 text-xs font-medium text-rose-700">{{ modalError }}</p>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="closeEditModal"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 cursor-pointer"
            @click="saveRuleChanges"
          >
            Save Tariff Rule
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
