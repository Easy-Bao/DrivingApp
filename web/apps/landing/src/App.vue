<script setup lang="ts">
import { MotionConfig, motion } from 'motion-v'
import { RouterView } from 'vue-router'
</script>

<template>
  <MotionConfig reduced-motion="user">
    <RouterView v-slot="{ Component, route }">
      <motion.div
        :key="route.path"
        :initial="{ opacity: 0, y: 6 }"
        :animate="{ opacity: 1, y: 0 }"
        :transition="{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }"
      >
        <component :is="Component" />
      </motion.div>
    </RouterView>
  </MotionConfig>
</template>
