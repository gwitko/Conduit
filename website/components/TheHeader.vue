<script setup lang="ts">
const { t } = useI18n()
const repoUrl = 'https://github.com/gwitko/Conduit'
const stores = useStores()

const links = [
  { key: 'nav.features', href: '#features' },
  { key: 'nav.security', href: '#security' },
  { key: 'nav.openSource', href: '#open-source' },
]

const open = ref(false)
const storeOpen = ref(false)
</script>

<template>
  <header
    class="sticky top-0 z-50 border-b border-hairline bg-canvas/80 backdrop-blur-md"
  >
    <div class="container-page flex h-16 items-center justify-between gap-6">
      <a href="#top" aria-label="Conduit home" @click="open = false">
        <SiteLogo />
      </a>

      <nav class="hidden items-center gap-8 md:flex">
        <a
          v-for="link in links"
          :key="link.href"
          :href="link.href"
          class="text-sm text-ink-muted transition-colors hover:text-ink"
        >
          {{ t(link.key) }}
        </a>
      </nav>

      <div class="hidden items-center gap-4 md:flex">
        <LanguageSwitcher />
        <a
          :href="repoUrl"
          rel="noopener"
          class="text-sm text-ink-muted transition-colors hover:text-ink"
        >
          {{ t('nav.github') }}
        </a>

        <div class="relative">
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-full bg-ink py-2 pl-4 pr-3 text-sm font-medium text-canvas transition-opacity hover:opacity-90"
            :aria-expanded="storeOpen"
            @click="storeOpen = !storeOpen"
          >
            {{ t('nav.getConduit') }}
            <svg viewBox="0 0 20 20" class="h-4 w-4 transition-transform" :class="storeOpen ? 'rotate-180' : ''" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M5 8l5 5 5-5" />
            </svg>
          </button>

          <div
            v-if="storeOpen"
            class="fixed inset-0 z-40"
            @click="storeOpen = false"
          />

          <Transition
            enter-active-class="transition duration-150 ease-out"
            enter-from-class="-translate-y-1 opacity-0"
            leave-active-class="transition duration-100 ease-in"
            leave-to-class="-translate-y-1 opacity-0"
          >
            <div
              v-if="storeOpen"
              class="absolute right-0 z-50 mt-2 w-64 overflow-hidden rounded-xl border border-border bg-panel-raised p-1.5 shadow-soft"
            >
              <a
                v-for="store in stores"
                :key="store.name"
                :href="store.href"
                rel="noopener"
                class="flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors hover:bg-panel"
                @click="storeOpen = false"
              >
                <StoreIcon :icon="store.icon" class="h-5 w-5 shrink-0" :class="store.accent" />
                <span class="leading-tight">
                  <span class="block text-[0.65rem] uppercase tracking-wide text-ink-faint">{{ store.caption }}</span>
                  <span class="block text-sm font-medium text-ink">{{ store.name }}</span>
                </span>
              </a>
            </div>
          </Transition>
        </div>
      </div>

      <button
        type="button"
        class="-mr-2 inline-flex h-10 w-10 items-center justify-center rounded-lg text-ink md:hidden"
        :aria-expanded="open"
        aria-label="Toggle menu"
        @click="open = !open"
      >
        <svg viewBox="0 0 24 24" class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
          <template v-if="!open">
            <path d="M4 7h16M4 12h16M4 17h16" />
          </template>
          <template v-else>
            <path d="M6 6l12 12M18 6L6 18" />
          </template>
        </svg>
      </button>
    </div>

    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="-translate-y-2 opacity-0"
      leave-active-class="transition duration-150 ease-in"
      leave-to-class="-translate-y-2 opacity-0"
    >
      <nav
        v-if="open"
        class="border-t border-hairline bg-canvas md:hidden"
      >
        <div class="container-page flex flex-col py-2">
          <a
            v-for="link in links"
            :key="link.href"
            :href="link.href"
            class="border-b border-hairline py-3.5 text-base text-ink-muted transition-colors hover:text-ink"
            @click="open = false"
          >
            {{ t(link.key) }}
          </a>
          <a
            :href="repoUrl"
            rel="noopener"
            class="border-b border-hairline py-3.5 text-base text-ink-muted transition-colors hover:text-ink"
            @click="open = false"
          >
            {{ t('nav.github') }}
          </a>

          <p class="pt-4 pb-2 text-xs font-medium uppercase tracking-wider text-ink-faint">
            {{ t('nav.getConduit') }}
          </p>
          <a
            v-for="store in stores"
            :key="store.name"
            :href="store.href"
            rel="noopener"
            class="mb-2 flex items-center gap-3 rounded-lg border border-border bg-panel px-3 py-3"
            @click="open = false"
          >
            <StoreIcon :icon="store.icon" class="h-5 w-5 shrink-0" :class="store.accent" />
            <span class="leading-tight">
              <span class="block text-[0.65rem] uppercase tracking-wide text-ink-faint">{{ store.caption }}</span>
              <span class="block text-sm font-medium text-ink">{{ store.name }}</span>
            </span>
          </a>

          <div class="mt-2 mb-2 flex justify-center border-t border-hairline pt-4">
            <LanguageSwitcher />
          </div>
        </div>
      </nav>
    </Transition>
  </header>
</template>
