import tailwindcss from '@tailwindcss/vite'

const siteUrl = 'https://gwitko.conduit.dev'

export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  devtools: { enabled: true },
  ssr: true,

  modules: ['@nuxtjs/i18n'],

  i18n: {
    strategy: 'prefix_except_default',
    defaultLocale: 'en',
    langDir: 'locales',
    vueI18n: './i18n.config.ts',
    lazy: true,
    baseUrl: siteUrl,
    detectBrowserLanguage: false,
    locales: [
      { code: 'en', language: 'en-US', name: 'English', file: 'en.json' },
      { code: 'zh', language: 'zh-CN', name: '中文', file: 'zh.json' },
    ],
  },

  nitro: {
    preset: 'static',
    prerender: {
      crawlLinks: true,
      routes: ['/', '/zh'],
    },
  },

  app: {
    baseURL: '/',
    head: {
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/conduit-mark.svg' },
      ],
      meta: [
        { name: 'theme-color', content: '#0c0c14' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      ],
    },
  },

  css: [
    '@fontsource-variable/hanken-grotesk',
    '~/assets/css/main.css',
  ],

  vite: {
    plugins: [tailwindcss()],
  },

  runtimeConfig: {
    public: { siteUrl },
  },
})
