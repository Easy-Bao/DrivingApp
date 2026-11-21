import { computed, ref } from 'vue'
import { formatCentavos } from '@/shared'
import { useAuditLogs, usePlatformConfig, useWalletPolicy } from '@/features/settings'
import { buildQrSvg } from '@/features/payments/domain/svg-receipt'
import {
  validateCommissionTierInput,
  validateCompanyAccountInput,
  validateFareRuleInput,
  validateMerchantReference,
  validateWalletAdjustment,
} from '@/features/payments/domain/validation'
import {
  INITIAL_COLLECTION_ACCOUNTS,
  INITIAL_COMMISSION_TIERS,
  INITIAL_DRIVER_EARNINGS,
  INITIAL_DRIVER_WALLETS,
  INITIAL_FARE_RULES,
  INITIAL_REFUND_CLAIMS,
  INITIAL_WALLET_TRANSACTIONS,
} from '@/features/payments/data/payments.seed'
import type {
  CommissionTier,
  CompanyCollectionAccount,
  CreateCommissionTierInput,
  CreateCompanyAccountInput,
  CreateFareTierRuleInput,
  DriverEarningSummary,
  DriverWalletRow,
  FareAdjustmentClaim,
  FareTierRule,
  PaymentMutationResult,
  SaveCommissionTierInput,
  TopUpRequest,
  UpdateCompanyAccountInput,
  WalletLedgerEntry,
} from '@/features/payments/types'

function cloneList<T>(items: readonly T[]): T[] {
  return items.map((item) => ({ ...item }))
}

const transactions = ref<WalletLedgerEntry[]>(cloneList(INITIAL_WALLET_TRANSACTIONS))
const wallets = ref<DriverWalletRow[]>(cloneList(INITIAL_DRIVER_WALLETS))
const earnings = ref<DriverEarningSummary[]>(cloneList(INITIAL_DRIVER_EARNINGS))
const commissionTiers = ref<CommissionTier[]>(cloneList(INITIAL_COMMISSION_TIERS))
const fareRules = ref<FareTierRule[]>(cloneList(INITIAL_FARE_RULES))
const collectionAccounts = ref<CompanyCollectionAccount[]>(cloneList(INITIAL_COLLECTION_ACCOUNTS))
const refundClaims = ref<FareAdjustmentClaim[]>(cloneList(INITIAL_REFUND_CLAIMS))
let nextLedgerSequence = 9402

function syncDriverEarningStanding(driverName: string, balanceCentavos: number) {
  const { config } = usePlatformConfig()
  const earningRow = earnings.value.find((row) => row.driver === driverName)
  if (!earningRow) return
  earningRow.walletStatus =
    balanceCentavos >= config.value.minWalletBalanceCentavos
      ? 'Prepaid Credit Active'
      : 'Low Prepaid Wallet'
}

export function resetPaymentsLedgerForTesting() {
  transactions.value = cloneList(INITIAL_WALLET_TRANSACTIONS)
  wallets.value = cloneList(INITIAL_DRIVER_WALLETS)
  earnings.value = cloneList(INITIAL_DRIVER_EARNINGS)
  commissionTiers.value = cloneList(INITIAL_COMMISSION_TIERS)
  fareRules.value = cloneList(INITIAL_FARE_RULES)
  collectionAccounts.value = cloneList(INITIAL_COLLECTION_ACCOUNTS)
  refundClaims.value = cloneList(INITIAL_REFUND_CLAIMS)
  nextLedgerSequence = 9402
}

export function syncTopupCreditToLedger(topup: TopUpRequest) {
  const wallet = wallets.value.find((row) => row.driver === topup.driverName)
  if (wallet) {
    wallet.balanceCentavos += topup.amountCentavos
    wallet.totalTopupsCentavos += topup.amountCentavos
    wallet.lastTopupAt = 'Just now'
    syncDriverEarningStanding(topup.driverName, wallet.balanceCentavos)
  }

  const existingEntry = transactions.value.find((entry) => entry.referenceId === topup.id)
  if (existingEntry) {
    existingEntry.status = 'Settled'
    existingEntry.timestamp = 'Just now'
    return
  }

  transactions.value.unshift({
    id: `TXN-7016-${nextLedgerSequence++}`,
    referenceId: topup.id,
    driver: topup.driverName,
    type: topup.paymentMethod === 'Company QR Code' ? 'QRPh Wallet Top-Up' : 'Bank Top-Up',
    method: `${topup.channelProvider} · ${topup.referenceCode}`,
    amountCentavos: topup.amountCentavos,
    direction: 'credit',
    status: 'Settled',
    timestamp: 'Just now',
  })
}

export function useWalletTransactions() {
  return {
    transactions: computed(() => transactions.value),
  }
}

export function useWalletAccounts() {
  const { config } = usePlatformConfig()
  const { policy: walletPolicy } = useWalletPolicy()
  const { appendAuditLog } = useAuditLogs()

  const minDispatchBalanceCentavos = computed(() => config.value.minWalletBalanceCentavos)
  const minTopUpAmountCentavos = computed(() => walletPolicy.value.minTopUpAmountCentavos)

  function adjustDriverWallet(
    driverId: string,
    input: { direction: 'credit' | 'debit'; amountCentavos: number; reason: string },
  ): PaymentMutationResult {
    const validationError = validateWalletAdjustment(input.amountCentavos, input.reason)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const wallet = wallets.value.find((row) => row.driverId === driverId)
    if (!wallet) {
      return { ok: false, error: `Driver wallet ${driverId} was not found.` }
    }

    if (input.direction === 'debit' && wallet.balanceCentavos < input.amountCentavos) {
      return {
        ok: false,
        error: `Cannot debit ${formatCentavos(input.amountCentavos)} from ${wallet.driver}; available balance is ${formatCentavos(wallet.balanceCentavos)}.`,
      }
    }

    const signedCentavos =
      input.direction === 'credit' ? input.amountCentavos : -input.amountCentavos
    wallet.balanceCentavos += signedCentavos
    if (input.direction === 'credit') {
      wallet.totalTopupsCentavos += input.amountCentavos
      wallet.lastTopupAt = 'Just now'
    }
    syncDriverEarningStanding(wallet.driver, wallet.balanceCentavos)

    const trimmedReason = input.reason.trim()
    transactions.value.unshift({
      id: `TXN-7016-${nextLedgerSequence++}`,
      referenceId: wallet.driverId,
      driver: wallet.driver,
      type: 'Operator Wallet Adjustment',
      method: input.direction === 'credit' ? 'Operator Manual Credit' : 'Operator Manual Debit',
      amountCentavos: input.amountCentavos,
      direction: input.direction,
      status: 'Settled',
      timestamp: 'Just now',
    })

    appendAuditLog({
      action: 'WALLET_ADJUSTED',
      targetEntity: `${wallet.driverId} (${wallet.driver})`,
      severity: input.direction === 'debit' ? 'Warning' : 'Info',
      payload: {
        direction: input.direction,
        amountCentavos: input.amountCentavos,
        newBalanceCentavos: wallet.balanceCentavos,
        reason: trimmedReason,
      },
    })

    const verb = input.direction === 'credit' ? 'Credited' : 'Debited'
    return {
      ok: true,
      message: `${verb} ${formatCentavos(input.amountCentavos)} for ${wallet.driver}`,
    }
  }

  return {
    wallets: computed(() => wallets.value),
    minDispatchBalanceCentavos,
    minTopUpAmountCentavos,
    adjustDriverWallet,
  }
}

export function useCommissionTiers() {
  const { appendAuditLog } = useAuditLogs()

  const defaultStandardRateBps = computed(
    () => commissionTiers.value.find((tier) => tier.id === 'standard-fleet')?.rateBps ?? 1500,
  )

  function createCommissionTier(input: CreateCommissionTierInput): PaymentMutationResult {
    const validationError = validateCommissionTierInput(input)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const category = input.category.trim()
    const rateBps = Math.round(input.rateBps)
    const percentLabel = Number((rateBps / 100).toFixed(2))
    const slug = category
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
    const id = `${slug || 'tier'}-${commissionTiers.value.length + 1}`

    commissionTiers.value.push({
      id,
      category,
      rateBps,
      fixedBookingFeeCentavos: Math.round(input.fixedBookingFeeCentavos),
      minWalletBalanceCentavos: Math.round(input.minWalletBalanceCentavos),
      eligibilityRule: input.eligibilityRule.trim() || 'Assigned via driver tier policy.',
      settlementNote: `${percentLabel}% (${rateBps} bps) deducted from prepaid commission wallet upon trip completion.`,
      isActive: true,
    })

    appendAuditLog({
      action: 'COMMISSION_TIER_CREATED',
      targetEntity: `${id} (${category})`,
      severity: 'Info',
      payload: {
        rateBps,
        fixedBookingFeeCentavos: Math.round(input.fixedBookingFeeCentavos),
        minWalletBalanceCentavos: Math.round(input.minWalletBalanceCentavos),
      },
    })

    return {
      ok: true,
      message: `Created commission tier ${category} at ${percentLabel}% (${rateBps} bps)`,
    }
  }

  function saveCommissionTier(id: string, input: SaveCommissionTierInput): PaymentMutationResult {
    const validationError = validateCommissionTierInput(input)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const tier = commissionTiers.value.find((row) => row.id === id)
    if (!tier) {
      return { ok: false, error: `Commission tier ${id} was not found.` }
    }

    const rateBps = Math.round(input.rateBps)
    const percentLabel = Number((rateBps / 100).toFixed(2))
    tier.rateBps = rateBps
    tier.fixedBookingFeeCentavos = Math.round(input.fixedBookingFeeCentavos)
    tier.minWalletBalanceCentavos = Math.round(input.minWalletBalanceCentavos)
    tier.eligibilityRule = input.eligibilityRule.trim() || tier.eligibilityRule
    tier.settlementNote = `${percentLabel}% (${rateBps} bps) deducted from prepaid commission wallet upon trip completion.`

    appendAuditLog({
      action: 'COMMISSION_TIER_UPDATED',
      targetEntity: `${tier.id} (${tier.category})`,
      severity: 'Info',
      payload: {
        rateBps: tier.rateBps,
        fixedBookingFeeCentavos: tier.fixedBookingFeeCentavos,
        minWalletBalanceCentavos: tier.minWalletBalanceCentavos,
      },
    })

    return {
      ok: true,
      message: `Updated ${tier.category} to ${percentLabel}% (${tier.rateBps} bps)`,
    }
  }

  function toggleCommissionTierActive(id: string): PaymentMutationResult {
    const tier = commissionTiers.value.find((row) => row.id === id)
    if (!tier) {
      return { ok: false, error: `Commission tier ${id} was not found.` }
    }
    tier.isActive = !(tier.isActive ?? true)
    appendAuditLog({
      action: 'COMMISSION_TIER_TOGGLED',
      targetEntity: `${tier.id} (${tier.category})`,
      severity: 'Warning',
      payload: { isActive: tier.isActive },
    })
    return {
      ok: true,
      message: `${tier.category} marked ${tier.isActive ? 'Active' : 'Paused'}`,
    }
  }

  return {
    tiers: computed(() => commissionTiers.value),
    defaultStandardRateBps,
    createCommissionTier,
    saveCommissionTier,
    toggleCommissionTierActive,
  }
}

export function useFarePricing() {
  const { config } = usePlatformConfig()
  const { appendAuditLog } = useAuditLogs()

  function createFareRule(input: CreateFareTierRuleInput): PaymentMutationResult {
    const validationError = validateFareRuleInput(input, config.value.maxBiddingSurgeCap)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const tier = input.tier.trim()
    const slug = tier
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
    const id = `${slug || 'tariff'}-${fareRules.value.length + 1}`

    const created: FareTierRule = {
      id,
      tier,
      corridorScope: input.corridorScope.trim(),
      baseFareCentavos: Math.round(input.baseFareCentavos),
      perKmCentavos: Math.round(input.perKmCentavos),
      perMinuteCentavos: Math.round(input.perMinuteCentavos),
      minimumFareCentavos: Math.round(input.minimumFareCentavos),
      cancellationFeeCentavos: Math.round(input.cancellationFeeCentavos),
      maxBiddingSurgeCap: Number(input.maxBiddingSurgeCap.toFixed(2)),
      highRatingDriverBonus: Number(input.highRatingDriverBonus.toFixed(2)),
      isActive: true,
    }
    fareRules.value.push(created)

    appendAuditLog({
      action: 'TARIFF_MATRIX_CREATED',
      targetEntity: `${created.id} (${created.tier})`,
      severity: 'Info',
      payload: {
        baseFareCentavos: created.baseFareCentavos,
        perKmCentavos: created.perKmCentavos,
        maxBiddingSurgeCap: created.maxBiddingSurgeCap,
      },
    })

    return {
      ok: true,
      message: `Created tariff tier ${created.tier}`,
    }
  }

  function saveFareRule(updated: FareTierRule): PaymentMutationResult {
    const validationError = validateFareRuleInput(updated, config.value.maxBiddingSurgeCap)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const index = fareRules.value.findIndex((rule) => rule.id === updated.id)
    if (index === -1) {
      return { ok: false, error: `Fare rule ${updated.id} was not found.` }
    }

    fareRules.value[index] = {
      ...updated,
      tier: updated.tier.trim(),
      corridorScope: updated.corridorScope.trim(),
      baseFareCentavos: Math.round(updated.baseFareCentavos),
      perKmCentavos: Math.round(updated.perKmCentavos),
      perMinuteCentavos: Math.round(updated.perMinuteCentavos),
      minimumFareCentavos: Math.round(updated.minimumFareCentavos),
      cancellationFeeCentavos: Math.round(updated.cancellationFeeCentavos),
      maxBiddingSurgeCap: Number(updated.maxBiddingSurgeCap.toFixed(2)),
      highRatingDriverBonus: Number(updated.highRatingDriverBonus.toFixed(2)),
      isActive: updated.isActive ?? fareRules.value[index]?.isActive ?? true,
    }

    appendAuditLog({
      action: 'TARIFF_MATRIX_UPDATED',
      targetEntity: `${updated.id} (${updated.tier})`,
      severity: 'Info',
      payload: {
        baseFareCentavos: fareRules.value[index].baseFareCentavos,
        perKmCentavos: fareRules.value[index].perKmCentavos,
        maxBiddingSurgeCap: fareRules.value[index].maxBiddingSurgeCap,
        highRatingDriverBonus: fareRules.value[index].highRatingDriverBonus,
      },
    })

    return {
      ok: true,
      message: `Saved tariff updates for ${updated.tier.trim()}`,
    }
  }

  function toggleFareRuleActive(id: string): PaymentMutationResult {
    const target = fareRules.value.find((rule) => rule.id === id)
    if (!target) {
      return { ok: false, error: `Fare rule ${id} was not found.` }
    }
    target.isActive = !(target.isActive ?? true)
    appendAuditLog({
      action: 'TARIFF_MATRIX_TOGGLED',
      targetEntity: `${target.id} (${target.tier})`,
      severity: 'Warning',
      payload: { isActive: target.isActive },
    })
    return {
      ok: true,
      message: `${target.tier} marked ${target.isActive ? 'Active' : 'Paused'}`,
    }
  }

  return {
    rules: computed(() => fareRules.value),
    createFareRule,
    saveFareRule,
    toggleFareRuleActive,
  }
}

export function useDriverEarnings() {
  return {
    earnings: computed(() => earnings.value),
  }
}

export function useCollectionAccounts() {
  const { appendAuditLog } = useAuditLogs()

  function createAccount(input: CreateCompanyAccountInput): PaymentMutationResult {
    const validationError = validateCompanyAccountInput(input)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const id = `ACC-${Date.now()}`
    const trimmedMerchant = input.branchOrMerchantId.trim() || 'INSTAPAY-PAGADIAN'
    const newAccount: CompanyCollectionAccount = {
      id,
      label: input.label.trim(),
      channelType: input.channelType,
      institution: input.institution.trim(),
      accountNumber: input.accountNumber.trim(),
      accountHolder: input.accountHolder.trim(),
      branchOrMerchantId: trimmedMerchant,
      qrPreviewUrl:
        input.channelType === 'QRPh Wallet' ? buildQrSvg(trimmedMerchant, '#171717') : '',
      qrUpdatedAt: input.channelType === 'QRPh Wallet' ? 'Added just now' : 'Bank Transfer Only',
      isActive: true,
    }

    collectionAccounts.value.unshift(newAccount)

    appendAuditLog({
      action: 'COLLECTION_ACCOUNT_CREATED',
      targetEntity: `${newAccount.id} (${newAccount.label})`,
      severity: 'Info',
      payload: {
        channelType: newAccount.channelType,
        institution: newAccount.institution,
      },
    })

    return {
      ok: true,
      message: `Added ${newAccount.label} to active company collection channels`,
    }
  }

  function updateAccount(id: string, input: UpdateCompanyAccountInput): PaymentMutationResult {
    const validationError = validateCompanyAccountInput(input)
    if (validationError) {
      return { ok: false, error: validationError }
    }

    const account = collectionAccounts.value.find((row) => row.id === id)
    if (!account) {
      return { ok: false, error: `Collection account ${id} was not found.` }
    }

    account.label = input.label.trim()
    account.institution = input.institution.trim()
    account.accountNumber = input.accountNumber.trim()
    account.accountHolder = input.accountHolder.trim()
    account.branchOrMerchantId = input.branchOrMerchantId.trim() || account.branchOrMerchantId

    appendAuditLog({
      action: 'COLLECTION_ACCOUNT_UPDATED',
      targetEntity: `${account.id} (${account.label})`,
      severity: 'Info',
      payload: {
        institution: account.institution,
        branchOrMerchantId: account.branchOrMerchantId,
      },
    })

    return {
      ok: true,
      message: `Updated account details for ${account.label}`,
    }
  }

  function rotateQrCode(
    id: string,
    input: { branchOrMerchantId: string; previewDataUrl: string },
  ): PaymentMutationResult {
    const merchantError = validateMerchantReference(input.branchOrMerchantId)
    if (merchantError) {
      return { ok: false, error: merchantError }
    }

    const account = collectionAccounts.value.find((row) => row.id === id)
    if (!account) {
      return { ok: false, error: `Collection account ${id} was not found.` }
    }

    account.branchOrMerchantId = input.branchOrMerchantId.trim()
    account.qrPreviewUrl = input.previewDataUrl || buildQrSvg(account.branchOrMerchantId, '#171717')
    account.qrUpdatedAt = 'Updated just now'

    appendAuditLog({
      action: 'COLLECTION_QR_ROTATED',
      targetEntity: `${account.id} (${account.label})`,
      severity: 'Info',
      payload: {
        branchOrMerchantId: account.branchOrMerchantId,
      },
    })

    return {
      ok: true,
      message: `Updated QRPh collection image for ${account.label}`,
    }
  }

  function toggleAccountActive(id: string): PaymentMutationResult {
    const account = collectionAccounts.value.find((row) => row.id === id)
    if (!account) {
      return { ok: false, error: `Collection account ${id} was not found.` }
    }

    account.isActive = !account.isActive

    appendAuditLog({
      action: 'COLLECTION_ACCOUNT_TOGGLED',
      targetEntity: `${account.id} (${account.label})`,
      severity: 'Warning',
      payload: { isActive: account.isActive },
    })

    return {
      ok: true,
      message: `${account.label} marked ${account.isActive ? 'Active' : 'Inactive'}`,
    }
  }

  return {
    accounts: computed(() => collectionAccounts.value),
    createAccount,
    updateAccount,
    rotateQrCode,
    toggleAccountActive,
  }
}

export function useRefundClaims() {
  const { appendAuditLog } = useAuditLogs()

  function resolveClaim(
    id: string,
    decision: 'approve' | 'decline',
    note: string,
  ): PaymentMutationResult {
    const claim = refundClaims.value.find((row) => row.id === id)
    if (!claim) {
      return { ok: false, error: `Claim ${id} was not found.` }
    }

    if (claim.status !== 'Pending Approval') {
      return { ok: false, error: `Claim ${id} has already been resolved.` }
    }

    const trimmedNote = note.trim()
    if (!trimmedNote) {
      return { ok: false, error: 'Provide a mandatory audit note before resolving claim.' }
    }

    claim.status = decision === 'approve' ? 'Approved & Credited' : 'Declined'
    claim.resolutionNote = trimmedNote

    appendAuditLog({
      action: decision === 'approve' ? 'REFUND_CLAIM_APPROVED' : 'REFUND_CLAIM_DECLINED',
      targetEntity: `${claim.id} (${claim.tripId})`,
      severity: 'Warning',
      payload: {
        amountCentavos: claim.amountCentavos,
        claimType: claim.claimType,
        resolutionNote: trimmedNote,
      },
    })

    return {
      ok: true,
      message: `${claim.id} marked ${claim.status}`,
    }
  }

  return {
    claims: computed(() => refundClaims.value),
    resolveClaim,
  }
}
