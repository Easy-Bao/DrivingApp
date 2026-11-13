<script setup lang="ts">
import {
  BenefitsSection,
  DriveCalloutSection,
  FareTrySection,
  FinalCtaSection,
  FleetServicesSection,
  HeroSection,
  HowItWorksSection,
} from '@/features/landing-showcase'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <HeroSection />
    <BenefitsSection />
    <HowItWorksSection />
    <FleetServicesSection />
    <FareTrySection />
    <DriveCalloutSection />
    <FinalCtaSection />
  </LandingLayout>
</template>
