<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

type ChannelKind = 'QRPh Wallet' | 'Corporate Bank'

interface CompanyCollectionAccount {
  id: string
  label: string
  channelType: ChannelKind
  institution: string
  accountNumber: string
  accountHolder: string
  branchOrMerchantId: string
  qrPreviewUrl: string
  qrUpdatedAt: string
  isActive: boolean
}

const buildQrSvg = (merchantCode: string, accentHex: string) => {
  const safeCode = merchantCode.replace(/[<>&"']/g, '')
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" viewBox="0 0 180 180">
  <rect width="180" height="180" fill="#ffffff"/>
  <rect x="8" y="8" width="164" height="164" fill="#ffffff" stroke="#e5e5e5" stroke-width="2"/>
  <rect x="20" y="20" width="38" height="38" fill="none" stroke="${accentHex}" stroke-width="6"/>
  <rect x="31" y="31" width="16" height="16" fill="#171717"/>
  <rect x="122" y="20" width="38" height="38" fill="none" stroke="${accentHex}" stroke-width="6"/>
  <rect x="133" y="31" width="16" height="16" fill="#171717"/>
  <rect x="20" y="122" width="38" height="38" fill="none" stroke="${accentHex}" stroke-width="6"/>
  <rect x="31" y="133" width="16" height="16" fill="#171717"/>
  <rect x="74" y="24" width="10" height="10" fill="#171717"/>
  <rect x="92" y="24" width="14" height="10" fill="${accentHex}"/>
  <rect x="74" y="42" width="30" height="10" fill="#171717"/>
  <rect x="24" y="74" width="14" height="12" fill="#171717"/>
  <rect x="46" y="74" width="18" height="12" fill="${accentHex}"/>
  <rect x="74" y="74" width="32" height="32" fill="#171717"/>
  <rect x="82" y="82" width="16" height="16" fill="#ffffff"/>
  <rect x="116" y="74" width="16" height="12" fill="#171717"/>
  <rect x="140" y="74" width="16" height="12" fill="${accentHex}"/>
  <rect x="74" y="120" width="22" height="12" fill="${accentHex}"/>
  <rect x="106" y="120" width="20" height="12" fill="#171717"/>
  <rect x="136" y="120" width="18" height="26" fill="#171717"/>
  <rect x="74" y="140" width="44" height="12" fill="#171717"/>
  <text x="90" y="168" font-family="monospace" font-size="9" font-weight="bold" fill="#171717" text-anchor="middle">${safeCode}</text>
</svg>`
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`
}

const accounts = ref<CompanyCollectionAccount[]>([
  {
    id: 'ACC-QR-GCASH',
    label: 'GCash QRPh · Pagadian Dispatch Treasury',
    channelType: 'QRPh Wallet',
    institution: 'GCash Business (QRPh)',
    accountNumber: '+63 917 701 6001',
    accountHolder: 'EasyRide Mobility Services ZDS Corp.',
    branchOrMerchantId: 'QRPH-PAG-8801',
    qrPreviewUrl: buildQrSvg('QRPH-PAG-8801', '#007dfe'),
    qrUpdatedAt: 'Updated Nov 01, 2026',
    isActive: true,
  },
  {
    id: 'ACC-QR-MAYA',
    label: 'Maya QRPh · Instant Fleet Wallet',
    channelType: 'QRPh Wallet',
    institution: 'Maya Philippines (QRPh)',
    accountNumber: '+63 928 701 6002',
    accountHolder: 'EasyRide Mobility Services ZDS Corp.',
    branchOrMerchantId: 'MAYA-PAG-8802',
    qrPreviewUrl: buildQrSvg('MAYA-PAG-8802', '#059669'),
    qrUpdatedAt: 'Updated Nov 04, 2026',
    isActive: true,
  },
  {
    id: 'ACC-BANK-BDO',
    label: 'BDO Unibank · Pagadian Rizal Ave Branch',
    channelType: 'Corporate Bank',
    institution: 'BDO Unibank Inc.',
    accountNumber: '0074-8029-4410',
    accountHolder: 'EasyRide Mobility Services ZDS Corp.',
    branchOrMerchantId: 'InstaPay / PESONet · Brgy. Santiago',
    qrPreviewUrl: '',
    qrUpdatedAt: 'Bank Transfer Only',
    isActive: true,
  },
  {
    id: 'ACC-BANK-BPI',
    label: 'BPI · Pagadian Pajares Corporate Settlement',
    channelType: 'Corporate Bank',
    institution: 'Bank of the Philippine Islands',
    accountNumber: '8491-0023-77',
    accountHolder: 'EasyRide Mobility Services ZDS Corp.',
    branchOrMerchantId: 'InstaPay Enabled · Pagadian (7016)',
    qrPreviewUrl: '',
    qrUpdatedAt: 'Standby Channel',
    isActive: false,
  },
])

const toastMessage = ref<string | null>(null)

const showAddModal = ref(false)
const newLabel = ref('')
const newChannelType = ref<ChannelKind>('QRPh Wallet')
const newInstitution = ref('')
const newAccountNumber = ref('')
const newAccountHolder = ref('EasyRide Mobility Services ZDS Corp.')
const newBranchOrMerchantId = ref('')
const addError = ref<string | null>(null)

const editingAccount = ref<CompanyCollectionAccount | null>(null)
const editLabel = ref('')
const editInstitution = ref('')
const editAccountNumber = ref('')
const editAccountHolder = ref('')
const editBranchOrMerchantId = ref('')
const editError = ref<string | null>(null)

const updatingQrAccount = ref<CompanyCollectionAccount | null>(null)
const draftMerchantRef = ref('')
const draftQrImageUrl = ref('')
const draftQrFileName = ref('')
const qrModalError = ref<string | null>(null)

const activeCount = computed(() => accounts.value.filter((a) => a.isActive).length)

const openAddModal = () => {
  newLabel.value = ''
  newChannelType.value = 'QRPh Wallet'
  newInstitution.value = ''
  newAccountNumber.value = ''
  newAccountHolder.value = 'EasyRide Mobility Services ZDS Corp.'
  newBranchOrMerchantId.value = ''
  addError.value = null
  showAddModal.value = true
}

const createCompanyAccount = () => {
  if (
    !newLabel.value.trim() ||
    !newInstitution.value.trim() ||
    !newAccountNumber.value.trim() ||
    !newAccountHolder.value.trim()
  ) {
    addError.value = 'Fill in account label, institution, account number, and holder name.'
    return
  }
  const code = newBranchOrMerchantId.value.trim() || `PAG-${accounts.value.length + 8801}`
  const isQr = newChannelType.value === 'QRPh Wallet'
  accounts.value.unshift({
    id: `ACC-${Date.now().toString().slice(-4)}`,
    label: newLabel.value.trim(),
    channelType: newChannelType.value,
    institution: newInstitution.value.trim(),
    accountNumber: newAccountNumber.value.trim(),
    accountHolder: newAccountHolder.value.trim(),
    branchOrMerchantId: code,
    qrPreviewUrl: isQr ? buildQrSvg(code, '#171717') : '',
    qrUpdatedAt: isQr ? 'Uploaded Just Now' : 'Bank Transfer Only',
    isActive: true,
  })
  toastMessage.value = `Added company collection account: ${newLabel.value.trim()}.`
  showAddModal.value = false
}

const openEditModal = (account: CompanyCollectionAccount) => {
  editingAccount.value = account
  editLabel.value = account.label
  editInstitution.value = account.institution
  editAccountNumber.value = account.accountNumber
  editAccountHolder.value = account.accountHolder
  editBranchOrMerchantId.value = account.branchOrMerchantId
  editError.value = null
}

const saveEditedAccount = () => {
  if (!editingAccount.value) return
  if (!editLabel.value.trim() || !editInstitution.value.trim() || !editAccountNumber.value.trim()) {
    editError.value = 'Account label, institution, and account number are required.'
    return
  }
  editingAccount.value.label = editLabel.value.trim()
  editingAccount.value.institution = editInstitution.value.trim()
  editingAccount.value.accountNumber = editAccountNumber.value.trim()
  editingAccount.value.accountHolder = editAccountHolder.value.trim()
  editingAccount.value.branchOrMerchantId = editBranchOrMerchantId.value.trim()
  toastMessage.value = `Updated account details for ${editingAccount.value.label}.`
  editingAccount.value = null
}

const openUpdateQrModal = (account: CompanyCollectionAccount) => {
  updatingQrAccount.value = account
  draftMerchantRef.value = account.branchOrMerchantId
  draftQrImageUrl.value = account.qrPreviewUrl || buildQrSvg(account.branchOrMerchantId, '#171717')
  draftQrFileName.value = ''
  qrModalError.value = null
}

const onQrFileSelected = (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  draftQrFileName.value = file.name
  if (typeof FileReader !== 'undefined') {
    const reader = new FileReader()
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        draftQrImageUrl.value = reader.result
      }
    }
    reader.readAsDataURL(file)
  }
}

const regenerateMerchantQr = () => {
  const refCode = draftMerchantRef.value.trim()
  if (!refCode) {
    qrModalError.value = 'Enter a QRPh Merchant Reference before regenerating preview.'
    return
  }
  qrModalError.value = null
  draftQrFileName.value = `${refCode.toLowerCase()}_qrph.svg`
  draftQrImageUrl.value = buildQrSvg(refCode, '#059669')
}

const saveUpdatedQrCode = () => {
  if (!updatingQrAccount.value) return
  if (!draftMerchantRef.value.trim()) {
    qrModalError.value = 'Merchant reference identifier is required.'
    return
  }
  updatingQrAccount.value.branchOrMerchantId = draftMerchantRef.value.trim()
  updatingQrAccount.value.qrPreviewUrl =
    draftQrImageUrl.value || buildQrSvg(draftMerchantRef.value.trim(), '#059669')
  updatingQrAccount.value.qrUpdatedAt = 'Rotated Just Now'
  toastMessage.value = `Updated QRPh collection image for ${updatingQrAccount.value.label} (${draftMerchantRef.value.trim()}).`
  updatingQrAccount.value = null
}

const toggleAccountStatus = (account: CompanyCollectionAccount) => {
  account.isActive = !account.isActive
  toastMessage.value = `${account.label} is now ${account.isActive ? 'Active for Driver Top-Ups' : 'Paused'}.`
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

    <PageHeader
      title="Channels"
      description="Manage QRPh codes and bank accounts for driver top-ups."
    >
      <template #actions>
        <StatusBadge :label="`${activeCount} Active Channels`" tone="neutral" />
        <button
          type="button"
          class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold rounded-none transition-colors"
          @click="openAddModal"
        >
          + Add Company Account
        </button>
      </template>
    </PageHeader>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-5">
      <div
        v-for="account in accounts"
        :key="account.id"
        class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4"
      >
        <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div class="space-y-2 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="font-bold text-sm text-neutral-900">{{ account.label }}</h3>
              <StatusBadge
                :label="account.isActive ? 'Active' : 'Paused'"
                :tone="account.isActive ? 'success' : 'neutral'"
              />
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              <div>
                <span class="text-neutral-400 block">Institution / Rail</span>
                <span class="font-medium text-neutral-800">{{ account.institution }}</span>
              </div>
              <div>
                <span class="text-neutral-400 block">Account / Wallet Number</span>
                <span class="font-mono font-semibold text-neutral-900">
                  {{ account.accountNumber }}
                </span>
              </div>
              <div>
                <span class="text-neutral-400 block">Beneficiary Account Name</span>
                <span class="font-medium text-neutral-800">{{ account.accountHolder }}</span>
              </div>
              <div>
                <span class="text-neutral-400 block">Merchant Ref / Branch</span>
                <span class="font-mono text-neutral-700">{{ account.branchOrMerchantId }}</span>
              </div>
            </div>
          </div>

          <div
            v-if="account.channelType === 'QRPh Wallet' && account.qrPreviewUrl"
            class="shrink-0 flex flex-col items-center border border-neutral-200 bg-neutral-50 p-2"
          >
            <img
              :src="account.qrPreviewUrl"
              :alt="`${account.label} QR code`"
              class="w-24 h-24 object-contain bg-white border border-neutral-200"
            />
            <span class="text-[10px] font-mono text-neutral-500 mt-1">
              {{ account.qrUpdatedAt }}
            </span>
          </div>
        </div>

        <div
          class="flex flex-wrap items-center justify-between gap-2 border-t border-neutral-100 pt-3"
        >
          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
              @click="openEditModal(account)"
            >
              Edit Account Info
            </button>
            <button
              v-if="account.channelType === 'QRPh Wallet'"
              type="button"
              class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
              @click="openUpdateQrModal(account)"
            >
              Update QR Code Image
            </button>
          </div>

          <button
            type="button"
            class="px-3 py-1.5 text-xs font-medium rounded-none border border-neutral-300 bg-white text-neutral-800 hover:bg-neutral-50 transition-colors cursor-pointer"
            @click="toggleAccountStatus(account)"
          >
            {{ account.isActive ? 'Pause Channel' : 'Activate Channel' }}
          </button>
        </div>
      </div>
    </div>

    <ModalDialog
      v-model:open="showAddModal"
      title="Add Company Collection Account"
      subtitle="Publish a verified QRPh merchant wallet or Pagadian corporate bank account for driver top-ups."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Display Account Label</label>
          <input
            v-model="newLabel"
            type="text"
            placeholder="e.g., Landbank Pagadian Operations"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Deposit Channel Type</label>
          <BaseSelect
            v-model="newChannelType"
            :full-width="true"
            aria-label="Deposit channel type"
            :options="[
              { label: 'QRPh Wallet (GCash / Maya)', value: 'QRPh Wallet' },
              { label: 'Corporate Bank (InstaPay / PESONet)', value: 'Corporate Bank' },
            ]"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1"> Institution / Bank Name </label>
          <input
            v-model="newInstitution"
            type="text"
            placeholder="e.g., Land Bank of the Philippines"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1"> Account or Mobile Number </label>
          <input
            v-model="newAccountNumber"
            type="text"
            placeholder="e.g., +63 917 ... or 0912-3456-78"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Account Holder Name</label>
          <input
            v-model="newAccountHolder"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">
            Merchant Ref / Branch Location
          </label>
          <input
            v-model="newBranchOrMerchantId"
            type="text"
            placeholder="e.g., QRPH-PAG-8805 or Brgy. Santiago"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>

        <p v-if="addError" class="text-xs font-medium text-rose-700">{{ addError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="showAddModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="createCompanyAccount"
          >
            Save Collection Account
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      :open="Boolean(editingAccount)"
      :title="editingAccount ? `Edit Account Info · ${editingAccount.id}` : ''"
      size="md"
      @update:open="(open) => !open && (editingAccount = null)"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Display Label</label>
          <input
            v-model="editLabel"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Institution</label>
          <input
            v-model="editInstitution"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Account / Wallet Number</label>
          <input
            v-model="editAccountNumber"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Beneficiary Holder</label>
          <input
            v-model="editAccountHolder"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Merchant Ref / Branch</label>
          <input
            v-model="editBranchOrMerchantId"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <p v-if="editError" class="text-xs font-medium text-rose-700">{{ editError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="editingAccount = null"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="saveEditedAccount"
          >
            Update Account Details
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      :open="Boolean(updatingQrAccount)"
      :title="updatingQrAccount ? `Update QR Code Image · ${updatingQrAccount.label}` : ''"
      subtitle="Upload a new official QRPh graphic or regenerate the signed merchant code preview."
      size="md"
      @update:open="(open) => !open && (updatingQrAccount = null)"
    >
      <div
        class="flex flex-col items-center gap-3 bg-neutral-50 border border-neutral-200 p-4 mb-3"
      >
        <img
          :src="draftQrImageUrl"
          alt="Updated QRPh preview"
          class="w-36 h-36 object-contain bg-white border border-neutral-300"
        />
        <span v-if="draftQrFileName" class="text-[11px] font-mono text-neutral-600">
          Selected: {{ draftQrFileName }}
        </span>
      </div>

      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">
            QRPh Merchant Code / Reference
          </label>
          <div class="flex flex-col sm:flex-row gap-2">
            <input
              v-model="draftMerchantRef"
              type="text"
              aria-label="QRPh Merchant Reference"
              class="flex-1 px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-800 hover:bg-neutral-50 shrink-0"
              @click="regenerateMerchantQr"
            >
              Regenerate Preview
            </button>
          </div>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">
            Upload Replacement QR Image
          </label>
          <input
            type="file"
            accept="image/*"
            class="w-full text-xs text-neutral-600 file:mr-3 file:py-1.5 file:px-3 file:border file:border-neutral-300 file:bg-white file:text-xs file:font-medium file:text-neutral-800"
            @change="onQrFileSelected"
          />
        </div>

        <p v-if="qrModalError" class="text-xs font-medium text-rose-700">{{ qrModalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="updatingQrAccount = null"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="saveUpdatedQrCode"
          >
            Publish Updated QR Code
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
