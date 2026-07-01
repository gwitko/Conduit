<script setup lang="ts">
withDefaults(
  defineProps<{
    src?: string
    video?: string
    poster?: string
    alt?: string
    loading?: 'lazy' | 'eager'
  }>(),
  { loading: 'lazy' },
)
</script>

<template>
  <div class="relative w-full max-w-[300px]">
    <div
      class="absolute -inset-6 -z-10 rounded-[3rem] bg-mauve/10 blur-3xl"
      aria-hidden="true"
    />
    <div
      class="rounded-[2.6rem] border border-white/10 bg-[#050509] p-2.5 shadow-frame ring-1 ring-black/60"
    >
      <div
        class="relative overflow-hidden rounded-[2.1rem] bg-canvas ring-1 ring-white/5"
      >
        <video
          v-if="video"
          class="block aspect-[9/19.5] w-full object-cover"
          :poster="poster"
          autoplay
          muted
          loop
          playsinline
        >
          <source :src="video" type="video/mp4" />
        </video>
        <img
          v-else-if="src"
          :src="src"
          :alt="alt ?? ''"
          :loading="loading"
          class="block aspect-[9/19.5] w-full object-cover"
          decoding="async"
        />
        <div
          v-else
          class="aspect-[9/19.5] w-full bg-canvas"
          aria-hidden="true"
        />
      </div>
    </div>
  </div>
</template>
