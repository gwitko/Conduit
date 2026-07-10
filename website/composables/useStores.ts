export interface StoreLink {
  name: string
  caption: string
  href: string
  icon: 'apple' | 'googleplay' | 'fdroid' | 'obtainium'
  accent: string
  badge: string
}

export function useStores(): ComputedRef<StoreLink[]> {
  const { t } = useI18n()

  return computed(() => [
    {
      name: 'App Store',
      caption: t('stores.captions.appStore'),
      href: 'https://apps.apple.com/app/id6780054869',
      icon: 'apple',
      accent: 'text-ink',
      badge: '/badges/app-store.svg',
    },
    {
      name: 'Google Play',
      caption: t('stores.captions.googlePlay'),
      href: 'https://play.google.com/store/apps/details?id=com.gwitko.conduit',
      icon: 'googleplay',
      accent: 'text-mint',
      badge: '/badges/google-play.png',
    },
    {
      name: 'F-Droid',
      caption: t('stores.captions.fdroid'),
      href: 'https://f-droid.org/packages/com.gwitko.conduit/',
      icon: 'fdroid',
      accent: 'text-mint',
      badge: '/badges/f-droid.png',
    },
    {
      name: 'Obtainium',
      caption: t('stores.captions.obtainium'),
      href: 'https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/gwitko/Conduit',
      icon: 'obtainium',
      accent: 'text-mauve',
      badge: '/badges/obtainium.png',
    },
  ])
}
