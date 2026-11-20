<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  DEFAULT_REPORT_FILTERS,
  hasCustomReportFilters,
} from '@/features/reports/composables/use-reports'
import type {
  ReportDateRange,
  ReportDispatchModeFilter,
  ReportFilterValues,
} from '@/features/reports/types'
import { BaseSelect, ToastBanner, useToast } from '@/shared'

const props = defineProps<{
  reportTitle: string
}>()

const emit = defineEmits<{
  (e: 'change', filters: ReportFilterValues): void
  (e: 'export', payload: { format: 'CSV'; filters: ReportFilterValues }): void
}>()

const dateRange = ref<ReportDateRange>(DEFAULT_REPORT_FILTERS.dateRange)
const cityZone = ref(DEFAULT_REPORT_FILTERS.cityZone)
const dispatchMode = ref<ReportDispatchModeFilter>(DEFAULT_REPORT_FILTERS.dispatchMode)
const { message: exportToast, tone: exportToastTone, showToast, dismissToast } = useToast('info')

const currentFilters = computed<ReportFilterValues>(() => ({
  dateRange: dateRange.value,
  cityZone: cityZone.value,
  dispatchMode: dispatchMode.value,
}))

watch(currentFilters, (filters) => emit('change', filters), { immediate: true })

const hasActiveFilters = computed(() => hasCustomReportFilters(currentFilters.value))

const resetFilters = () => {
  dateRange.value = DEFAULT_REPORT_FILTERS.dateRange
  cityZone.value = DEFAULT_REPORT_FILTERS.cityZone
  dispatchMode.value = DEFAULT_REPORT_FILTERS.dispatchMode
}

defineExpose({ resetFilters })

const triggerExport = () => {
  const filters = { ...currentFilters.value }
  emit('export', { format: 'CSV', filters })
  const zoneLabel = cityZone.value === 'all-zones' ? 'All Zones' : cityZone.value
  showToast(`Prepared ${props.reportTitle} (CSV) for ${zoneLabel}.`)
}
</script>

<template>
  <div class="space-y-3">
    <ToastBanner :message="exportToast" :tone="exportToastTone" @dismiss="dismissToast" />

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
            Zone
          </label>
          <BaseSelect
            v-model="cityZone"
            :full-width="true"
            aria-label="Filter report operating zone"
            :options="[
              { label: 'All Zones', value: 'all-zones' },
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
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors cursor-pointer"
          @click="triggerExport"
        >
          Download CSV
        </button>
      </div>
    </div>
  </div>
</template>
