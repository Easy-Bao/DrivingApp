<script setup lang="ts">
import { motion } from 'motion-v'
import { computed, ref } from 'vue'
import type { ArchitectureServiceNode } from '@/features/platform-architecture/types'

const EASE = [0.22, 1, 0.36, 1] as const

interface DetailedArchitectureNode extends ArchitectureServiceNode {
  id: string
  step: string
  responsibility: string
}

const ARCHITECTURE_NODES: DetailedArchitectureNode[] = [
  {
    id: 'gateway',
    step: '01',
    name: 'API Gateway',
    role: 'HTTP & WebSocket Ingress',
    protocol: 'REST + WS',
    responsibility: 'Terminates requests, checks auth sessions, and upgrades live bidding sockets.',
  },
  {
    id: 'core',
    step: '02',
    name: 'Core Dispatch',
    role: 'Domain & Persistence',
    protocol: 'PostgreSQL + PostGIS',
    responsibility: 'Enforces trip state machines, fare floors, and wallet commission ledgers.',
  },
  {
    id: 'realtime',
    step: '03',
    name: 'Realtime Broker',
    role: 'Location & Bidding Fanout',
    protocol: 'WebSockets + Redis',
    responsibility:
      'Streams nearby Pagadian trip broadcasts and live driver bids inside 90s windows.',
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
  <section id="services" class="space-y-5">
    <div class="grid gap-4 md:grid-cols-3">
      <button
        v-for="node in ARCHITECTURE_NODES"
        :key="node.id"
        type="button"
        class="rounded-2xl border p-6 text-left transition-all duration-150"
        :class="
          selectedNodeId === node.id
            ? 'border-neutral-950 bg-white shadow-[0_14px_32px_-18px_rgba(9,13,22,0.16)] ring-1 ring-neutral-950/10'
            : 'border-neutral-200/85 bg-white/70 hover:border-neutral-300 hover:bg-white'
        "
        @click="selectedNodeId = node.id"
      >
        <div class="flex items-center justify-between gap-2">
          <span class="font-mono text-[11px] font-bold tabular-nums text-neutral-400">
            {{ node.step }}
          </span>
          <span
            class="h-2 w-2 rounded-full transition-colors"
            :class="selectedNodeId === node.id ? 'bg-emerald-600' : 'bg-neutral-200'"
            aria-hidden="true"
          />
        </div>

        <h2 class="mt-4 text-base font-bold tracking-[-0.015em] text-neutral-950">
          {{ node.name }}
        </h2>
        <p class="mt-1 text-xs font-medium text-neutral-500">{{ node.role }}</p>

        <span
          class="mt-5 inline-flex rounded-full border border-neutral-200/80 bg-neutral-50 px-2.5 py-1 font-mono text-[11px] text-neutral-600"
        >
          {{ node.protocol }}
        </span>
      </button>
    </div>

    <motion.div
      v-if="activeNode"
      :key="activeNode.id"
      :initial="{ opacity: 0, y: 6 }"
      :animate="{ opacity: 1, y: 0 }"
      :transition="{ duration: 0.22, ease: EASE }"
      class="rounded-2xl border border-neutral-200/85 bg-white p-6 shadow-[0_1px_3px_rgba(9,13,22,0.03)] sm:p-7"
    >
      <div class="flex flex-wrap items-center justify-between gap-2">
        <h3 class="text-base font-bold tracking-[-0.015em] text-neutral-950">
          {{ activeNode.name }}
        </h3>
        <span class="font-mono text-xs text-neutral-400">{{ activeNode.protocol }}</span>
      </div>
      <p class="mt-2.5 max-w-2xl text-sm leading-relaxed text-neutral-600">
        {{ activeNode.responsibility }}
      </p>
    </motion.div>
  </section>
</template>
