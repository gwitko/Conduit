<script setup lang="ts">
defineProps<{ icon: 'apple' | 'fdroid' | 'obtainium' }>()
</script>

<template>
  <svg
    v-if="icon === 'apple'"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
  >
    <path d="M16.365 1.43c0 1.14-.42 2.2-1.12 2.98-.79.9-2.06 1.6-3.14 1.51-.13-1.1.44-2.28 1.1-3.02.75-.86 2.09-1.5 3.16-1.47zM20.9 17.13c-.55 1.27-.82 1.83-1.53 2.95-1 1.56-2.4 3.5-4.15 3.52-1.55.02-1.95-1.01-4.05-1-2.1.01-2.54 1.02-4.09 1-1.75-.02-3.08-1.77-4.07-3.33C1.03 16.9.68 11.85 2.83 9.16c1-1.32 2.58-2.15 4.14-2.15 1.6 0 2.6 1.02 3.92 1.02 1.28 0 2.06-1.02 3.92-1.02 1.38 0 2.85.75 3.9 2.05-3.43 1.88-2.87 6.78.19 8.07z" />
  </svg>
  <svg
    v-else-if="icon === 'fdroid'"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
  >
    <path d="M12 2 3 7v10l9 5 9-5V7l-9-5zm0 2.3 6.8 3.78L12 11.86 5.2 8.08 12 4.3zM5 9.7l6 3.35v6.7L5 16.4V9.7zm14 0v6.7l-6 3.35v-6.7l6-3.35z" />
  </svg>
  <svg
    v-else
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.8"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path d="M12 3v11m0 0 4-4m-4 4-4-4" />
    <path d="M4 16v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3" />
  </svg>
</template>
