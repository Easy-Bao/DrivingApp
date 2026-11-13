<script setup lang="ts">
import {
  BiddingShowcaseSection,
  CoverageCorridorsSection,
  DriverBannerSection,
  FaqSection,
  FleetServicesSection,
  HeroSection,
  SafetyTrustSection,
} from '@/features/landing-showcase'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <HeroSection />
    <FleetServicesSection />
    <BiddingShowcaseSection />
    <CoverageCorridorsSection />
    <SafetyTrustSection />
    <DriverBannerSection />
    <FaqSection />
  </LandingLayout>
</template>
