<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

export interface ReportFilterValues {
  dateRange: 'today' | 'last-7-days' | 'last-30-days' | 'this-quarter'
  cityZone: string
  dispatchMode: string
}

const props = defineProps<{
  reportTitle: string
}>()

const emit = defineEmits<{
  (e: 'change', filters: ReportFilterValues): void
  (e: 'export', payload: { format: 'CSV' | 'PDF' | 'Excel'; filters: ReportFilterValues }): void
}>()

const dateRange = ref<ReportFilterValues['dateRange']>('last-30-days')
const cityZone = ref('all-zones')
const dispatchMode = ref('all-modes')
const exportToast = ref<string | null>(null)

const emitFilters = () => {
  emit('change', {
    dateRange: dateRange.value,
    cityZone: cityZone.value,
    dispatchMode: dispatchMode.value,
  })
}

watch([dateRange, cityZone, dispatchMode], emitFilters, { immediate: true })

const hasActiveFilters = computed(
  () =>
    dateRange.value !== 'last-30-days' ||
    cityZone.value !== 'all-zones' ||
    dispatchMode.value !== 'all-modes',
)

const resetFilters = () => {
  dateRange.value = 'last-30-days'
  cityZone.value = 'all-zones'
  dispatchMode.value = 'all-modes'
}

defineExpose({ resetFilters })

const triggerExport = (format: 'CSV' | 'PDF' | 'Excel') => {
  const filters: ReportFilterValues = {
    dateRange: dateRange.value,
    cityZone: cityZone.value,
    dispatchMode: dispatchMode.value,
  }
  emit('export', { format, filters })
  exportToast.value = `Prepared ${props.reportTitle} (${format}) for ${cityZone.value === 'all-zones' ? 'All Pagadian Zones' : cityZone.value}.`
}
</script>

<template>
  <div class="space-y-3">
    <ToastBanner
      v-if="exportToast"
      :message="exportToast"
      tone="info"
      @dismiss="exportToast = null"
    />

    <div
      class="bg-white border border-neutral-200 p-4 flex flex-col lg:flex-row lg:items-end lg:justify-between gap-4"
    >
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 flex-1">
        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            Date Range
          </label>
          <BaseSelect
            v-model="dateRange"
            :full-width="true"
            aria-label="Filter report date range"
            :options="[
              { label: 'Today (PHT)', value: 'today' },
              { label: 'Last 7 Days', value: 'last-7-days' },
              { label: 'Last 30 Days', value: 'last-30-days' },
              { label: 'This Quarter', value: 'this-quarter' },
            ]"
          />
        </div>

        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            Pagadian Operating Zone
          </label>
          <BaseSelect
            v-model="cityZone"
            :full-width="true"
            aria-label="Filter report operating zone"
            :options="[
              { label: 'All Pagadian Zones', value: 'all-zones' },
              { label: 'Poblacion & Agora Market', value: 'poblacion' },
              { label: 'Integrated Bus Terminal', value: 'terminal' },
              { label: 'Dao Capitol & Gaisano', value: 'dao-capitol' },
              { label: 'Santiago Port & Coastal', value: 'santiago-port' },
            ]"
          />
        </div>

        <div>
          <label
            class="block text-[11px] font-semibold text-neutral-500 uppercase tracking-wider mb-1"
          >
            Dispatch Mode
          </label>
          <BaseSelect
            v-model="dispatchMode"
            :full-width="true"
            aria-label="Filter report dispatch mode"
            :options="[
              { label: 'All Dispatch Modes', value: 'all-modes' },
              { label: 'Open Broadcast', value: 'open-broadcast' },
              { label: 'Chosen Driver', value: 'chosen-driver' },
            ]"
          />
        </div>
      </div>

      <div
        class="flex flex-wrap items-center gap-2 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-neutral-100"
      >
        <button
          v-if="hasActiveFilters"
          type="button"
          class="px-3 py-1.5 bg-white border border-neutral-300 hover:bg-neutral-50 text-neutral-700 rounded-none text-xs font-medium transition-colors cursor-pointer"
          @click="resetFilters"
        >
          Reset
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-white border border-neutral-300 hover:bg-neutral-50 text-neutral-800 rounded-none text-xs font-semibold transition-colors inline-flex items-center gap-1.5 cursor-pointer"
          @click="triggerExport('CSV')"
        >
          <Icon icon="lucide:file-text" class="text-neutral-500 h-3.5 w-3.5" aria-hidden="true" />
          <span>Download CSV</span>
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors inline-flex items-center gap-1.5"
          @click="triggerExport('Excel')"
        >
          <Icon
            icon="lucide:file-spreadsheet"
            class="text-emerald-400 h-3.5 w-3.5"
            aria-hidden="true"
          />
          <span>Export Spreadsheet</span>
        </button>
      </div>
    </div>
  </div>
</template>
