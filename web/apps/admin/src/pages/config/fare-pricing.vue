<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  BaseSelect,
  ConfirmDialog,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  formatCentavos,
  useToast,
} from '@/shared'
import {
  DEFAULT_PRICING_POLICY,
  usePricingPolicy,
  validatePricingPolicy,
  type DiscountEligibilityType,
  type FareDiscountRule,
  type PricingPolicyConfig,
} from '@/features/settings'
import { useFarePricing, type FareTierRule } from '@/features/payments'

const { rules, createFareRule, saveFareRule, toggleFareRuleActive } = useFarePricing()
const {
  policy,
  discounts,
  commitPricingPolicy,
  resetPricingDefaults,
  saveDiscountRule,
  toggleDiscountRule,
} = usePricingPolicy()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const showTariffModal = ref(false)
const editingRuleId = ref<string | null>(null)
const editTierTitle = ref('')
const editCorridorScope = ref('')
const editBaseFarePhp = ref(25)
const editPerKmPhp = ref(12)
const editPerMinutePhp = ref(2)
const editMinimumFarePhp = ref(25)
const editCancellationFeePhp = ref(15)
const editMaxSurgeCap = ref(2.5)
const editRatingBonus = ref(1.05)
const tariffModalError = ref<string | null>(null)

const activeTariffCount = computed(
  () => rules.value.filter((rule) => rule.isActive !== false).length,
)

function openCreateTariffModal() {
  editingRuleId.value = null
  editTierTitle.value = ''
  editCorridorScope.value = ''
  editBaseFarePhp.value = policy.value.baseFareCentavos / 100
  editPerKmPhp.value = 12
  editPerMinutePhp.value = 2
  editMinimumFarePhp.value = policy.value.baseFareCentavos / 100
  editCancellationFeePhp.value = policy.value.cancellationFeeCentavos / 100
  editMaxSurgeCap.value = policy.value.maxBiddingSurgeCap
  editRatingBonus.value = policy.value.ratingBonusMultiplier
  tariffModalError.value = null
  showTariffModal.value = true
}

function openEditTariffModal(rule: FareTierRule) {
  editingRuleId.value = rule.id
  editTierTitle.value = rule.tier
  editCorridorScope.value = rule.corridorScope
  editBaseFarePhp.value = rule.baseFareCentavos / 100
  editPerKmPhp.value = rule.perKmCentavos / 100
  editPerMinutePhp.value = rule.perMinuteCentavos / 100
  editMinimumFarePhp.value = rule.minimumFareCentavos / 100
  editCancellationFeePhp.value = rule.cancellationFeeCentavos / 100
  editMaxSurgeCap.value = rule.maxBiddingSurgeCap
  editRatingBonus.value = rule.highRatingDriverBonus
  tariffModalError.value = null
  showTariffModal.value = true
}

function closeTariffModal() {
  showTariffModal.value = false
  tariffModalError.value = null
}

function saveTariffChanges() {
  const payload = {
    tier: editTierTitle.value,
    corridorScope: editCorridorScope.value,
    baseFareCentavos: Math.round(Number(editBaseFarePhp.value) * 100),
    perKmCentavos: Math.round(Number(editPerKmPhp.value) * 100),
    perMinuteCentavos: Math.round(Number(editPerMinutePhp.value) * 100),
    minimumFareCentavos: Math.round(Number(editMinimumFarePhp.value) * 100),
    cancellationFeeCentavos: Math.round(Number(editCancellationFeePhp.value) * 100),
    maxBiddingSurgeCap: Number(editMaxSurgeCap.value),
    highRatingDriverBonus: Number(editRatingBonus.value),
  }

  const result = editingRuleId.value
    ? saveFareRule({ id: editingRuleId.value, ...payload })
    : createFareRule(payload)

  if (!result.ok) {
    tariffModalError.value = result.error
    return
  }

  closeTariffModal()
  showToast(result.message ?? `Saved tariff updates for ${editTierTitle.value}`, 'success')
}

function handleToggleTariff(rule: FareTierRule) {
  const result = toggleFareRuleActive(rule.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated tariff status.', 'info')
}

const policyDraft = ref<PricingPolicyConfig>({ ...policy.value })
const draftBaseFarePhp = ref(policy.value.baseFareCentavos / 100)
const draftCancellationFeePhp = ref(policy.value.cancellationFeeCentavos / 100)

watch(
  policy,
  (next) => {
    policyDraft.value = { ...next }
    draftBaseFarePhp.value = next.baseFareCentavos / 100
    draftCancellationFeePhp.value = next.cancellationFeeCentavos / 100
  },
  { deep: true },
)

const policyDraftPayload = computed<PricingPolicyConfig>(() => ({
  ...policyDraft.value,
  baseFareCentavos: Number.isFinite(draftBaseFarePhp.value)
    ? Math.round(draftBaseFarePhp.value * 100)
    : -1,
  cancellationFeeCentavos: Number.isFinite(draftCancellationFeePhp.value)
    ? Math.round(draftCancellationFeePhp.value * 100)
    : -1,
}))

const ratingThresholdLabel = computed(() =>
  Number.isFinite(policyDraft.value.ratingBonusThreshold)
    ? `${policyDraft.value.ratingBonusThreshold.toFixed(1)}★ Rating Bonus Factor`
    : 'Rating Bonus Factor',
)

const showPolicyConfirm = ref(false)
const policyAuditReason = ref('')

function requestSavePolicy() {
  const error = validatePricingPolicy(policyDraftPayload.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  policyAuditReason.value = ''
  showPolicyConfirm.value = true
}

function confirmSavePolicy() {
  const result = commitPricingPolicy(policyDraftPayload.value, policyAuditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showPolicyConfirm.value = false
  policyAuditReason.value = ''
  showToast(result.message ?? 'Saved global pricing policy.', 'success')
}

function handleResetPolicyDefaults() {
  resetPricingDefaults()
  policyDraft.value = { ...DEFAULT_PRICING_POLICY }
  draftBaseFarePhp.value = DEFAULT_PRICING_POLICY.baseFareCentavos / 100
  draftCancellationFeePhp.value = DEFAULT_PRICING_POLICY.cancellationFeeCentavos / 100
  showToast('Restored default pricing and surge policy.', 'success')
}

const showDiscountModal = ref(false)
const editingDiscountId = ref<string | null>(null)
const draftDiscountName = ref('')
const draftDiscountType = ref<DiscountEligibilityType>('Senior Citizen')
const draftDiscountPercent = ref(20)
const draftDiscountRequiresId = ref(true)
const draftDiscountRef = ref('')
const discountModalError = ref<string | null>(null)

function openCreateDiscount() {
  editingDiscountId.value = null
  draftDiscountName.value = ''
  draftDiscountType.value = 'Promotional'
  draftDiscountPercent.value = 10
  draftDiscountRequiresId.value = false
  draftDiscountRef.value = ''
  discountModalError.value = null
  showDiscountModal.value = true
}

function openEditDiscount(rule: FareDiscountRule) {
  editingDiscountId.value = rule.id
  draftDiscountName.value = rule.name
  draftDiscountType.value = rule.eligibilityType
  draftDiscountPercent.value = rule.discountPercent
  draftDiscountRequiresId.value = rule.requiresVerificationId
  draftDiscountRef.value = rule.legalReference
  discountModalError.value = null
  showDiscountModal.value = true
}

function saveDiscountChanges() {
  const result = saveDiscountRule(editingDiscountId.value, {
    name: draftDiscountName.value,
    eligibilityType: draftDiscountType.value,
    discountPercent: Number(draftDiscountPercent.value),
    requiresVerificationId: draftDiscountRequiresId.value,
    legalReference: draftDiscountRef.value,
  })
  if (!result.ok) {
    discountModalError.value = result.error
    return
  }
  showDiscountModal.value = false
  showToast(result.message ?? 'Saved fare discount rule.', 'success')
}

function handleToggleDiscount(rule: FareDiscountRule) {
  const result = toggleDiscountRule(rule.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated discount rule status.', 'info')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Fare Configuration"
      description="Configure corridor tariff matrices, global surge and rating multipliers, cancellation grace rules, and statutory discounts. Server-computed fare calculation."
    >
      <template #actions>
        <span class="text-xs font-mono text-neutral-500">
          {{ activeTariffCount }} Active / {{ rules.length }} Tiers
        </span>
        <button
          type="button"
          class="px-3.5 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="openCreateTariffModal"
        >
          + Add Tariff Tier
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <!-- 1. Corridor Tariff Matrix -->
    <section class="space-y-3" aria-labelledby="tariff-matrix-heading">
      <div class="flex items-center justify-between">
        <div>
          <h2
            id="tariff-matrix-heading"
            class="text-xs font-bold uppercase tracking-wider text-neutral-700"
          >
            Corridor Tariff Matrix
          </h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Base flagdown, distance, time increments, and per-tier ceilings persisted in exact
            integer centavos.
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div
          v-for="rule in rules"
          :key="rule.id"
          class="bg-white border border-neutral-200 p-5 space-y-4"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h3 class="text-sm font-bold text-neutral-900">{{ rule.tier }}</h3>
                <StatusBadge
                  :label="rule.isActive !== false ? 'Active' : 'Paused'"
                  :tone="rule.isActive !== false ? 'success' : 'neutral'"
                />
              </div>
              <p class="text-xs text-neutral-500 mt-0.5">{{ rule.corridorScope }}</p>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <button
                type="button"
                class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                @click="openEditTariffModal(rule)"
              >
                Edit Tariff
              </button>
              <button
                type="button"
                class="px-2.5 py-1.5 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
                @click="handleToggleTariff(rule)"
              >
                {{ rule.isActive !== false ? 'Pause' : 'Activate' }}
              </button>
            </div>
          </div>

          <div
            class="grid grid-cols-2 sm:grid-cols-3 gap-4 text-xs border-t border-neutral-100 pt-3"
          >
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
    </section>

    <!-- 2. Global Pricing, Surge & Rating Policy -->
    <section
      class="bg-white border border-neutral-200 p-5 space-y-5"
      aria-labelledby="pricing-policy-heading"
    >
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-neutral-100"
      >
        <div>
          <h2 id="pricing-policy-heading" class="text-sm font-bold text-neutral-900">
            Global Surge, Rating &amp; Cancellation Policy
          </h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Platform-wide pricing guardrails applied to all corridor tariffs, zone surge overrides,
            and rating multipliers.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2 shrink-0">
          <button
            id="reset-pricing-defaults"
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
            @click="handleResetPolicyDefaults"
          >
            Reset Defaults
          </button>
          <button
            id="save-pricing-policy"
            type="button"
            class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
            @click="requestSavePolicy"
          >
            Save Pricing Policy
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 text-xs">
        <div class="space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label for="policy-base-fare" class="block text-neutral-700 font-medium mb-1">
                Default Base Fare (PHP)
              </label>
              <input
                id="policy-base-fare"
                v-model.number="draftBaseFarePhp"
                type="number"
                min="1"
                step="1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-cancel-fee" class="block text-neutral-700 font-medium mb-1">
                Standard Cancel Fee (PHP)
              </label>
              <input
                id="policy-cancel-fee"
                v-model.number="draftCancellationFeePhp"
                type="number"
                min="0"
                step="1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-cancel-grace" class="block text-neutral-700 font-medium mb-1">
                Free Grace Window (Min)
              </label>
              <input
                id="policy-cancel-grace"
                v-model.number="policyDraft.cancellationGraceMinutes"
                type="number"
                min="0"
                max="15"
                step="1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label for="policy-max-surge" class="block text-neutral-700 font-medium mb-1">
                Max Surge Ceiling (x)
              </label>
              <input
                id="policy-max-surge"
                v-model.number="policyDraft.maxBiddingSurgeCap"
                type="number"
                min="1"
                max="2.5"
                step="0.1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-rating-threshold" class="block text-neutral-700 font-medium mb-1">
                Rating Bonus Min (★)
              </label>
              <input
                id="policy-rating-threshold"
                v-model.number="policyDraft.ratingBonusThreshold"
                type="number"
                min="1"
                max="5"
                step="0.1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-rating-multiplier" class="block text-neutral-700 font-medium mb-1">
                {{ ratingThresholdLabel }}
              </label>
              <input
                id="policy-rating-multiplier"
                v-model.number="policyDraft.ratingBonusMultiplier"
                type="number"
                min="1"
                max="1.2"
                step="0.01"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div>
            <label for="policy-low-rating-penalty" class="block text-neutral-700 font-medium mb-1">
              Low-Rating Surge Penalty Multiplier (0.5x–1.0x)
            </label>
            <input
              id="policy-low-rating-penalty"
              v-model.number="policyDraft.lowRatingSurgePenaltyMultiplier"
              type="number"
              min="0.5"
              max="1"
              step="0.05"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Caps surge participation for drivers below the minimum rating threshold (1.0x =
              neutral).
            </p>
          </div>
        </div>

        <div class="space-y-3">
          <div class="flex items-center justify-between py-2 border-b border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Dynamic Corridor Surge Multiplier</div>
              <div class="text-[11px] text-neutral-500">
                Allow geofenced demand multipliers up to the
                {{ policyDraft.maxBiddingSurgeCap.toFixed(1) }}x server cap
              </div>
            </div>
            <input
              v-model="policyDraft.enableSurgePricing"
              aria-label="Dynamic Corridor Surge Multiplier"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-b border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Night Differential Surcharge</div>
              <div class="text-[11px] text-neutral-500">
                Apply late-night corridor surcharge during configured operating hours
              </div>
            </div>
            <input
              v-model="policyDraft.enableNightDifferential"
              aria-label="Enable Night Differential Surcharge"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>

          <div class="grid grid-cols-3 gap-3 pt-1">
            <div>
              <label for="policy-night-percent" class="block text-neutral-700 font-medium mb-1">
                Night Surcharge (%)
              </label>
              <input
                id="policy-night-percent"
                v-model.number="policyDraft.nightDifferentialPercent"
                type="number"
                min="0"
                max="50"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-night-start" class="block text-neutral-700 font-medium mb-1">
                Start Hour (24h)
              </label>
              <input
                id="policy-night-start"
                v-model.number="policyDraft.nightStartHour"
                type="number"
                min="0"
                max="23"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="policy-night-end" class="block text-neutral-700 font-medium mb-1">
                End Hour (24h)
              </label>
              <input
                id="policy-night-end"
                v-model.number="policyDraft.nightEndHour"
                type="number"
                min="0"
                max="23"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 3. Statutory & Promotional Fare Discounts -->
    <section
      class="bg-white border border-neutral-200 overflow-hidden"
      aria-labelledby="fare-discounts-heading"
    >
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <h2 id="fare-discounts-heading" class="text-sm font-bold text-neutral-900">
            Statutory &amp; Fare Discounts
          </h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Mandated Philippine passenger discounts (Senior, PWD, Student) and approved fare
            concessions.
          </p>
        </div>
        <button
          type="button"
          class="self-start sm:self-auto px-3 py-1.5 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-900 text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateDiscount"
        >
          + Add Discount Rule
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[780px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Rule ID</th>
              <th class="py-3 px-4">Discount &amp; Reference</th>
              <th class="py-3 px-4">Eligibility</th>
              <th class="py-3 px-4">Rate</th>
              <th class="py-3 px-4">ID Verification</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr v-for="rule in discounts" :key="rule.id" class="hover:bg-neutral-50/70">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ rule.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ rule.name }}</div>
                <div class="text-[11px] text-neutral-500">{{ rule.legalReference }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="rule.eligibilityType" tone="info" />
              </td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">
                {{ rule.discountPercent }}%
              </td>
              <td class="py-3 px-4 text-neutral-700">
                {{ rule.requiresVerificationId ? 'Verified ID Required' : 'Open Eligibility' }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="rule.isActive ? 'Active' : 'Paused'"
                  :tone="rule.isActive ? 'success' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap space-x-2">
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                  @click="openEditDiscount(rule)"
                >
                  Edit
                </button>
                <button
                  type="button"
                  class="px-2.5 py-1 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
                  @click="handleToggleDiscount(rule)"
                >
                  {{ rule.isActive ? 'Pause' : 'Activate' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- Tariff Create/Edit Modal -->
    <ModalDialog
      v-model:open="showTariffModal"
      :title="editingRuleId ? `Edit Tariff · ${editTierTitle}` : 'Create Tariff Tier'"
      subtitle="Configure tariff parameters in PHP; persisted internally in exact integer centavos."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="tariff-tier-name" class="block font-medium text-neutral-700 mb-1">
            Tariff Tier Name
          </label>
          <input
            id="tariff-tier-name"
            v-model="editTierTitle"
            type="text"
            placeholder="e.g., Night Express Corridor"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>

        <div>
          <label for="tariff-corridor-scope" class="block font-medium text-neutral-700 mb-1">
            Corridor Scope
          </label>
          <input
            id="tariff-corridor-scope"
            v-model="editCorridorScope"
            type="text"
            placeholder="e.g., Inter-barangay uphill routes (> 5 km)"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label for="tariff-base-fare" class="block font-medium text-neutral-700 mb-1">
              Base Fare (PHP)
            </label>
            <input
              id="tariff-base-fare"
              v-model.number="editBaseFarePhp"
              type="number"
              min="1"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="tariff-per-km" class="block font-medium text-neutral-700 mb-1">
              Per Km (PHP)
            </label>
            <input
              id="tariff-per-km"
              v-model.number="editPerKmPhp"
              type="number"
              min="1"
              step="0.5"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="tariff-per-minute" class="block font-medium text-neutral-700 mb-1">
              Per Minute (PHP)
            </label>
            <input
              id="tariff-per-minute"
              v-model.number="editPerMinutePhp"
              type="number"
              min="0"
              step="0.5"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="tariff-minimum-fare" class="block font-medium text-neutral-700 mb-1">
              Minimum Fare (PHP)
            </label>
            <input
              id="tariff-minimum-fare"
              v-model.number="editMinimumFarePhp"
              type="number"
              min="1"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="tariff-cancellation-fee" class="block font-medium text-neutral-700 mb-1">
              Cancellation Fee (PHP)
            </label>
            <input
              id="tariff-cancellation-fee"
              v-model.number="editCancellationFeePhp"
              type="number"
              min="0"
              step="1"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="tariff-max-surge" class="block font-medium text-neutral-700 mb-1">
              Max Surge Multiplier (1.0x–{{ policy.maxBiddingSurgeCap.toFixed(1) }}x)
            </label>
            <input
              id="tariff-max-surge"
              v-model.number="editMaxSurgeCap"
              type="number"
              min="1"
              :max="policy.maxBiddingSurgeCap"
              step="0.1"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div class="col-span-2">
            <label for="tariff-rating-bonus" class="block font-medium text-neutral-700 mb-1">
              High-Rating VIP Driver Bonus Multiplier (1.0x–1.2x)
            </label>
            <input
              id="tariff-rating-bonus"
              v-model.number="editRatingBonus"
              type="number"
              min="1"
              max="1.2"
              step="0.01"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
        </div>
      </div>

      <p v-if="tariffModalError" role="alert" class="mt-3 text-xs font-medium text-rose-700">
        {{ tariffModalError }}
      </p>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="closeTariffModal"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
          @click="saveTariffChanges"
        >
          Save Tariff Rule
        </button>
      </template>
    </ModalDialog>

    <!-- Discount Rule Create/Edit Modal -->
    <ModalDialog
      v-model:open="showDiscountModal"
      :title="
        editingDiscountId ? `Edit Discount Rule · ${editingDiscountId}` : 'Add Fare Discount Rule'
      "
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="discount-name" class="block font-medium text-neutral-700 mb-1">
            Discount Rule Name
          </label>
          <input
            id="discount-name"
            v-model="draftDiscountName"
            type="text"
            placeholder="e.g., Solo Parent LGU Concession"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <div class="font-medium text-neutral-700 mb-1">Eligibility Type</div>
            <BaseSelect
              v-model="draftDiscountType"
              :full-width="true"
              aria-label="Discount eligibility type"
              :options="['Senior Citizen', 'PWD', 'Student', 'Promotional']"
            />
          </div>
          <div>
            <label for="discount-percent" class="block font-medium text-neutral-700 mb-1">
              Discount Rate (1–50%)
            </label>
            <input
              id="discount-percent"
              v-model.number="draftDiscountPercent"
              type="number"
              min="1"
              max="50"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
        </div>
        <div>
          <label for="discount-reference" class="block font-medium text-neutral-700 mb-1">
            Statutory or Policy Reference
          </label>
          <input
            id="discount-reference"
            v-model="draftDiscountRef"
            type="text"
            placeholder="e.g., RA 9994 / City Ordinance 2026-04"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
          <input
            v-model="draftDiscountRequiresId"
            type="checkbox"
            class="h-4 w-4 accent-neutral-900"
          />
          Require verified passenger ID before applying discount
        </label>
        <p v-if="discountModalError" role="alert" class="text-rose-700 font-medium">
          {{ discountModalError }}
        </p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showDiscountModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="saveDiscountChanges"
        >
          Save Discount Rule
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:open="showPolicyConfirm"
      v-model:reason="policyAuditReason"
      title="Publish Global Pricing Policy"
      description="Changes update server-computed fare defaults, surge ceilings, and driver rating multipliers."
      confirm-label="Apply Pricing Policy"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Aligned Pagadian peak surge cap after weekly review..."
      @confirm="confirmSavePolicy"
      @cancel="showPolicyConfirm = false"
    />
  </div>
</template>
