<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface ServiceZone {
  id: string
  name: string
  barangaysCovered: string
  centerCoords: string
  surgeFactor: number
  polygonPoints: number
  activeDrivers: number
  status: 'Active' | 'Monitoring' | 'Paused'
}

const zones = ref<ServiceZone[]>([
  {
    id: 'ZN-PAG-01',
    name: 'Poblacion & Agora Market Core',
    barangaysCovered: 'San Jose, San Francisco, Gatas, Santiago, Santo Nino',
    centerCoords: '7.8257° N, 123.4370° E',
    surgeFactor: 1.4,
    polygonPoints: 18,
    activeDrivers: 64,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-02',
    name: 'Integrated Bus Terminal & Bulatok',
    barangaysCovered: 'Bulatok, Tawagan Sur, San Pedro',
    centerCoords: '7.8342° N, 123.4285° E',
    surgeFactor: 1.8,
    polygonPoints: 14,
    activeDrivers: 39,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-03',
    name: 'Dao Capitol & Gaisano Corridor',
    barangaysCovered: 'Dao, Tuburan, Tiguma, Balangasan',
    centerCoords: '7.8391° N, 123.4418° E',
    surgeFactor: 1.2,
    polygonPoints: 16,
    activeDrivers: 45,
    status: 'Active',
  },
  {
    id: 'ZN-PAG-04',
    name: 'Santiago Wharf & Coastal Belt',
    barangaysCovered: 'Santiago, Santa Lucia, Kawit',
    centerCoords: '7.8211° N, 123.4404° E',
    surgeFactor: 1.5,
    polygonPoints: 12,
    activeDrivers: 22,
    status: 'Monitoring',
  },
])

const searchQuery = ref('')
const toastMessage = ref<string | null>(null)

const showModal = ref(false)
const editingZoneId = ref<string | null>(null)
const draftName = ref('')
const draftBarangays = ref('')
const draftCoords = ref('7.8257° N, 123.4370° E')
const draftSurge = ref(1.0)
const draftPoints = ref(12)
const draftStatus = ref<ServiceZone['status']>('Active')
const modalError = ref<string | null>(null)

const filteredZones = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return zones.value
  return zones.value.filter(
    (z) =>
      z.id.toLowerCase().includes(q) ||
      z.name.toLowerCase().includes(q) ||
      z.barangaysCovered.toLowerCase().includes(q),
  )
})

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
  if (!draftName.value.trim() || !draftBarangays.value.trim()) {
    modalError.value = 'Provide zone title and covered Pagadian barangays.'
    return
  }
  if (draftSurge.value < 1 || draftSurge.value > 2.5) {
    modalError.value = 'Zone surge multiplier must remain between 1.0x and 2.5x.'
    return
  }
  if (editingZoneId.value) {
    const existing = zones.value.find((z) => z.id === editingZoneId.value)
    if (existing) {
      existing.name = draftName.value.trim()
      existing.barangaysCovered = draftBarangays.value.trim()
      existing.centerCoords = draftCoords.value.trim()
      existing.surgeFactor = Number(draftSurge.value.toFixed(1))
      existing.polygonPoints = draftPoints.value
      existing.status = draftStatus.value
      toastMessage.value = `Updated geofence zone ${existing.name} (${existing.surgeFactor.toFixed(1)}x cap).`
    }
  } else {
    const nextId = `ZN-PAG-0${zones.value.length + 1}`
    zones.value.unshift({
      id: nextId,
      name: draftName.value.trim(),
      barangaysCovered: draftBarangays.value.trim(),
      centerCoords: draftCoords.value.trim() || '7.8257° N, 123.4370° E',
      surgeFactor: Number(draftSurge.value.toFixed(1)),
      polygonPoints: draftPoints.value,
      activeDrivers: 0,
      status: draftStatus.value,
    })
    toastMessage.value = `Created geofence zone ${nextId}: ${draftName.value.trim()}.`
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

    <div
      class="bg-white border border-neutral-200 p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">
          Pagadian City Geofence Zones &amp; Surge Boundaries
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Configure barangay polygon boundaries and localized bidding demand multipliers (max 2.5x
          server cap).
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search zone ID, corridor, or Pagadian barangay..."
          class="w-full max-w-sm px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
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
              <th class="py-3 px-4">Online Taxicles</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="z in filteredZones"
              :key="z.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ z.id }}</td>
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ z.name }}</div>
                <div class="text-[11px] text-neutral-500">{{ z.barangaysCovered }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-[11px] text-neutral-600">{{ z.centerCoords }}</td>
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">
                {{ z.surgeFactor.toFixed(1) }}x
              </td>
              <td class="py-3 px-4 font-mono text-neutral-500">{{ z.polygonPoints }} vertices</td>
              <td class="py-3 px-4 font-bold text-neutral-800">{{ z.activeDrivers }} drivers</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="z.status"
                  :tone="
                    z.status === 'Active'
                      ? 'success'
                      : z.status === 'Monitoring'
                        ? 'warning'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                  @click="openEditZone(z)"
                >
                  Edit Zone &amp; Surge
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="showModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="showModal = false"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-md bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">
              {{ editingZoneId ? `Configure Zone · ${editingZoneId}` : 'Create Geofence Zone' }}
            </h3>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Zone Name</label>
              <input
                v-model="draftName"
                type="text"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
              />
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">
                Covered Barangays / Landmarks
              </label>
              <input
                v-model="draftBarangays"
                type="text"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
              />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block font-medium text-neutral-700 mb-1">Surge (1.0x–2.5x)</label>
                <input
                  v-model.number="draftSurge"
                  type="number"
                  min="1"
                  max="2.5"
                  step="0.1"
                  class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
                />
              </div>
              <div>
                <label class="block font-medium text-neutral-700 mb-1">Polygon Vertices</label>
                <input
                  v-model.number="draftPoints"
                  type="number"
                  min="4"
                  class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
                />
              </div>
            </div>
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Center Coordinates</label>
              <input
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

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
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
        </div>
      </div>
    </Teleport>
  </div>
</template>
