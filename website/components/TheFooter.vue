<script setup lang="ts">
const { t } = useI18n()
const stores = useStores()

const repoUrl = 'https://github.com/gwitko/Conduit'
const kofiUrl = 'https://ko-fi.com/gwitko'
const year = new Date().getFullYear()

const productLinks = [
  { key: 'nav.features', href: '#features' },
  { key: 'nav.security', href: '#security' },
  { key: 'nav.openSource', href: '#open-source' },
]

const projectLinks = [
  { key: 'footer.links.source', href: repoUrl },
  { key: 'footer.links.issues', href: `${repoUrl}/issues` },
  { key: 'footer.links.changelog', href: `${repoUrl}/releases` },
  { key: 'footer.links.support', href: kofiUrl },
]
</script>

<template>
  <footer class="border-t border-hairline">
    <div class="container-page grid gap-10 py-14 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
      <div class="max-w-xs">
        <SiteLogo />
        <p class="mt-4 text-sm leading-relaxed text-ink-muted">
          {{ t('footer.tagline') }}
        </p>
      </div>

      <div>
        <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-faint">
          {{ t('footer.columns.product') }}
        </h3>
        <ul class="mt-4 space-y-3">
          <li v-for="link in productLinks" :key="link.key">
            <a :href="link.href" class="text-sm text-ink-muted transition-colors hover:text-ink">
              {{ t(link.key) }}
            </a>
          </li>
        </ul>
      </div>

      <div>
        <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-faint">
          {{ t('footer.columns.project') }}
        </h3>
        <ul class="mt-4 space-y-3">
          <li v-for="link in projectLinks" :key="link.key">
            <a :href="link.href" rel="noopener" class="text-sm text-ink-muted transition-colors hover:text-ink">
              {{ t(link.key) }}
            </a>
          </li>
        </ul>
      </div>

      <div>
        <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-faint">
          {{ t('footer.columns.install') }}
        </h3>
        <ul class="mt-4 space-y-3">
          <li v-for="store in stores" :key="store.name">
            <a :href="store.href" rel="noopener" class="text-sm text-ink-muted transition-colors hover:text-ink">
              {{ store.name }}
            </a>
          </li>
        </ul>
      </div>
    </div>

    <div class="border-t border-hairline">
      <div
        class="container-page flex flex-col items-start justify-between gap-4 py-6 text-xs text-ink-faint sm:flex-row sm:items-center"
      >
        <span>{{ t('footer.copyright', { year }) }}</span>
        <div class="flex items-center gap-4">
          <LanguageSwitcher />
          <span class="font-mono">gwitko.conduit.dev</span>
        </div>
      </div>
    </div>
  </footer>
</template>
