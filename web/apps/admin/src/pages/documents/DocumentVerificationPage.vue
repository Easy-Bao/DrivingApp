<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

interface PendingDocument {
  id: string
  driver: string
  driverPhone: string
  docType: string
  issuedCountry: string
  expiryDate: string
  submittedAt: string
  docImageUrl: string
  status: 'Pending Review' | 'Approved' | 'Rejected'
}

const pendingDocs = ref<PendingDocument[]>([
  {
    id: 'DOC-901',
    driver: 'Brandon Lee',
    driverPhone: '+1 (555) 111-2233',
    docType: "Commercial Driver's License (Class B)",
    issuedCountry: 'USA',
    expiryDate: '2028-09-15',
    submittedAt: '3 hours ago',
    docImageUrl: 'CDL-Front-Scan-901.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-902',
    driver: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    docType: 'Comprehensive Motor Insurance Policy',
    issuedCountry: 'USA',
    expiryDate: '2027-04-12',
    submittedAt: '5 hours ago',
    docImageUrl: 'Insurance-Certificate-902.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-903',
    driver: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    docType: 'Annual Vehicle Inspection Certificate',
    issuedCountry: 'USA',
    expiryDate: '2027-11-01',
    submittedAt: '1 day ago',
    docImageUrl: 'Inspection-Cert-903.pdf',
    status: 'Pending Review',
  },
])

const selectedDoc = ref<PendingDocument | null>(null)
const actionToast = ref<string | null>(null)

function openReview(doc: PendingDocument) {
  selectedDoc.value = doc
}

function verifyDoc(decision: 'Approved' | 'Rejected') {
  if (!selectedDoc.value) return
  selectedDoc.value.status = decision
  actionToast.value = `Document ${selectedDoc.value.id} for ${selectedDoc.value.driver} marked as ${decision}.`
  selectedDoc.value = null
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Driver Document Verification Queue
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review official driver licenses, commercial vehicle insurance, and regulatory background
          files.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 rounded-lg bg-blue-50 border border-blue-200 text-xs font-semibold text-blue-800"
        >
          12 Pending Verifications
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Compliance Verification Queue</h2>
        <span class="text-xs text-neutral-400">Strict regulatory compliance mode enabled</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Document ID</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Document Type</th>
            <th class="py-3 px-4">Expiry Date</th>
            <th class="py-3 px-4">Submitted</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="doc in pendingDocs"
            :key="doc.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ doc.driverPhone }}</div>
            </td>
            <td class="py-3 px-4 font-medium text-neutral-800">{{ doc.docType }}</td>
            <td class="py-3 px-4 font-mono">{{ doc.expiryDate }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ doc.submittedAt }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  doc.status === 'Approved'
                    ? 'bg-emerald-100 text-emerald-800'
                    : doc.status === 'Rejected'
                      ? 'bg-rose-100 text-rose-800'
                      : 'bg-blue-100 text-blue-800'
                "
              >
                {{ doc.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors"
                @click="openReview(doc)"
              >
                Review Document
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Review Modal -->
    <div
      v-if="selectedDoc"
      class="fixed inset-0 z-50 bg-neutral-900/40 backdrop-blur-xs flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-neutral-200">
        <div class="flex items-center justify-between pb-4 border-b border-neutral-100">
          <div>
            <h3 class="font-bold text-base text-neutral-900">Audit Document Submission</h3>
            <span class="text-xs text-neutral-400 font-mono">{{ selectedDoc.id }}</span>
          </div>
          <button
            type="button"
            class="text-neutral-400 hover:text-neutral-900 p-1"
            @click="selectedDoc = null"
          >
            <Icon icon="lucide:x" class="text-lg" />
          </button>
        </div>

        <div class="py-4 space-y-3 text-xs">
          <div class="flex justify-between py-1.5 border-b border-neutral-50">
            <span class="text-neutral-500">Driver</span>
            <span class="font-semibold text-neutral-900">{{ selectedDoc.driver }}</span>
          </div>
          <div class="flex justify-between py-1.5 border-b border-neutral-50">
            <span class="text-neutral-500">Document Type</span>
            <span class="font-semibold text-neutral-900">{{ selectedDoc.docType }}</span>
          </div>
          <div class="flex justify-between py-1.5 border-b border-neutral-50">
            <span class="text-neutral-500">Declared Expiration</span>
            <span class="font-mono font-semibold text-neutral-900">{{
              selectedDoc.expiryDate
            }}</span>
          </div>
          <div class="p-4 bg-neutral-50 rounded-xl border border-neutral-200 text-center">
            <Icon icon="lucide:file-text" class="text-3xl text-neutral-400 mx-auto mb-2" />
            <div class="font-medium text-neutral-800">{{ selectedDoc.docImageUrl }}</div>
            <div class="text-[11px] text-neutral-400 mt-1">
              High-resolution scan attached by driver
            </div>
          </div>
        </div>

        <div class="flex items-center justify-end space-x-3 pt-4 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 rounded-lg text-xs font-semibold transition-colors"
            @click="verifyDoc('Rejected')"
          >
            Reject Document
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors"
            @click="verifyDoc('Approved')"
          >
            Approve & Validate
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
