export interface StoreLink {
  name: string
  caption: string
  href: string
  icon: 'apple' | 'fdroid' | 'obtainium'
  accent: string
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
    },
    {
      name: 'F-Droid',
      caption: t('stores.captions.fdroid'),
      href: 'https://f-droid.org/packages/com.gwitko.conduit/',
      icon: 'fdroid',
      accent: 'text-mint',
    },
    {
      name: 'Obtainium',
      caption: t('stores.captions.obtainium'),
      href: 'https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/gwitko/Conduit',
      icon: 'obtainium',
      accent: 'text-mauve',
    },
  ])
}
