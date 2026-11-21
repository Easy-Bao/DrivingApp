<script setup lang="ts">
import { computed, ref } from 'vue'
import { useVehicleClasses, type VehicleClassConfig } from '@/features/settings'
import { useCommissionTiers, useFarePricing } from '@/features/payments'
import {
  BaseSelect,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  formatBpsAsPercent,
  formatCentavos,
  useToast,
} from '@/shared'

const { vehicleClasses, saveVehicleClass, toggleVehicleClass } = useVehicleClasses()
const { rules: fareRules } = useFarePricing()
const { tiers: commissionTiers } = useCommissionTiers()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const showModal = ref(false)
const editingId = ref<string | null>(null)
const draftName = ref('')
const draftCode = ref('')
const draftDescription = ref('')
const draftCapacity = ref(3)
const draftFareRuleId = ref('')
const draftCommissionTierId = ref('')
const draftIsElectric = ref(false)
const modalError = ref<string | null>(null)

const fareRuleOptions = computed(() =>
  fareRules.value.map((rule) => ({
    label: `${rule.tier} (${formatCentavos(rule.baseFareCentavos)} base)`,
    value: rule.id,
  })),
)

const commissionTierOptions = computed(() =>
  commissionTiers.value.map((tier) => ({
    label: `${tier.category} (${formatBpsAsPercent(tier.rateBps)})`,
    value: tier.id,
  })),
)

function getFareLabel(id: string): string {
  const match = fareRules.value.find((rule) => rule.id === id)
  return match ? `${match.tier} (${formatCentavos(match.baseFareCentavos)})` : id
}

function getCommissionLabel(id: string): string {
  const match = commissionTiers.value.find((tier) => tier.id === id)
  return match ? `${match.category} (${formatBpsAsPercent(match.rateBps)})` : id
}

function openCreateModal() {
  editingId.value = null
  draftName.value = ''
  draftCode.value = ''
  draftDescription.value = ''
  draftCapacity.value = 3
  draftFareRuleId.value = fareRules.value[0]?.id ?? ''
  draftCommissionTierId.value = commissionTiers.value[0]?.id ?? ''
  draftIsElectric.value = false
  modalError.value = null
  showModal.value = true
}

function openEditModal(item: VehicleClassConfig) {
  editingId.value = item.id
  draftName.value = item.name
  draftCode.value = item.code
  draftDescription.value = item.description
  draftCapacity.value = item.passengerCapacity
  draftFareRuleId.value = item.fareRuleId
  draftCommissionTierId.value = item.commissionTierId
  draftIsElectric.value = item.isElectric
  modalError.value = null
  showModal.value = true
}

function submitVehicleClass() {
  const result = saveVehicleClass(editingId.value, {
    name: draftName.value,
    code: draftCode.value,
    description: draftDescription.value,
    passengerCapacity: Number(draftCapacity.value),
    fareRuleId: draftFareRuleId.value,
    commissionTierId: draftCommissionTierId.value,
    isElectric: draftIsElectric.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  showModal.value = false
  showToast(result.message ?? 'Saved vehicle class.', 'success')
}

function handleToggle(item: VehicleClassConfig) {
  const result = toggleVehicleClass(item.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated vehicle class status.', 'info')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Vehicle Classes"
      description="Manage Bao-Bao and fleet service classes, passenger capacities, and linked tariff and commission profiles."
    >
      <template #actions>
        <button
          type="button"
          class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="openCreateModal"
        >
          + Add Vehicle Class
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div
        v-for="item in vehicleClasses"
        :key="item.id"
        class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4"
      >
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-sm font-bold text-neutral-900">{{ item.name }}</h2>
                <StatusBadge
                  :label="item.isActive ? 'Active' : 'Paused'"
                  :tone="item.isActive ? 'success' : 'neutral'"
                />
                <StatusBadge v-if="item.isElectric" label="Zero-Emission" tone="info" />
              </div>
              <p class="text-[11px] font-mono text-neutral-500 mt-0.5">
                {{ item.code }} · {{ item.passengerCapacity }} pax max
              </p>
            </div>
          </div>

          <p class="text-xs text-neutral-600 leading-relaxed">{{ item.description }}</p>

          <div class="space-y-2 text-xs border-t border-neutral-100 pt-3">
            <div>
              <div class="text-[11px] text-neutral-500">Linked Fare Tariff</div>
              <div class="font-medium text-neutral-900 mt-0.5">
                {{ getFareLabel(item.fareRuleId) }}
              </div>
            </div>
            <div>
              <div class="text-[11px] text-neutral-500">Linked Commission Tier</div>
              <div class="font-medium text-neutral-900 mt-0.5">
                {{ getCommissionLabel(item.commissionTierId) }}
              </div>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-2 pt-2 border-t border-neutral-100">
          <button
            type="button"
            class="flex-1 py-1.5 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="openEditModal(item)"
          >
            Configure Class
          </button>
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
            @click="handleToggle(item)"
          >
            {{ item.isActive ? 'Pause' : 'Activate' }}
          </button>
        </div>
      </div>
    </div>

    <ModalDialog
      v-model:open="showModal"
      :title="editingId ? `Configure Vehicle Class · ${draftCode}` : 'Add Vehicle Class'"
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div class="sm:col-span-2">
            <label for="vc-name" class="block font-medium text-neutral-700 mb-1">
              Service Class Name
            </label>
            <input
              id="vc-name"
              v-model="draftName"
              type="text"
              placeholder="e.g., Cargo Bao-Bao Utility"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
            />
          </div>
          <div>
            <label for="vc-code" class="block font-medium text-neutral-700 mb-1">Code</label>
            <input
              id="vc-code"
              v-model="draftCode"
              type="text"
              placeholder="BAO-CRG"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
        </div>

        <div>
          <label for="vc-description" class="block font-medium text-neutral-700 mb-1">
            Operational Description
          </label>
          <textarea
            id="vc-description"
            v-model="draftDescription"
            rows="2"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>

        <div>
          <label for="vc-capacity" class="block font-medium text-neutral-700 mb-1">
            Max Passenger Capacity
          </label>
          <input
            id="vc-capacity"
            v-model.number="draftCapacity"
            type="number"
            min="1"
            max="12"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
          />
        </div>

        <div>
          <div class="font-medium text-neutral-700 mb-1">Assigned Fare Tariff</div>
          <BaseSelect
            v-model="draftFareRuleId"
            :full-width="true"
            aria-label="Assigned fare tariff"
            :options="fareRuleOptions"
          />
        </div>

        <div>
          <div class="font-medium text-neutral-700 mb-1">Assigned Commission Tier</div>
          <BaseSelect
            v-model="draftCommissionTierId"
            :full-width="true"
            aria-label="Assigned commission tier"
            :options="commissionTierOptions"
          />
        </div>

        <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
          <input v-model="draftIsElectric" type="checkbox" class="h-4 w-4 accent-neutral-900" />
          Mark as battery-electric / zero-emission vehicle class
        </label>

        <p v-if="modalError" role="alert" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="submitVehicleClass"
        >
          Save Vehicle Class
        </button>
      </template>
    </ModalDialog>
  </div>
</template>
