<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  usePlatformConfig,
  useServiceZones,
  type ServiceZone,
  type ServiceZoneStatus,
} from '@/features/settings'
import {
  BaseSelect,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  ToastBanner,
} from '@/shared'

const { config } = usePlatformConfig()
const { zones, saveServiceZone } = useServiceZones()

const searchQuery = ref('')
const toastMessage = ref<string | null>(null)

const showModal = ref(false)
const editingZoneId = ref<string | null>(null)
const draftName = ref('')
const draftBarangays = ref('')
const draftCoords = ref('7.8257° N, 123.4370° E')
const draftSurge = ref(1.0)
const draftPoints = ref(12)
const draftStatus = ref<ServiceZoneStatus>('Active')
const modalError = ref<string | null>(null)

const filteredZones = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return zones.value
  return zones.value.filter(
    (zone) =>
      zone.id.toLowerCase().includes(query) ||
      zone.name.toLowerCase().includes(query) ||
      zone.barangaysCovered.toLowerCase().includes(query),
  )
})

const hasActiveFilters = computed(() => searchQuery.value.trim().length > 0)

const resetFilters = () => {
  searchQuery.value = ''
}

const openCreateZone = () => {
  editingZoneId.value = null
  draftName.value = ''
  draftBarangays.value = ''
  draftCoords.value = '7.8257° N, 123.4370° E'
  draftSurge.value = 1.0
  draftPoints.value = 12
  draftStatus.value = 'Active'
  modalError.value = null
  showModal.value = true
}

const openEditZone = (zone: ServiceZone) => {
  editingZoneId.value = zone.id
  draftName.value = zone.name
  draftBarangays.value = zone.barangaysCovered
  draftCoords.value = zone.centerCoords
  draftSurge.value = zone.surgeFactor
  draftPoints.value = zone.polygonPoints
  draftStatus.value = zone.status
  modalError.value = null
  showModal.value = true
}

const saveZone = () => {
  const result = saveServiceZone(editingZoneId.value, {
    name: draftName.value,
    barangaysCovered: draftBarangays.value,
    centerCoords: draftCoords.value,
    surgeFactor: draftSurge.value,
    polygonPoints: draftPoints.value,
    status: draftStatus.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  toastMessage.value = result.message ?? 'Saved service zone.'
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
      title="Service Zones"
      description="Configure geofence boundaries and localized surge multipliers."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search zone ID, corridor, or Pagadian barangay..."
          aria-label="Search geofence zones"
          class="sm:max-w-sm"
        />
        <button
          type="button"
          class="self-start sm:self-auto px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateZone"
        >
          + Create Zone
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Zone ID</th>
              <th class="py-3 px-4">Zone &amp; Covered Barangays</th>
              <th class="py-3 px-4">Centroid GPS</th>
              <th class="py-3 px-4">Surge Factor</th>
              <th class="py-3 px-4">Polygon Vertices</th>
              <th class="py-3 px-4">Online Drivers</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="zone in filteredZones"
              :key="zone.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ zone.id }}</td>
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ zone.name }}</div>
                <div class="text-[11px] text-neutral-500">{{ zone.barangaysCovered }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-[11px] text-neutral-600">
                {{ zone.centerCoords }}
              </td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">
                {{ zone.surgeFactor.toFixed(1) }}x
              </td>
              <td class="py-3 px-4 font-mono text-neutral-500">
                {{ zone.polygonPoints }} vertices
              </td>
              <td class="py-3 px-4 font-bold text-neutral-800">{{ zone.activeDrivers }} drivers</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="zone.status"
                  :tone="
                    zone.status === 'Active'
                      ? 'success'
                      : zone.status === 'Monitoring'
                        ? 'warning'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                  @click="openEditZone(zone)"
                >
                  Edit Zone &amp; Surge
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredZones.length === 0"
              :colspan="8"
              title="No matching service zones"
              description="No geofence zones match the current search query."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      v-model:open="showModal"
      :title="editingZoneId ? `Configure Zone · ${editingZoneId}` : 'Create Geofence Zone'"
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="zone-name" class="block font-medium text-neutral-700 mb-1">Zone Name</label>
          <input
            id="zone-name"
            v-model="draftName"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label for="zone-barangays" class="block font-medium text-neutral-700 mb-1">
            Covered Barangays / Landmarks
          </label>
          <input
            id="zone-barangays"
            v-model="draftBarangays"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="zone-surge" class="block font-medium text-neutral-700 mb-1">
              Surge (1.0x–{{ config.maxBiddingSurgeCap.toFixed(1) }}x)
            </label>
            <input
              id="zone-surge"
              v-model.number="draftSurge"
              type="number"
              min="1"
              :max="config.maxBiddingSurgeCap"
              step="0.1"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
          </div>
          <div>
            <label for="zone-points" class="block font-medium text-neutral-700 mb-1">
              Polygon Vertices
            </label>
            <input
              id="zone-points"
              v-model.number="draftPoints"
              type="number"
              min="4"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
          </div>
        </div>
        <div>
          <label for="zone-coords" class="block font-medium text-neutral-700 mb-1">
            Center Coordinates
          </label>
          <input
            id="zone-coords"
            v-model="draftCoords"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Zone Status</label>
          <BaseSelect
            v-model="draftStatus"
            :full-width="true"
            aria-label="Service zone status"
            :options="['Active', 'Monitoring', 'Paused']"
          />
        </div>
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
            @click="saveZone"
          >
            Save Service Zone
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
