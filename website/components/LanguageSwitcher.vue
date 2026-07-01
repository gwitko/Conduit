<script setup lang="ts">
const { locale, locales } = useI18n()
const switchLocalePath = useSwitchLocalePath()
</script>

<template>
  <div class="inline-flex items-center rounded-full border border-border p-0.5 text-xs">
    <NuxtLink
      v-for="l in locales"
      :key="l.code"
      :to="switchLocalePath(l.code)"
      class="rounded-full px-2.5 py-1 font-medium transition-colors"
      :class="l.code === locale ? 'bg-ink text-canvas' : 'text-ink-muted hover:text-ink'"
    >
      {{ l.name }}
    </NuxtLink>
  </div>
</template>
