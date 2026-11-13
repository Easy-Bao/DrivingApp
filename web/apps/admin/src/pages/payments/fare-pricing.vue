<script setup lang="ts">
import { computed, ref } from 'vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

interface FareTierRule {
  id: string
  tier: string
  corridorScope: string
  baseFare: number
  perKm: number
  perMinute: number
  minimumFare: number
  cancellationFee: number
  maxBiddingSurgeCap: number
  highRatingDriverBonus: number
}

const pricingRules = ref<FareTierRule[]>([
  {
    id: 'solo-standard',
    tier: 'Solo Taxicle · Standard Poblacion',
    corridorScope: 'Urban Poblacion & market barangays (<= 5 km)',
    baseFare: 25.0,
    perKm: 12.0,
    perMinute: 2.0,
    minimumFare: 25.0,
    cancellationFee: 15.0,
    maxBiddingSurgeCap: 2.5,
    highRatingDriverBonus: 1.05,
  },
  {
    id: 'solo-express',
    tier: 'Solo Taxicle · Terminal & Uphill Express',
    corridorScope: 'Integrated Bus Terminal, Dao Capitol & Airport Road',
    baseFare: 35.0,
    perKm: 14.0,
    perMinute: 2.5,
    minimumFare: 40.0,
    cancellationFee: 20.0,
    maxBiddingSurgeCap: 2.5,
    highRatingDriverBonus: 1.05,
  },
])

const selectedTierId = ref<string>('solo-standard')
const estimateDistanceKm = ref<number>(3.4)
const estimateDurationMin = ref<number>(12)
const estimateSurge = ref<number>(1.0)
const qualifyRatingBonus = ref<boolean>(false)

const toastMessage = ref<string | null>(null)
const editingRule = ref<FareTierRule | null>(null)
const draftRule = ref<FareTierRule | null>(null)
const modalError = ref<string | null>(null)

const activeEstimatorTier = computed(
  () => pricingRules.value.find((r) => r.id === selectedTierId.value) ?? pricingRules.value[0]!,
)

const estimatedFare = computed(() => {
  const tier = activeEstimatorTier.value
  const rawBase =
    tier.baseFare +
    Math.max(0, estimateDistanceKm.value - 1) * tier.perKm +
    estimateDurationMin.value * tier.perMinute
  const floored = Math.max(rawBase, tier.minimumFare)
  const clampedSurge = Math.min(Math.max(1.0, estimateSurge.value), tier.maxBiddingSurgeCap)
  const ratedMultiplier = qualifyRatingBonus.value ? tier.highRatingDriverBonus : 1.0
  return Number((floored * clampedSurge * ratedMultiplier).toFixed(2))
})

const estimatedDriverTakeHome = computed(() => Number((estimatedFare.value * 0.85).toFixed(2)))
const estimatedPlatformCut = computed(() =>
  Number((estimatedFare.value - estimatedDriverTakeHome.value).toFixed(2)),
)

const openEditModal = (rule: FareTierRule) => {
  editingRule.value = rule
  draftRule.value = { ...rule }
  modalError.value = null
}

const closeEditModal = () => {
  editingRule.value = null
  draftRule.value = null
  modalError.value = null
}

const saveRuleChanges = () => {
  if (!editingRule.value || !draftRule.value) return
  if (
    draftRule.value.baseFare <= 0 ||
    draftRule.value.perKm <= 0 ||
    draftRule.value.minimumFare <= 0 ||
    draftRule.value.maxBiddingSurgeCap < 1 ||
    draftRule.value.maxBiddingSurgeCap > 2.5
  ) {
    modalError.value =
      'Verify PHP tariff rates are positive and bidding surge cap remains within 1.0x–2.5x.'
    return
  }
  Object.assign(editingRule.value, draftRule.value)
  toastMessage.value = `Saved tariff updates for ${editingRule.value.tier} (${formatPhp(editingRule.value.baseFare)} base).`
  closeEditModal()
}

const saveInlineChanges = () => {
  toastMessage.value =
    'Published Pagadian Solo Taxicle tariff parameters to bidding & quote calculation engine.'
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <div
      class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white border border-neutral-200 p-4"
    >
      <div>
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="text-sm font-semibold text-neutral-900">
            Pagadian Solo Taxicle Fare &amp; Bidding Caps
          </h2>
          <StatusBadge label="PHP Active Tariff" tone="neutral" />
        </div>
        <p class="text-xs text-neutral-500 mt-0.5">
          All amounts in Philippine Pesos (₱). Server enforces a 2.5x maximum bidding surge cap and
          a 1.05x reward multiplier for drivers rated 4.5★ or higher.
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="text-sm font-semibold text-neutral-900">Active Regional Pricing Matrix</h3>
          <span class="text-xs text-neutral-500 font-mono">Pagadian City · 7016</span>
        </div>
        <button
          type="button"
          class="self-start sm:self-auto px-4 py-1.5 bg-neutral-900 text-white text-xs font-medium rounded-none hover:bg-neutral-800 transition-colors cursor-pointer shrink-0"
          @click="saveInlineChanges"
        >
          Publish Tariff Matrix
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[920px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Taxicle Service Tier</th>
              <th class="py-3 px-4">Base Fare (₱)</th>
              <th class="py-3 px-4">Rate / km (₱)</th>
              <th class="py-3 px-4">Rate / min (₱)</th>
              <th class="py-3 px-4">Min Fare (₱)</th>
              <th class="py-3 px-4">Cancel Fee (₱)</th>
              <th class="py-3 px-4">Max Bid Cap</th>
              <th class="py-3 px-4">4.5★ Bonus</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="rule in pricingRules"
              :key="rule.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-bold text-neutral-900">{{ rule.tier }}</div>
                <div class="text-[11px] text-neutral-500">{{ rule.corridorScope }}</div>
              </td>
              <td class="py-3.5 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                {{ formatPhp(rule.baseFare) }}
              </td>
              <td class="py-3.5 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(rule.perKm) }}
              </td>
              <td class="py-3.5 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(rule.perMinute) }}
              </td>
              <td class="py-3.5 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(rule.minimumFare) }}
              </td>
              <td class="py-3.5 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(rule.cancellationFee) }}
              </td>
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900">
                {{ rule.maxBiddingSurgeCap.toFixed(1) }}x
              </td>
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900">
                {{ rule.highRatingDriverBonus.toFixed(2) }}x
              </td>
              <td class="py-3.5 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                  @click="openEditModal(rule)"
                >
                  Edit Tariff
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 p-5 space-y-4">
      <div class="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 class="text-sm font-semibold text-neutral-900">
            Pagadian Bidding Fare Floor Simulator
          </h3>
          <p class="text-xs text-neutral-500">
            Preview recommended starting fare and commission split before passenger bid broadcast.
          </p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="tier in pricingRules"
            :key="tier.id"
            type="button"
            class="px-3 py-1 border rounded-none text-xs font-medium transition-colors"
            :class="
              selectedTierId === tier.id
                ? 'bg-neutral-900 text-white border-neutral-900'
                : 'bg-white text-neutral-700 border-neutral-300 hover:bg-neutral-50'
            "
            @click="selectedTierId = tier.id"
          >
            {{ tier.tier }}
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Trip Distance (km)</label>
          <input
            v-model.number="estimateDistanceKm"
            type="number"
            min="0.5"
            step="0.2"
            aria-label="Simulator distance in kilometers"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Estimated Duration (min)</label>
          <input
            v-model.number="estimateDurationMin"
            type="number"
            min="2"
            step="1"
            aria-label="Simulator duration in minutes"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Demand Surge (1.0x–2.5x)</label>
          <input
            v-model.number="estimateSurge"
            type="number"
            min="1"
            max="2.5"
            step="0.1"
            aria-label="Simulator demand multiplier"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <div class="flex items-end pb-1.5">
          <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
            <input
              v-model="qualifyRatingBonus"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
            Apply 4.5★ Driver Bonus (1.05x)
          </label>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 border-t border-neutral-100 pt-4 text-xs">
        <div class="bg-neutral-50 border border-neutral-200 p-3">
          <div class="text-neutral-500">Recommended Fare Floor</div>
          <div
            data-testid="estimated-fare"
            class="text-lg font-bold font-mono text-neutral-900 mt-0.5 tabular-nums"
          >
            {{ formatPhp(estimatedFare) }}
          </div>
        </div>
        <div class="bg-neutral-50 border border-neutral-200 p-3">
          <div class="text-neutral-500">15% Prepaid Commission Deducted</div>
          <div class="text-lg font-bold font-mono text-neutral-900 mt-0.5 tabular-nums">
            {{ formatPhp(estimatedPlatformCut) }}
          </div>
        </div>
        <div class="bg-neutral-50 border border-neutral-200 p-3">
          <div class="text-neutral-500">Driver Cash Take-Home</div>
          <div class="text-lg font-bold font-mono text-neutral-900 mt-0.5 tabular-nums">
            {{ formatPhp(estimatedDriverTakeHome) }}
          </div>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="editingRule && draftRule"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="closeEditModal"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-lg bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">Edit Tariff · {{ editingRule.tier }}</h3>
            <p class="text-xs text-neutral-500 mt-0.5">{{ editingRule.corridorScope }}</p>
          </div>

          <div class="grid grid-cols-2 gap-3 text-xs">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Base Fare (₱)</label>
              <input
                v-model.number="draftRule.baseFare"
                type="number"
                step="1"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Rate / km (₱)</label>
              <input
                v-model.number="draftRule.perKm"
                type="number"
                step="0.5"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Rate / min (₱)</label>
              <input
                v-model.number="draftRule.perMinute"
                type="number"
                step="0.5"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Min Trip Fare (₱)</label>
              <input
                v-model.number="draftRule.minimumFare"
                type="number"
                step="1"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Cancellation Fee (₱)</label>
              <input
                v-model.number="draftRule.cancellationFee"
                type="number"
                step="1"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Max Bid Surge (x)</label>
              <input
                v-model.number="draftRule.maxBiddingSurgeCap"
                type="number"
                min="1"
                max="2.5"
                step="0.1"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
            </div>
          </div>

          <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
              @click="closeEditModal"
            >
              Cancel
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
              @click="saveRuleChanges"
            >
              Save Tariff Rule
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
