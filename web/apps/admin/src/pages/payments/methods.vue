<script setup lang="ts">
import { computed, ref } from 'vue'
import { BaseSelect, ModalDialog, PageHeader, StatusBadge, ToastBanner } from '@/shared'
import type { ToastTone } from '@/shared'
import { buildQrSvg, useCollectionAccounts, validateQrUploadFile } from '@/features/payments'
import type { ChannelKind, CompanyCollectionAccount } from '@/features/payments'

const { accounts, createAccount, updateAccount, rotateQrCode, toggleAccountActive } =
  useCollectionAccounts()

const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')
const modalError = ref<string | null>(null)

const showAddModal = ref(false)
const newLabel = ref('')
const newChannelType = ref<ChannelKind>('QRPh Wallet')
const newInstitution = ref('')
const newAccountNumber = ref('')
const newAccountHolder = ref('EasyRide Mobility Services ZDS Corp.')
const newBranchOrMerchantId = ref('')

const showEditModal = ref(false)
const editAccountId = ref('')
const editLabel = ref('')
const editInstitution = ref('')
const editAccountNumber = ref('')
const editAccountHolder = ref('')
const editBranchOrMerchantId = ref('')

const showQrModal = ref(false)
const qrTargetId = ref('')
const qrTargetLabel = ref('')
const qrMerchantReference = ref('')
const qrPreviewDraftUrl = ref('')
const qrUploadFileName = ref('')

const activeChannelCount = computed(
  () => accounts.value.filter((account) => account.isActive).length,
)

function showToast(message: string, tone: ToastTone = 'success') {
  toastMessage.value = message
  toastTone.value = tone
}

function openAddModal() {
  newLabel.value = ''
  newChannelType.value = 'QRPh Wallet'
  newInstitution.value = ''
  newAccountNumber.value = ''
  newAccountHolder.value = 'EasyRide Mobility Services ZDS Corp.'
  newBranchOrMerchantId.value = ''
  modalError.value = null
  showAddModal.value = true
}

function submitNewAccount() {
  const result = createAccount({
    label: newLabel.value,
    channelType: newChannelType.value,
    institution: newInstitution.value,
    accountNumber: newAccountNumber.value,
    accountHolder: newAccountHolder.value,
    branchOrMerchantId: newBranchOrMerchantId.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  showAddModal.value = false
  showToast(result.message ?? 'Added collection channel')
}

function openEditModal(account: CompanyCollectionAccount) {
  editAccountId.value = account.id
  editLabel.value = account.label
  editInstitution.value = account.institution
  editAccountNumber.value = account.accountNumber
  editAccountHolder.value = account.accountHolder
  editBranchOrMerchantId.value = account.branchOrMerchantId
  modalError.value = null
  showEditModal.value = true
}

function submitAccountEdit() {
  const result = updateAccount(editAccountId.value, {
    label: editLabel.value,
    institution: editInstitution.value,
    accountNumber: editAccountNumber.value,
    accountHolder: editAccountHolder.value,
    branchOrMerchantId: editBranchOrMerchantId.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  showEditModal.value = false
  showToast(result.message ?? 'Updated account details')
}

function openUpdateQrModal(account: CompanyCollectionAccount) {
  qrTargetId.value = account.id
  qrTargetLabel.value = account.label
  qrMerchantReference.value = account.branchOrMerchantId
  qrPreviewDraftUrl.value =
    account.qrPreviewUrl || buildQrSvg(account.branchOrMerchantId, '#171717')
  qrUploadFileName.value = ''
  modalError.value = null
  showQrModal.value = true
}

function regenerateQrPreview() {
  const code = qrMerchantReference.value.trim() || 'QRPH-PAGADIAN'
  qrPreviewDraftUrl.value = buildQrSvg(code, '#171717')
}

function handleQrFileUpload(event: Event) {
  const input = event.target as HTMLInputElement | null
  const file = input?.files?.[0]
  if (!file) return

  const validationError = validateQrUploadFile(file)
  if (validationError) {
    modalError.value = validationError
    qrUploadFileName.value = ''
    if (input) input.value = ''
    return
  }

  modalError.value = null
  qrUploadFileName.value = file.name
  const reader = new FileReader()
  reader.onload = () => {
    if (typeof reader.result === 'string') {
      qrPreviewDraftUrl.value = reader.result
    }
  }
  reader.readAsDataURL(file)
}

function publishQrUpdate() {
  const result = rotateQrCode(qrTargetId.value, {
    branchOrMerchantId: qrMerchantReference.value,
    previewDataUrl: qrPreviewDraftUrl.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  showQrModal.value = false
  showToast(result.message ?? 'Updated QRPh collection image')
}

function toggleAccountStatus(account: CompanyCollectionAccount) {
  const result = toggleAccountActive(account.id)
  if (result.ok) {
    showToast(result.message ?? 'Updated channel status', 'info')
  }
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <PageHeader
      title="Company Payment Channels"
      description="Manage verified QRPh merchant codes and corporate bank depository accounts used for driver wallet top-ups."
    >
      <template #actions>
        <div class="flex items-center gap-3">
          <span class="text-xs font-mono text-neutral-500">
            {{ activeChannelCount }} Active / {{ accounts.length }} Total
          </span>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="openAddModal"
          >
            + Add Company Account
          </button>
        </div>
      </template>
    </PageHeader>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
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
              class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50 cursor-pointer"
              @click="openEditModal(account)"
            >
              Edit Account Info
            </button>
            <button
              v-if="account.channelType === 'QRPh Wallet'"
              type="button"
              class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50 cursor-pointer"
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
          <label class="block font-medium text-neutral-700 mb-1">Financial Institution</label>
          <input
            v-model="newInstitution"
            type="text"
            placeholder="e.g., Land Bank of the Philippines"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Account / Mobile Number</label>
            <input
              v-model="newAccountNumber"
              type="text"
              placeholder="e.g., +63 917 701 6005"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Merchant / Branch Code</label>
            <input
              v-model="newBranchOrMerchantId"
              type="text"
              placeholder="e.g., QRPH-PAG-8805"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Beneficiary Account Holder</label>
          <input
            v-model="newAccountHolder"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <p v-if="modalError" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="showAddModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="submitNewAccount"
          >
            Save Collection Account
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      v-model:open="showEditModal"
      :title="`Edit Account Info · ${editLabel}`"
      subtitle="Update institutional account numbers or beneficiary details visible inside the driver app."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Display Account Label</label>
          <input
            v-model="editLabel"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Financial Institution</label>
          <input
            v-model="editInstitution"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Account / Wallet Number</label>
            <input
              v-model="editAccountNumber"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Merchant / Branch Ref</label>
            <input
              v-model="editBranchOrMerchantId"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Beneficiary Account Holder</label>
          <input
            v-model="editAccountHolder"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <p v-if="modalError" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="showEditModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="submitAccountEdit"
          >
            Update Account Details
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      v-model:open="showQrModal"
      :title="`Update QR Code Image · ${qrTargetLabel}`"
      subtitle="Upload a verified PNG, JPEG, WebP, or SVG merchant QR code or regenerate preview from merchant ID."
      size="md"
    >
      <div class="space-y-4 text-xs">
        <div class="flex items-center gap-4">
          <img
            :src="qrPreviewDraftUrl"
            :alt="`Preview QR for ${qrTargetLabel}`"
            class="w-24 h-24 object-contain border border-neutral-200 bg-white shrink-0"
          />
          <div class="space-y-2 flex-1">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">QRPh Merchant Reference</label>
              <div class="flex gap-2">
                <input
                  v-model="qrMerchantReference"
                  aria-label="QRPh Merchant Reference"
                  type="text"
                  class="flex-1 px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
                />
                <button
                  type="button"
                  class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 font-medium hover:bg-neutral-50 cursor-pointer"
                  @click="regenerateQrPreview"
                >
                  Regenerate Preview
                </button>
              </div>
            </div>

            <div>
              <label class="block font-medium text-neutral-700 mb-1">Upload QR Image File</label>
              <input
                type="file"
                aria-label="Upload QR code image"
                accept="image/png,image/jpeg,image/webp,image/svg+xml"
                class="block w-full text-xs text-neutral-600"
                @change="handleQrFileUpload"
              />
              <span v-if="qrUploadFileName" class="text-[11px] font-mono text-neutral-500">
                Selected: {{ qrUploadFileName }}
              </span>
            </div>
          </div>
        </div>

        <p v-if="modalError" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="showQrModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="publishQrUpdate"
          >
            Publish Updated QR Code
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
