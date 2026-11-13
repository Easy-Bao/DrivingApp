<script setup lang="ts">
import { computed, ref } from 'vue'
import type { ArchitectureServiceNode } from '@/features/platform-architecture/types'
import UiIcon from '@/shared/components/UiIcon.vue'

interface DetailedArchitectureNode extends ArchitectureServiceNode {
  id: string
  responsibility: string
  highlights: string[]
  latencyTarget: string
}

const ARCHITECTURE_NODES: DetailedArchitectureNode[] = [
  {
    id: 'gateway',
    name: 'Go API Gateway',
    role: 'HTTP & WebSocket Ingress',
    protocol: 'REST JSON + WS Upgrade',
    responsibility:
      'Terminates TLS, authenticates Firebase JWT passenger/driver sessions, rate-limits requests, and upgrades real-time bidding channels.',
    highlights: [
      'Role-scoped Firebase token verification',
      'Idempotent trip & QRPh top-up endpoints',
      'Single binary reverse-proxy ingress',
    ],
    latencyTarget: '< 25 ms p95',
  },
  {
    id: 'core',
    name: 'Core Dispatch Service',
    role: 'Domain Logic & Persistence',
    protocol: 'Modular Monolith · sqlc + PostgreSQL',
    responsibility:
      'Enforces trip state machines, municipal Taxicle tariff floors, prepaid wallet commission ledgers, and driver document expiry rules.',
    highlights: [
      'Parameterized sqlc queries over PostgreSQL + PostGIS',
      'Atomic prepaid QRPh wallet debit on trip completion',
      'Outbox & compliance checks before bidding access',
    ],
    latencyTarget: '< 40 ms p95',
  },
  {
    id: 'realtime',
    name: 'Realtime Bidding Broker',
    role: 'Location & 90s Auction Fanout',
    protocol: 'WebSockets + Redis Pub/Sub',
    responsibility:
      'Broadcasts new Pagadian passenger trip requests to nearby MTOP-verified online drivers and streams incoming PHP bids back live.',
    highlights: [
      '90-second deterministic auction countdown timer',
      'Geo-indexed driver presence across barangay corridors',
      'Live trip telemetry & SOS event fanout',
    ],
    latencyTarget: '< 60 ms bid fanout',
  },
]

const selectedNodeId = ref<string>(ARCHITECTURE_NODES[0]?.id ?? 'gateway')

const activeNode = computed(() => {
  return (
    ARCHITECTURE_NODES.find((node) => node.id === selectedNodeId.value) ?? ARCHITECTURE_NODES[0]
  )
})
</script>

<template>
  <section id="services" class="space-y-6">
    <div class="grid gap-5 md:grid-cols-3">
      <button
        v-for="node in ARCHITECTURE_NODES"
        :key="node.id"
        type="button"
        class="flex flex-col justify-between rounded-3xl border p-6 text-left transition-all"
        :class="
          selectedNodeId === node.id
            ? 'border-emerald-600 bg-white shadow-md ring-1 ring-emerald-600/20'
            : 'border-slate-200 bg-slate-50/70 hover:border-slate-300 hover:bg-white'
        "
        @click="selectedNodeId = node.id"
      >
        <div>
          <div class="flex items-center justify-between gap-2">
            <span
              class="inline-flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200"
            >
              <UiIcon :name="node.id === 'realtime' ? 'radio' : 'server'" size-class="h-5 w-5" />
            </span>
            <span
              class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-bold tabular-nums text-slate-700"
            >
              {{ node.latencyTarget }}
            </span>
          </div>

          <h2 class="mt-4 text-lg font-extrabold text-[#090d16]">{{ node.name }}</h2>
          <p class="mt-0.5 text-sm font-semibold text-emerald-800">{{ node.role }}</p>
        </div>

        <p
          class="mt-4 rounded-xl bg-slate-100/90 px-3 py-2 text-xs font-mono font-semibold text-slate-700"
        >
          {{ node.protocol }}
        </p>
      </button>
    </div>

    <div
      v-if="activeNode"
      id="protocol"
      class="rounded-3xl border border-slate-200 bg-white p-6 shadow-xs sm:p-8"
    >
      <div class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 pb-4">
        <div>
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Selected Node Specification
          </p>
          <h3 class="mt-0.5 text-2xl font-extrabold text-[#090d16]">{{ activeNode.name }}</h3>
        </div>
        <span
          class="rounded-full bg-[#090d16] px-4 py-1.5 text-xs font-mono font-semibold text-emerald-300"
        >
          {{ activeNode.protocol }}
        </span>
      </div>

      <p class="mt-4 max-w-3xl text-sm leading-relaxed text-slate-700 sm:text-base">
        {{ activeNode.responsibility }}
      </p>

      <ul class="mt-5 grid gap-3 sm:grid-cols-3">
        <li
          v-for="item in activeNode.highlights"
          :key="item"
          class="flex items-start gap-2.5 rounded-2xl border border-slate-200/80 bg-slate-50 p-4 text-xs font-semibold text-slate-800"
        >
          <UiIcon name="check-circle" size-class="mt-0.5 h-4 w-4 text-emerald-700" />
          <span>{{ item }}</span>
        </li>
      </ul>
    </div>
  </section>
</template>
