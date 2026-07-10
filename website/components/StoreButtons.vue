<script setup lang="ts">
const stores = useStores()
</script>

<template>
  <div class="grid w-fit grid-cols-2 gap-3">
    <a
      v-for="store in stores"
      :key="store.name"
      :href="store.href"
      rel="noopener"
      class="transition-opacity hover:opacity-80"
    >
      <img
        :src="store.badge"
        :alt="`${store.caption} ${store.name}`"
        class="h-12 w-auto"
        loading="lazy"
      >
    </a>
  </div>
</template>
