<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps<{
  reportTitle: string
}>()

const emit = defineEmits<{
  (e: 'export', format: 'CSV' | 'PDF' | 'Excel'): void
}>()

const dateRange = ref('last-30-days')
const cityZone = ref('all-zones')
const vehicleType = ref('all-tiers')

const exportToast = ref<string | null>(null)

function triggerExport(format: 'CSV' | 'PDF' | 'Excel') {
  emit('export', format)
  exportToast.value = `Exporting ${props.reportTitle} as ${format} (Filters: ${dateRange.value}, ${cityZone.value}, ${vehicleType.value}). Generating file...`
  setTimeout(() => {
    exportToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-3">
    <!-- Filter Bar Card -->
    <div
      class="bg-white border border-neutral-200 rounded-xl p-4 shadow-2xs flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4"
    >
      <!-- Filters: Date Range, City / Zone, Driver / Vehicle Type -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 flex-1">
        <!-- Date Range Filter -->
        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            Date Range
          </label>
          <div class="relative">
            <Icon
              icon="lucide:calendar"
              class="absolute left-2.5 top-2.5 text-neutral-400 text-xs"
            />
            <select
              v-model="dateRange"
              class="w-full pl-7 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 rounded-lg text-xs text-neutral-800 font-medium focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
            >
              <option value="today">Today</option>
              <option value="last-7-days">Last 7 Days</option>
              <option value="last-30-days">Last 30 Days</option>
              <option value="this-quarter">This Quarter</option>
              <option value="year-to-date">Year to Date (YTD)</option>
            </select>
          </div>
        </div>

        <!-- City / Zone Filter -->
        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            City / Operating Zone
          </label>
          <div class="relative">
            <Icon
              icon="lucide:map-pin"
              class="absolute left-2.5 top-2.5 text-neutral-400 text-xs"
            />
            <select
              v-model="cityZone"
              class="w-full pl-7 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 rounded-lg text-xs text-neutral-800 font-medium focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
            >
              <option value="all-zones">All Operating Zones</option>
              <option value="downtown-central">Downtown Central</option>
              <option value="airport-corridor">Airport Express Corridor</option>
              <option value="west-valley">West Valley University</option>
              <option value="north-hills">North Residential Hills</option>
            </select>
          </div>
        </div>

        <!-- Driver / Vehicle Type Filter -->
        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            Driver / Vehicle Class
          </label>
          <div class="relative">
            <Icon icon="lucide:car" class="absolute left-2.5 top-2.5 text-neutral-400 text-xs" />
            <select
              v-model="vehicleType"
              class="w-full pl-7 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 rounded-lg text-xs text-neutral-800 font-medium focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
            >
              <option value="all-tiers">All Vehicle Types & Fleets</option>
              <option value="economy">Economy Sedan</option>
              <option value="comfort">Comfort</option>
              <option value="xl-family">XL Family</option>
              <option value="executive-black">Executive Chauffeur</option>
              <option value="ev-only">100% Electric Vehicle (EV)</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Export Actions (CSV, PDF, Excel) -->
      <div
        class="flex items-center space-x-2 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-neutral-100"
      >
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 rounded-lg text-xs font-semibold transition-colors flex items-center space-x-1.5"
          @click="triggerExport('CSV')"
        >
          <Icon icon="lucide:file-text" class="text-neutral-500" />
          <span>CSV</span>
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 rounded-lg text-xs font-semibold transition-colors flex items-center space-x-1.5"
          @click="triggerExport('PDF')"
        >
          <Icon icon="lucide:file-down" class="text-rose-600" />
          <span>PDF</span>
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-1.5 shadow-2xs"
          @click="triggerExport('Excel')"
        >
          <Icon icon="lucide:file-spreadsheet" class="text-emerald-400" />
          <span>Excel</span>
        </button>
      </div>
    </div>

    <!-- Export Notification Toast -->
    <div
      v-if="exportToast"
      class="p-3.5 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:download-cloud" class="text-emerald-400 text-base animate-bounce" />
        <span>{{ exportToast }}</span>
      </div>
      <button type="button" @click="exportToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>
  </div>
</template>
