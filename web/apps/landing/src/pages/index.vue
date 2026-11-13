<script setup lang="ts">
import {
  DriveCalloutSection,
  FleetServicesSection,
  HeroSection,
  HowItWorksSection,
} from '@/features/landing-showcase'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <HeroSection />
    <FleetServicesSection />
    <HowItWorksSection />
    <DriveCalloutSection />
  </LandingLayout>
</template>
