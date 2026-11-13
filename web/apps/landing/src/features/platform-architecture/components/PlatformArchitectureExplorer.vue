<script setup lang="ts">
import { computed, ref } from 'vue'
import type { ArchitectureServiceNode } from '@/features/platform-architecture/types'

interface DetailedArchitectureNode extends ArchitectureServiceNode {
  id: string
  responsibility: string
}

const ARCHITECTURE_NODES: DetailedArchitectureNode[] = [
  {
    id: 'gateway',
    name: 'API Gateway',
    role: 'HTTP & WebSocket Ingress',
    protocol: 'REST + WS',
    responsibility: 'Terminates requests, checks auth sessions, and upgrades live bidding sockets.',
  },
  {
    id: 'core',
    name: 'Core Dispatch',
    role: 'Domain & Persistence',
    protocol: 'PostgreSQL + PostGIS',
    responsibility: 'Enforces trip state machines, fare floors, and wallet commission ledgers.',
  },
  {
    id: 'realtime',
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
  <section id="services" class="space-y-4">
    <div class="grid gap-4 md:grid-cols-3">
      <button
        v-for="node in ARCHITECTURE_NODES"
        :key="node.id"
        type="button"
        class="border p-5 text-left transition-colors"
        :class="
          selectedNodeId === node.id
            ? 'border-neutral-900 bg-white'
            : 'border-neutral-200 bg-neutral-50 hover:border-neutral-300 hover:bg-white'
        "
        @click="selectedNodeId = node.id"
      >
        <h2 class="text-base font-bold text-neutral-900">{{ node.name }}</h2>
        <p class="mt-0.5 text-xs font-medium text-neutral-600">{{ node.role }}</p>
        <p class="mt-3 font-mono text-xs text-neutral-500">{{ node.protocol }}</p>
      </button>
    </div>

    <div v-if="activeNode" class="border border-neutral-200 bg-white p-5">
      <h3 class="text-base font-bold text-neutral-900">{{ activeNode.name }}</h3>
      <p class="mt-1.5 text-sm text-neutral-600">{{ activeNode.responsibility }}</p>
    </div>
  </section>
</template>
