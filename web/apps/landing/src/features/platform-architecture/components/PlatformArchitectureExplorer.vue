<script setup lang="ts">
import type { ArchitectureServiceNode } from '@/features/platform-architecture/types'

const serviceNodes: ArchitectureServiceNode[] = [
  { name: 'Gateway', role: 'Reverse Proxy & Ingress', protocol: 'HTTP/2 & WS' },
  { name: 'Core Service', role: 'Ride Matching & Trips', protocol: 'gRPC & Postgres' },
  { name: 'Realtime Service', role: 'Driver Telemetry Stream', protocol: 'WebSocket & Redis' },
]
</script>

<template>
  <div class="rounded-xl border border-neutral-200 bg-white p-6">
    <h2 class="text-xl font-bold text-neutral-900 mb-4">Platform Architecture Topology</h2>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div
        v-for="node in serviceNodes"
        :key="node.name"
        class="p-4 rounded-lg bg-neutral-50 border border-neutral-200"
      >
        <span class="text-xs font-semibold text-neutral-500 uppercase">{{ node.protocol }}</span>
        <h4 class="text-base font-semibold text-neutral-900 mt-1">{{ node.name }}</h4>
        <p class="text-sm text-neutral-600 mt-1">{{ node.role }}</p>
      </div>
    </div>
  </div>
</template>
