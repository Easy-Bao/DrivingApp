<script setup lang="ts">
import { StatusBadge, type BadgeTone } from '@/shared'
import type { DriverApplication } from '@/features/users/types'

defineProps<{
  application: DriverApplication
  statusTone: BadgeTone
}>()

const emit = defineEmits<{
  (e: 'openPhoto'): void
  (e: 'openLicense'): void
  (e: 'openVehicleDoc', docKind: 'OR' | 'CR' | 'CTPL' | 'MVIR'): void
  (e: 'openClearance'): void
}>()
</script>

<template>
  <div class="space-y-6">
    <div
      class="bg-white border border-neutral-200 p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
    >
      <div class="flex items-center space-x-4">
        <button
          type="button"
          class="relative group cursor-pointer shrink-0 border border-neutral-300 bg-neutral-100"
          title="View enlarged applicant photo"
          @click="emit('openPhoto')"
        >
          <img
            :src="application.facePhotoUrl"
            :alt="application.applicant"
            class="w-16 h-16 object-cover"
          />
          <span
            class="absolute inset-0 bg-neutral-900/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-[10px] font-semibold text-white"
          >
            Zoom
          </span>
        </button>

        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-lg font-bold text-neutral-900 tracking-tight">
              Application {{ application.id }}
            </h1>
            <StatusBadge :label="application.status" :tone="statusTone" />
          </div>
          <p class="text-sm font-semibold text-neutral-800 mt-0.5">{{ application.applicant }}</p>
          <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-neutral-500 mt-1">
            <span class="font-mono">{{ application.phone }}</span>
            <span>·</span>
            <span>{{ application.email }}</span>
            <span>·</span>
            <span>
              {{ application.barangay }}, {{ application.city }}, {{ application.province }}
            </span>
          </div>
        </div>
      </div>

      <div class="text-xs text-neutral-500 sm:text-right shrink-0">
        <div class="font-medium text-neutral-500 text-[11px]">Submitted</div>
        <div class="font-semibold text-neutral-900">{{ application.appliedDate }}</div>
        <div class="text-[11px]">{{ application.appliedTime }}</div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
        <div class="space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Driver License</h2>
            <button
              type="button"
              class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 cursor-pointer transition-colors"
              @click="emit('openLicense')"
            >
              View License
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div class="sm:col-span-2">
              <div class="text-neutral-500 text-[11px] font-medium">License Number</div>
              <div class="font-mono font-bold text-neutral-900 mt-0.5">
                {{ application.licenseNumber }}
              </div>
            </div>
            <div>
              <div class="text-neutral-500 text-[11px] font-medium">Classification &amp; Code</div>
              <div class="font-semibold text-neutral-900 mt-0.5">
                {{ application.licenseType }} · Code {{ application.licenseCodes }}
              </div>
            </div>
            <div>
              <div class="text-neutral-500 text-[11px] font-medium">Expiration</div>
              <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                {{ application.licenseExpiry }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Vehicle &amp; Franchise</h2>
          <span
            class="text-xs font-semibold px-2 py-0.5 bg-neutral-100 text-neutral-700 border border-neutral-200"
          >
            {{ application.vehicle.type }}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          <div>
            <div class="text-neutral-500 text-[11px] font-medium">Model &amp; Year</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.vehicle.year }} {{ application.vehicle.make }}
              {{ application.vehicle.model }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500 text-[11px] font-medium">Plate &amp; Body No.</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ application.vehicle.plate }} · {{ application.vehicle.bodyNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500 text-[11px] font-medium">TODA &amp; MTOP</div>
            <div class="font-semibold text-neutral-800 mt-0.5">
              {{ application.vehicle.todaFranchise }} · {{ application.vehicle.mtopNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500 text-[11px] font-medium">Engine / Chassis</div>
            <div class="font-mono text-neutral-700 mt-0.5">
              {{ application.vehicle.engineNumber }} / {{ application.vehicle.chassisNumber }}
            </div>
          </div>
        </div>

        <div
          class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs pt-2 border-t border-neutral-100"
        >
          <button
            type="button"
            class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
            @click="emit('openVehicleDoc', 'OR')"
          >
            <div class="min-w-0 pr-2">
              <div class="text-[11px] text-neutral-500 font-medium">LTO OR</div>
              <div class="font-mono font-semibold text-neutral-800 truncate">
                {{ application.vehicle.orNumber }}
              </div>
            </div>
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
              View
            </span>
          </button>

          <button
            type="button"
            class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
            @click="emit('openVehicleDoc', 'CR')"
          >
            <div class="min-w-0 pr-2">
              <div class="text-[11px] text-neutral-500 font-medium">LTO CR</div>
              <div class="font-mono font-semibold text-neutral-800 truncate">
                {{ application.vehicle.crNumber }}
              </div>
            </div>
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
              View
            </span>
          </button>

          <button
            type="button"
            class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
            @click="emit('openVehicleDoc', 'CTPL')"
          >
            <div class="min-w-0 pr-2">
              <div class="text-[11px] text-neutral-500 font-medium">CTPL Policy</div>
              <div class="font-semibold text-neutral-800 truncate">
                {{ application.vehicle.insurancePolicy }}
              </div>
            </div>
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
              View
            </span>
          </button>

          <button
            type="button"
            class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
            @click="emit('openVehicleDoc', 'MVIR')"
          >
            <div class="min-w-0 pr-2">
              <div class="text-[11px] text-neutral-500 font-medium">MVIR Certificate</div>
              <div class="font-mono text-neutral-800 truncate">
                {{ application.vehicle.inspectionDoc }}
              </div>
            </div>
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
              View
            </span>
          </button>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
        <div class="space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Background Clearance</h2>
            <button
              type="button"
              class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 cursor-pointer transition-colors"
              @click="emit('openClearance')"
            >
              View Certificate
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div>
              <div class="text-neutral-500 text-[11px] font-medium">Authority</div>
              <div class="font-semibold text-neutral-900 mt-0.5 flex items-center gap-2">
                <span>{{ application.backgroundProvider }}</span>
                <StatusBadge
                  :label="application.backgroundStatus"
                  :tone="application.backgroundStatus === 'Passed' ? 'success' : 'warning'"
                />
              </div>
            </div>
            <div>
              <div class="text-neutral-500 text-[11px] font-medium">Reference No.</div>
              <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                {{ application.clearanceNumber }}
              </div>
            </div>
          </div>

          <div class="p-3 bg-neutral-50 border border-neutral-200 text-xs">
            <div class="font-semibold text-neutral-900">Remarks</div>
            <p class="text-neutral-600 mt-1 leading-relaxed">{{ application.backgroundNotes }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
