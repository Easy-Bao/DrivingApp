<script setup lang="ts">
import { ref } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

interface MunicipalityMarket {
  id: string
  municipality: string
  province: string
  zipCode: string
  centerCoords: string
  minFarePhp: number
  requireTodaMtop: boolean
  status: 'Active Launch Market' | 'Pilot Rollout' | 'Planned Expansion'
}

const cities = ref<MunicipalityMarket[]>([
  {
    id: 'MKT-ZDS-7016',
    municipality: 'Pagadian City',
    province: 'Zamboanga del Sur',
    zipCode: '7016',
    centerCoords: '7.8257° N, 123.4370° E',
    minFarePhp: 25.0,
    requireTodaMtop: true,
    status: 'Active Launch Market',
  },
  {
    id: 'MKT-ZDS-7017',
    municipality: 'Labangan',
    province: 'Zamboanga del Sur',
    zipCode: '7017',
    centerCoords: '7.8594° N, 123.5042° E',
    minFarePhp: 30.0,
    requireTodaMtop: true,
    status: 'Pilot Rollout',
  },
  {
    id: 'MKT-ZDS-7019',
    municipality: 'Tukuran',
    province: 'Zamboanga del Sur',
    zipCode: '7019',
    centerCoords: '7.8492° N, 123.5880° E',
    minFarePhp: 35.0,
    requireTodaMtop: true,
    status: 'Planned Expansion',
  },
  {
    id: 'MKT-ZDS-7015',
    municipality: 'Dumalinao',
    province: 'Zamboanga del Sur',
    zipCode: '7015',
    centerCoords: '7.8130° N, 123.3680° E',
    minFarePhp: 30.0,
    requireTodaMtop: true,
    status: 'Planned Expansion',
  },
])

const toastMessage = ref<string | null>(null)
const showModal = ref(false)
const editingMarketId = ref<string | null>(null)
const draftName = ref('')
const draftZip = ref('')
const draftMinFare = ref(25)
const draftRequireToda = ref(true)
const draftStatus = ref<MunicipalityMarket['status']>('Pilot Rollout')
const modalError = ref<string | null>(null)

const openCreateModal = () => {
  editingMarketId.value = null
  draftName.value = ''
  draftZip.value = '70'
  draftMinFare.value = 30
  draftRequireToda.value = true
  draftStatus.value = 'Planned Expansion'
  modalError.value = null
  showModal.value = true
}

const openEditModal = (city: MunicipalityMarket) => {
  editingMarketId.value = city.id
  draftName.value = city.municipality
  draftZip.value = city.zipCode
  draftMinFare.value = city.minFarePhp
  draftRequireToda.value = city.requireTodaMtop
  draftStatus.value = city.status
  modalError.value = null
  showModal.value = true
}

const saveMunicipality = () => {
  if (!draftName.value.trim() || !draftZip.value.trim()) {
    modalError.value = 'Enter municipality name and Philippine postal code.'
    return
  }
  if (editingMarketId.value) {
    const existing = cities.value.find((city) => city.id === editingMarketId.value)
    if (existing) {
      existing.municipality = draftName.value.trim()
      existing.zipCode = draftZip.value.trim()
      existing.minFarePhp = draftMinFare.value
      existing.requireTodaMtop = draftRequireToda.value
      existing.status = draftStatus.value
      toastMessage.value = `Updated municipal market rules for ${existing.municipality}.`
    }
  } else {
    const code = `MKT-ZDS-${draftZip.value.trim()}`
    cities.value.push({
      id: code,
      municipality: draftName.value.trim(),
      province: 'Zamboanga del Sur',
      zipCode: draftZip.value.trim(),
      centerCoords: '7.83° N, 123.44° E',
      minFarePhp: draftMinFare.value,
      requireTodaMtop: draftRequireToda.value,
      status: draftStatus.value,
    })
    toastMessage.value = `Registered regional municipality ${draftName.value.trim()} (${code}).`
  }
  showModal.value = false
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
      title="Cities"
      description="Manage launch status, franchise gates, and baseline minimum fares."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <span class="text-xs font-medium text-neutral-500 tabular-nums">
          {{ cities.length }} Municipalities
        </span>
        <button
          type="button"
          class="self-start sm:self-auto px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateModal"
        >
          + Add Municipality
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="min-w-[800px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Market Code</th>
              <th class="py-3 px-4">City / Municipality</th>
              <th class="py-3 px-4">ZIP &amp; Coordinates</th>
              <th class="py-3 px-4">Min Fare</th>
              <th class="py-3 px-4">TODA Charter Gate</th>
              <th class="py-3 px-4">Launch State</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="city in cities"
              :key="city.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900">{{ city.id }}</td>
              <td class="py-3.5 px-4">
                <div class="font-bold text-neutral-900">{{ city.municipality }}</div>
                <div class="text-[11px] text-neutral-500">{{ city.province }}</div>
              </td>
              <td class="py-3.5 px-4 font-mono text-[11px] text-neutral-600">
                ZIP {{ city.zipCode }} · {{ city.centerCoords }}
              </td>
              <td class="py-3.5 px-4 font-mono font-semibold text-neutral-900">
                {{ formatPhp(city.minFarePhp) }}
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="city.requireTodaMtop ? 'MTOP Required' : 'Open Dispatch'"
                  :tone="city.requireTodaMtop ? 'info' : 'neutral'"
                />
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="city.status"
                  :tone="
                    city.status === 'Active Launch Market'
                      ? 'success'
                      : city.status === 'Pilot Rollout'
                        ? 'warning'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3.5 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                  @click="openEditModal(city)"
                >
                  Configure Market
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      v-model:open="showModal"
      :title="
        editingMarketId
          ? `Configure Municipality · ${editingMarketId}`
          : 'Add Zamboanga del Sur Municipality'
      "
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div class="sm:col-span-2">
            <label class="block font-medium text-neutral-700 mb-1">Municipality Name</label>
            <input
              v-model="draftName"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">ZIP Code</label>
            <input
              v-model="draftZip"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
          </div>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Min Base Fare (PHP)</label>
          <input
            v-model.number="draftMinFare"
            type="number"
            min="15"
            step="5"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Launch State</label>
          <BaseSelect
            v-model="draftStatus"
            :full-width="true"
            aria-label="Municipality launch state"
            :options="['Active Launch Market', 'Pilot Rollout', 'Planned Expansion']"
          />
        </div>

        <label class="inline-flex items-center gap-2 cursor-pointer font-medium text-neutral-800">
          <input
            v-model="draftRequireToda"
            type="checkbox"
            class="h-4 w-4 accent-neutral-900 rounded-none"
          />
          Require verified municipal TODA MTOP franchise certificate
        </label>

        <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="showModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="saveMunicipality"
          >
            Save Municipality
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
