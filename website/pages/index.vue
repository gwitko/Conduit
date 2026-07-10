<script setup lang="ts">
const { t, tm, rt } = useI18n()
const localePath = useLocalePath()
const { public: { siteUrl } } = useRuntimeConfig()

const repoUrl = 'https://github.com/gwitko/Conduit'
const kofiUrl = 'https://ko-fi.com/gwitko'
const starsUrl = 'https://github.com/gwitko/Conduit/stargazers'
const heroCommand = '$ ssh you@anywhere'

useSeoMeta({
  title: () => t('meta.title'),
  description: () => t('meta.description'),
  ogTitle: () => t('meta.title'),
  ogDescription: () => t('meta.description'),
  ogType: 'website',
  ogUrl: () => `${siteUrl}${localePath('/')}`,
  ogSiteName: 'Conduit',
  twitterCard: 'summary',
  twitterTitle: () => t('meta.title'),
  twitterDescription: () => t('meta.description'),
})

useHead(() => ({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'SoftwareApplication',
        name: 'Conduit',
        applicationCategory: 'DeveloperApplication',
        operatingSystem: 'Android, iOS',
        description: t('meta.description'),
        url: `${siteUrl}/`,
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
        author: { '@type': 'Person', name: 'gwitko' },
      }),
    },
  ],
}))

const features = [
  { id: 'ssh-mosh', image: '/images/ssh-mosh.png' },
  { id: 'ai-agents', image: '/images/ai-agents.png' },
  { id: 'fleet', image: '/images/fleet.png' },
  { id: 'tmux', image: '/images/tmux.png' },
  { id: 'nvim', image: '/images/nvim.png' },
  { id: 'key-row', image: '/images/key-row.png' },
  { id: 'sftp', image: '/images/sftp.png' },
  { id: 'themes', image: '/images/themes.png' },
  { id: 'local-shell', image: '/images/local-shell.png' },
]

const stats = [
  { value: '100%', key: 'openSource.stats.source' },
  { value: '0', key: 'openSource.stats.trackers' },
  { value: '4', key: 'openSource.stats.install' },
]

const trust = computed(() => tm('hero.trust') as unknown as string[])
</script>

<template>
  <div>
    <section class="relative overflow-hidden">
      <div
        class="pointer-events-none absolute inset-x-0 -top-40 -z-10 h-[420px] bg-[radial-gradient(60%_100%_at_50%_0%,rgba(203,166,247,0.14),transparent_70%)]"
        aria-hidden="true"
      />
      <div
        class="container-page grid items-center gap-10 py-16 sm:py-20 lg:grid-cols-[1.05fr_0.95fr] lg:gap-14 lg:py-28"
      >
        <div>
          <p class="font-mono text-sm text-mauve">{{ heroCommand }}</p>
          <h1 class="mt-5 text-4xl font-medium leading-[1.04] text-ink sm:text-5xl lg:text-[3.75rem]">
            {{ t('hero.title') }}
          </h1>
          <p class="mt-6 max-w-xl text-lg leading-relaxed text-ink-muted">
            {{ t('hero.body') }}
          </p>

          <div class="mt-8">
            <StoreButtons />
          </div>

          <ul class="mt-8 flex flex-wrap items-center gap-x-3 gap-y-2 text-sm text-ink-faint sm:gap-x-4">
            <li v-for="(item, i) in trust" :key="i" class="flex items-center gap-3 sm:gap-4">
              <span>{{ rt(item) }}</span>
              <span v-if="i < trust.length - 1" class="text-border">/</span>
            </li>
          </ul>
        </div>

        <div class="flex justify-center lg:justify-end">
          <PhoneFrame
            src="/images/hero.png"
            :alt="t('features.items.ai-agents.alt')"
            loading="eager"
          />
        </div>
      </div>
    </section>

    <section id="features" class="scroll-mt-20">
      <div class="container-page border-t border-hairline py-8">
        <p class="max-w-2xl text-lg text-ink-muted">
          {{ t('features.intro') }}
        </p>
      </div>

      <div
        v-for="(feature, index) in features"
        :id="feature.id"
        :key="feature.id"
        class="container-page grid items-center gap-10 border-t border-hairline py-16 lg:grid-cols-2 lg:gap-12 lg:py-24"
      >
        <div :class="index % 2 === 0 ? 'lg:order-2' : ''">
          <p class="kicker">{{ t(`features.items.${feature.id}.eyebrow`) }}</p>
          <h2 class="mt-4 text-3xl font-semibold text-ink sm:text-4xl">
            {{ t(`features.items.${feature.id}.title`) }}
          </h2>
          <p class="mt-5 max-w-xl text-lg leading-relaxed text-ink-muted">
            {{ t(`features.items.${feature.id}.body`) }}
          </p>
          <ul class="mt-7 space-y-3">
            <li
              v-for="(point, i) in tm(`features.items.${feature.id}.points`)"
              :key="i"
              class="flex items-start gap-3 text-ink"
            >
              <svg viewBox="0 0 20 20" class="mt-1 h-4 w-4 shrink-0 text-mauve" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M16.7 5.3a1 1 0 0 1 0 1.4l-7.5 7.5a1 1 0 0 1-1.4 0L3.3 9.7a1 1 0 1 1 1.4-1.4l3.3 3.3 6.8-6.8a1 1 0 0 1 1.4 0z" clip-rule="evenodd" />
              </svg>
              <span class="text-[0.98rem] text-ink-muted">{{ rt(point) }}</span>
            </li>
          </ul>
        </div>

        <div
          class="flex justify-center"
          :class="index % 2 === 0 ? 'lg:order-1 lg:justify-start' : 'lg:justify-end'"
        >
          <PhoneFrame :src="feature.image" :alt="t(`features.items.${feature.id}.alt`)" />
        </div>
      </div>
    </section>

    <section id="security" class="scroll-mt-20">
      <div class="container-page grid items-center gap-10 border-t border-hairline py-16 lg:grid-cols-2 lg:gap-12 lg:py-24">
        <div>
          <p class="kicker">{{ t('security.eyebrow') }}</p>
          <h2 class="mt-4 text-3xl font-semibold text-ink sm:text-4xl">
            {{ t('security.title') }}
          </h2>
          <p class="mt-5 max-w-xl text-lg leading-relaxed text-ink-muted">
            {{ t('security.body') }}
          </p>
          <ul class="mt-7 space-y-3">
            <li
              v-for="(point, i) in tm('security.points')"
              :key="i"
              class="flex items-start gap-3 text-ink"
            >
              <svg viewBox="0 0 20 20" class="mt-1 h-4 w-4 shrink-0 text-mauve" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M16.7 5.3a1 1 0 0 1 0 1.4l-7.5 7.5a1 1 0 0 1-1.4 0L3.3 9.7a1 1 0 1 1 1.4-1.4l3.3 3.3 6.8-6.8a1 1 0 0 1 1.4 0z" clip-rule="evenodd" />
              </svg>
              <span class="text-[0.98rem] text-ink-muted">{{ rt(point) }}</span>
            </li>
          </ul>
        </div>

        <div class="flex justify-center lg:justify-end">
          <PhoneFrame
            src="/images/security.png"
            :alt="t('security.alt')"
          />
        </div>
      </div>
    </section>

    <section id="open-source" class="scroll-mt-20">
      <div class="container-page border-t border-hairline py-16 lg:py-24">
        <div class="max-w-2xl">
          <p class="kicker">{{ t('openSource.eyebrow') }}</p>
          <h2 class="mt-4 text-3xl font-semibold text-ink sm:text-4xl">
            {{ t('openSource.title') }}
          </h2>
          <p class="mt-5 text-lg leading-relaxed text-ink-muted">
            {{ t('openSource.body') }}
          </p>
        </div>

        <div class="mt-12 grid gap-8 sm:grid-cols-3">
          <div v-for="stat in stats" :key="stat.key">
            <p class="font-mono text-4xl text-ink">{{ stat.value }}</p>
            <p class="mt-2 text-sm text-ink-muted">{{ t(stat.key) }}</p>
          </div>
        </div>

        <div class="mt-12 flex flex-wrap items-center gap-x-6 gap-y-4">
          <a
            :href="repoUrl"
            rel="noopener"
            class="inline-flex items-center gap-2 text-sm font-medium text-mauve transition-colors hover:text-blush"
          >
            {{ t('openSource.readSource') }}
            <span aria-hidden="true">→</span>
          </a>
          <a
            :href="starsUrl"
            rel="noopener"
            class="inline-flex items-center gap-2 rounded-lg border border-border bg-panel px-4 py-2.5 text-sm text-ink transition-colors hover:border-mauve/50 hover:bg-panel-raised"
          >
            <svg viewBox="0 0 20 20" class="h-4 w-4 text-gold" fill="currentColor" aria-hidden="true">
              <path d="M10 1.5l2.6 5.27 5.82.85-4.21 4.1.99 5.79L10 15.77l-5.2 2.73.99-5.79L1.58 8.6l5.82-.85L10 1.5z" />
            </svg>
            {{ t('openSource.star') }}
          </a>
          <a
            :href="kofiUrl"
            rel="noopener"
            class="inline-flex items-center gap-2 rounded-lg border border-border bg-panel px-4 py-2.5 text-sm text-ink transition-colors hover:border-blush/50 hover:bg-panel-raised"
          >
            <svg viewBox="0 0 20 20" class="h-4 w-4 text-blush" fill="currentColor" aria-hidden="true">
              <path d="M10 17.5l-1.16-1.05C4.7 12.72 2 10.28 2 7.3 2 4.9 3.9 3 6.3 3c1.36 0 2.66.63 3.5 1.64A4.68 4.68 0 0113.7 3C16.1 3 18 4.9 18 7.3c0 2.98-2.7 5.42-6.84 9.16L10 17.5z" />
            </svg>
            {{ t('openSource.support') }}
          </a>
        </div>
      </div>
    </section>

    <section class="border-t border-hairline">
      <div class="container-page py-16 text-center lg:py-24">
        <h2 class="mx-auto max-w-2xl text-3xl font-semibold text-ink sm:text-4xl">
          {{ t('cta.title') }}
        </h2>
        <p class="mx-auto mt-5 max-w-xl text-lg text-ink-muted">
          {{ t('cta.body') }}
        </p>
        <div class="mt-8 flex justify-center">
          <StoreButtons />
        </div>
      </div>
    </section>
  </div>
</template>
