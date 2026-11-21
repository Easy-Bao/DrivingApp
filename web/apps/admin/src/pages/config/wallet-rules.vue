<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  DEFAULT_WALLET_POLICY,
  useWalletPolicy,
  validateWalletPolicy,
  type WalletPolicyConfig,
} from '@/features/settings'
import { ConfirmDialog, PageHeader, ToastBanner, formatCentavos, useToast } from '@/shared'

const { policy, commitWalletPolicy, resetWalletDefaults } = useWalletPolicy()
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const minDispatchPhp = ref(policy.value.minWalletBalanceCentavos / 100)
const lowWarningPhp = ref(policy.value.lowBalanceWarningCentavos / 100)
const minTopUpPhp = ref(policy.value.minTopUpAmountCentavos / 100)
const maxTopUpPhp = ref(policy.value.maxTopUpAmountCentavos / 100)
const autoLockLowBalance = ref(policy.value.autoLockLowBalanceDispatch)
const requireReceiptProof = ref(policy.value.requireReceiptProof)
const verificationSlaMinutes = ref(policy.value.topUpVerificationSlaMinutes)

watch(
  policy,
  (next) => {
    minDispatchPhp.value = next.minWalletBalanceCentavos / 100
    lowWarningPhp.value = next.lowBalanceWarningCentavos / 100
    minTopUpPhp.value = next.minTopUpAmountCentavos / 100
    maxTopUpPhp.value = next.maxTopUpAmountCentavos / 100
    autoLockLowBalance.value = next.autoLockLowBalanceDispatch
    requireReceiptProof.value = next.requireReceiptProof
    verificationSlaMinutes.value = next.topUpVerificationSlaMinutes
  },
  { deep: true },
)

const draftPayload = computed<WalletPolicyConfig>(() => ({
  minWalletBalanceCentavos: Number.isFinite(minDispatchPhp.value)
    ? Math.round(minDispatchPhp.value * 100)
    : -1,
  lowBalanceWarningCentavos: Number.isFinite(lowWarningPhp.value)
    ? Math.round(lowWarningPhp.value * 100)
    : -1,
  minTopUpAmountCentavos: Number.isFinite(minTopUpPhp.value)
    ? Math.round(minTopUpPhp.value * 100)
    : -1,
  maxTopUpAmountCentavos: Number.isFinite(maxTopUpPhp.value)
    ? Math.round(maxTopUpPhp.value * 100)
    : -1,
  autoLockLowBalanceDispatch: autoLockLowBalance.value,
  requireReceiptProof: requireReceiptProof.value,
  topUpVerificationSlaMinutes: Number(verificationSlaMinutes.value),
}))

const formattedMinBalance = computed(() =>
  draftPayload.value.minWalletBalanceCentavos >= 0
    ? formatCentavos(draftPayload.value.minWalletBalanceCentavos)
    : '₱0.00',
)

const confirmOpen = ref(false)
const auditReason = ref('')

function requestSave() {
  const error = validateWalletPolicy(draftPayload.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  auditReason.value = ''
  confirmOpen.value = true
}

function confirmSave() {
  const result = commitWalletPolicy(draftPayload.value, auditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  confirmOpen.value = false
  auditReason.value = ''
  showToast(result.message ?? 'Saved wallet policy.', 'success')
}

function handleResetDefaults() {
  resetWalletDefaults()
  minDispatchPhp.value = DEFAULT_WALLET_POLICY.minWalletBalanceCentavos / 100
  lowWarningPhp.value = DEFAULT_WALLET_POLICY.lowBalanceWarningCentavos / 100
  minTopUpPhp.value = DEFAULT_WALLET_POLICY.minTopUpAmountCentavos / 100
  maxTopUpPhp.value = DEFAULT_WALLET_POLICY.maxTopUpAmountCentavos / 100
  autoLockLowBalance.value = DEFAULT_WALLET_POLICY.autoLockLowBalanceDispatch
  requireReceiptProof.value = DEFAULT_WALLET_POLICY.requireReceiptProof
  verificationSlaMinutes.value = DEFAULT_WALLET_POLICY.topUpVerificationSlaMinutes
  showToast('Restored default driver wallet & top-up rules.', 'success')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Wallet & Top-Up Rules"
      description="Single source of truth for driver prepaid wallet thresholds, dispatch auto-lock, and QRPh/bank top-up limits."
    >
      <template #actions>
        <RouterLink
          to="/config/payment-channels"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium"
        >
          Payment Channels
        </RouterLink>
        <button
          id="reset-wallet-defaults"
          type="button"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-wallet-policy"
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="requestSave"
        >
          Save Wallet Rules
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Dispatch Eligibility Thresholds</h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Controls live dispatch standing across Wallets, Top-Ups, and Drivers.
          </p>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label for="wallet-min-dispatch" class="block text-neutral-700 font-medium mb-1">
              Minimum Driver Wallet Balance for Dispatch (PHP ₱)
            </label>
            <input
              id="wallet-min-dispatch"
              v-model.number="minDispatchPhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Drivers below {{ formattedMinBalance }} cannot accept new cash bid requests
            </p>
          </div>

          <div>
            <label for="wallet-low-warning" class="block text-neutral-700 font-medium mb-1">
              Low-Balance Reminder Threshold (PHP ₱)
            </label>
            <input
              id="wallet-low-warning"
              v-model.number="lowWarningPhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Triggers proactive driver app notification before dispatch lock is reached
            </p>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Auto-Lock Low-Balance Dispatch</div>
              <div class="text-[11px] text-neutral-500">
                Automatically pause bidding eligibility when prepaid balance drops below
                {{ formattedMinBalance }}
              </div>
            </div>
            <input
              v-model="autoLockLowBalance"
              aria-label="Auto-Lock Low-Balance Dispatch"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Top-Up Limits &amp; Verification SLA</h2>
          <p class="text-xs text-neutral-500 mt-0.5">
            Applied to QRPh and corporate bank deposit requests submitted by drivers.
          </p>
        </div>

        <div class="space-y-3 text-xs">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="wallet-min-topup" class="block text-neutral-700 font-medium mb-1">
                Minimum Top-Up Increment (PHP ₱)
              </label>
              <input
                id="wallet-min-topup"
                v-model.number="minTopUpPhp"
                type="number"
                min="10"
                step="10"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="wallet-max-topup" class="block text-neutral-700 font-medium mb-1">
                Maximum Single Top-Up (PHP ₱)
              </label>
              <input
                id="wallet-max-topup"
                v-model.number="maxTopUpPhp"
                type="number"
                min="50"
                step="100"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div>
            <label for="wallet-verification-sla" class="block text-neutral-700 font-medium mb-1">
              Treasury Verification SLA Target (Minutes)
            </label>
            <input
              id="wallet-verification-sla"
              v-model.number="verificationSlaMinutes"
              type="number"
              min="5"
              max="240"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Expected review window for finance operators verifying uploaded deposit slips
            </p>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Require Deposit Receipt Proof</div>
              <div class="text-[11px] text-neutral-500">
                Drivers must attach a QRPh or bank transfer screenshot before queuing credit review
              </div>
            </div>
            <input
              v-model="requireReceiptProof"
              aria-label="Require Deposit Receipt Proof"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish Wallet & Top-Up Rules"
      description="Changes immediately update driver dispatch eligibility thresholds and top-up validation rules."
      confirm-label="Apply Wallet Rules"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Adjusted minimum prepaid balance reserve per treasury review..."
      @confirm="confirmSave"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
