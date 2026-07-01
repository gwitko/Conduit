<script setup lang="ts">
const stores = useStores()
</script>

<template>
  <div class="flex flex-wrap items-center gap-3">
    <a
      v-for="store in stores"
      :key="store.name"
      :href="store.href"
      rel="noopener"
      class="group inline-flex items-center gap-3 rounded-xl border border-border bg-panel px-5 py-3 transition-colors hover:border-mauve/50 hover:bg-panel-raised"
    >
      <StoreIcon :icon="store.icon" class="h-6 w-6" :class="store.accent" />
      <span class="text-left leading-tight">
        <span class="block text-[0.65rem] uppercase tracking-wide text-ink-faint">{{ store.caption }}</span>
        <span class="block text-sm font-semibold text-ink">{{ store.name }}</span>
      </span>
    </a>
  </div>
</template>
