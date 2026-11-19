<script setup lang="ts">
import { motion } from 'motion-v'
import { RouterLink } from 'vue-router'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section class="relative overflow-hidden border-b border-neutral-200/70 bg-white">
    <div
      class="pointer-events-none absolute inset-x-0 top-0 h-[34rem] bg-[radial-gradient(ellipse_75%_55%_at_70%_-10%,rgba(9,13,22,0.04),transparent_70%)]"
      aria-hidden="true"
    />

    <div
      class="relative mx-auto grid max-w-6xl items-center gap-14 px-5 py-16 sm:px-6 sm:py-22 lg:grid-cols-12 lg:gap-12 lg:py-26"
    >
      <div class="lg:col-span-7">
        <motion.p
          :initial="{ opacity: 0, y: 10 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.45, ease: EASE }"
          class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase"
        >
          Pagadian City
        </motion.p>

        <motion.h1
          :initial="{ opacity: 0, y: 14 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.55, delay: 0.06, ease: EASE }"
          class="mt-4 max-w-xl text-4xl leading-[1.06] font-bold tracking-[-0.035em] text-neutral-950 sm:text-5xl lg:text-[3.5rem]"
        >
          Rides around Pagadian, made easy.
        </motion.h1>

        <motion.p
          :initial="{ opacity: 0, y: 14 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.55, delay: 0.12, ease: EASE }"
          class="mt-5 max-w-md text-base leading-relaxed text-neutral-500 sm:text-[1.0625rem]"
        >
          Book a Taxicle in seconds. See the fare first, pick your driver, and pay in cash.
        </motion.p>

        <motion.div
          :initial="{ opacity: 0, y: 14 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.55, delay: 0.18, ease: EASE }"
          class="mt-8 flex flex-wrap items-center gap-3"
        >
          <RouterLink
            to="/download"
            class="inline-flex min-h-12 items-center rounded-full bg-neutral-950 px-6 py-3 text-sm font-semibold text-white shadow-[0_8px_20px_-8px_rgba(9,13,22,0.45)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.98]"
          >
            Download App
          </RouterLink>

          <RouterLink
            to="/drive"
            class="inline-flex min-h-12 items-center rounded-full border border-neutral-200/90 bg-white px-6 py-3 text-sm font-semibold text-neutral-900 shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-all duration-150 hover:border-neutral-300 hover:bg-neutral-50 active:scale-[0.98]"
          >
            Become a Driver
          </RouterLink>
        </motion.div>

        <motion.div
          :initial="{ opacity: 0 }"
          :animate="{ opacity: 1 }"
          :transition="{ duration: 0.55, delay: 0.26, ease: EASE }"
          class="mt-8 flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-neutral-200/70 pt-6 text-xs text-neutral-500"
        >
          <span>Free for passengers</span>
          <span class="h-1 w-1 rounded-full bg-neutral-300" aria-hidden="true" />
          <span>Upfront PHP fares</span>
          <span class="h-1 w-1 rounded-full bg-neutral-300" aria-hidden="true" />
          <span>Android and iOS</span>
        </motion.div>
      </div>

      <motion.div
        :initial="{ opacity: 0, y: 22, scale: 0.98 }"
        :animate="{ opacity: 1, y: 0, scale: 1 }"
        :transition="{ duration: 0.65, delay: 0.14, ease: EASE }"
        class="relative flex justify-center lg:col-span-5 lg:justify-end"
        aria-hidden="true"
      >
        <div
          class="pointer-events-none absolute -inset-6 rounded-full bg-[radial-gradient(circle_at_center,rgba(9,13,22,0.06),transparent_65%)]"
        />

        <div
          class="relative w-[18.25rem] rounded-[2.75rem] bg-[#0b0f19] p-[10px] shadow-[0_36px_80px_-24px_rgba(9,13,22,0.28),0_8px_24px_-8px_rgba(9,13,22,0.1)] ring-1 ring-neutral-900/15 sm:w-[19.5rem]"
        >
          <div
            class="overflow-hidden rounded-[2.15rem] bg-[#f4f5f7] ring-1 ring-inset ring-black/5"
          >
            <!-- Status bar & minimalist dynamic pill -->
            <div
              class="relative z-10 flex items-center justify-between px-5 pt-3 pb-1 text-[10px] font-semibold text-neutral-800"
            >
              <span class="tabular-nums">9:41</span>
              <span class="h-4 w-16 rounded-full bg-[#0b0f19]" />
              <span class="text-[9px] font-bold tracking-tight text-neutral-600">5G</span>
            </div>

            <!-- Minimalist vector Pagadian map preview -->
            <div class="relative h-64 w-full overflow-hidden">
              <svg
                class="absolute inset-0 h-full w-full"
                viewBox="0 0 280 256"
                fill="none"
                preserveAspectRatio="xMidYMid slice"
              >
                <rect width="280" height="256" fill="#f3f4f6" />
                <path d="M0 198 C55 208, 92 224, 138 256 L0 256 Z" fill="#e6edf3" />
                <rect x="24" y="108" width="44" height="36" rx="8" fill="#e7efe9" />
                <rect x="184" y="34" width="54" height="38" rx="8" fill="#e7efe9" />

                <!-- Clean street network -->
                <path
                  d="M-10 62 L290 48 M-10 124 L290 108 M-10 184 L290 168 M72 -10 L58 266 M148 -10 L138 266 M224 -10 L212 266"
                  stroke="#ffffff"
                  stroke-width="6.5"
                  stroke-linecap="round"
                />
                <path
                  d="M-10 92 L290 80 M-10 154 L290 140 M108 -10 L98 266 M186 -10 L176 266"
                  stroke="#ffffff"
                  stroke-width="2.5"
                  stroke-linecap="round"
                  opacity="0.85"
                />

                <!-- Route halo & Motion-drawn route polyline -->
                <motion.path
                  d="M66 76 C98 78, 124 94, 144 128 C160 154, 180 174, 210 180"
                  stroke="#090d16"
                  stroke-opacity="0.09"
                  stroke-width="10"
                  stroke-linecap="round"
                  :initial="{ pathLength: 0 }"
                  :animate="{ pathLength: 1 }"
                  :transition="{ duration: 0.9, delay: 0.35, ease: EASE }"
                />
                <motion.path
                  d="M66 76 C98 78, 124 94, 144 128 C160 154, 180 174, 210 180"
                  stroke="#090d16"
                  stroke-width="2.75"
                  stroke-linecap="round"
                  :initial="{ pathLength: 0 }"
                  :animate="{ pathLength: 1 }"
                  :transition="{ duration: 0.9, delay: 0.35, ease: EASE }"
                />

                <!-- Nearby available Taxicle markers -->
                <circle cx="118" cy="70" r="4.5" fill="#090d16" stroke="#ffffff" stroke-width="2" />
                <circle
                  cx="174"
                  cy="116"
                  r="4.5"
                  fill="#090d16"
                  stroke="#ffffff"
                  stroke-width="2"
                />
                <circle
                  cx="100"
                  cy="160"
                  r="4"
                  fill="#52525b"
                  stroke="#ffffff"
                  stroke-width="1.8"
                />

                <!-- Pickup marker -->
                <circle cx="66" cy="76" r="6" fill="#ffffff" stroke="#090d16" stroke-width="3" />

                <!-- Destination marker with subtle Motion pulse -->
                <motion.circle
                  cx="210"
                  cy="180"
                  r="13"
                  fill="#059669"
                  :initial="{ scale: 0.85, opacity: 0.14 }"
                  :animate="{ scale: [0.85, 1.15, 0.85], opacity: [0.14, 0.28, 0.14] }"
                  :transition="{ duration: 2.8, repeat: Infinity, ease: 'easeInOut' }"
                />
                <circle
                  cx="210"
                  cy="180"
                  r="6"
                  fill="#059669"
                  stroke="#ffffff"
                  stroke-width="2.5"
                />
              </svg>

              <!-- Floating location labels -->
              <motion.div
                :initial="{ opacity: 0, y: 6 }"
                :animate="{ opacity: 1, y: 0 }"
                :transition="{ duration: 0.45, delay: 0.3, ease: EASE }"
                class="absolute top-6 left-4 inline-flex items-center gap-1.5 rounded-full bg-white/95 px-2.5 py-1 text-[10px] font-semibold text-neutral-800 shadow-[0_4px_12px_rgba(9,13,22,0.08)] ring-1 ring-black/6 backdrop-blur-xs"
              >
                <span class="h-1.5 w-1.5 rounded-full border border-neutral-950 bg-white" />
                <span>Agora Public Market</span>
              </motion.div>

              <motion.div
                :initial="{ opacity: 0, y: 6 }"
                :animate="{ opacity: 1, y: 0 }"
                :transition="{ duration: 0.45, delay: 0.45, ease: EASE }"
                class="absolute right-4 bottom-5 inline-flex items-center gap-1.5 rounded-full bg-neutral-950 px-2.5 py-1 text-[10px] font-semibold text-white shadow-[0_6px_16px_rgba(9,13,22,0.2)]"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                <span>Dao Capitol</span>
              </motion.div>
            </div>

            <!-- Crisp ride sheet -->
            <div
              class="relative -mt-3 rounded-t-[1.5rem] bg-white px-4 pt-2.5 pb-4 shadow-[0_-10px_28px_-12px_rgba(9,13,22,0.12)]"
            >
              <div class="mx-auto mb-3 h-1 w-8 rounded-full bg-neutral-200" />

              <div class="flex items-center justify-between text-[11px] text-neutral-500">
                <span class="inline-flex items-center gap-1.5 font-medium text-neutral-700">
                  <span class="h-1.5 w-1.5 rounded-full bg-emerald-600" />
                  3 drivers nearby
                </span>
                <span class="tabular-nums">~3 min away</span>
              </div>

              <div
                class="mt-3 flex items-center justify-between rounded-xl border border-neutral-200/80 bg-neutral-50/75 px-3.5 py-2.5"
              >
                <div>
                  <p class="text-xs font-bold text-neutral-950">Standard</p>
                  <p class="text-[11px] tabular-nums text-neutral-500">3.4 km · 11 min</p>
                </div>

                <span class="text-lg font-bold tracking-tight tabular-nums text-neutral-950">
                  ₱61
                </span>
              </div>

              <div
                class="mt-3 rounded-xl bg-neutral-950 py-2.5 text-center text-xs font-semibold text-white shadow-[0_4px_12px_-4px_rgba(9,13,22,0.35)]"
              >
                Book Ride
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  </section>
</template>
