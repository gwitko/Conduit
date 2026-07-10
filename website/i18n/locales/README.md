# Translations

All user-facing copy lives here as JSON. Components never hardcode strings, so
translating the site means editing these files only.

- `en.json` — English source. This is the canonical file. When copy changes,
  it changes here first.
- `zh.json` — Chinese (`zh-CN`). **Currently a verbatim copy of the English
  source, awaiting professional translation.** Translate the *values*, never the
  keys, and keep the structure identical to `en.json`.

## Notes for the translator

- Translate values only. Keys (the left-hand side) must stay exactly as-is.
- Leave these untranslated where they appear: `Conduit`, `SSH`, `Mosh`, `SFTP`,
  `tmux`, `nvim`, `btop`, `Claude Code`, `Codex`, `YubiKey`, `FIDO2`, `Arch
  Linux`, `pacman`, `App Store`, `Google Play`, `F-Droid`, `Obtainium`, `Ko-fi`, `GitHub`, and
  the theme names (`Catppuccin`, `Tokyo Night`, etc.).
- `footer.copyright` contains a `{year}` placeholder. Keep it exactly, in the
  right spot for the sentence.
- Arrays (for example `hero.trust` and each feature's `points`) must keep the
  same number of items and order.
- `meta.title` and `meta.description` are for SEO. Keep the title under about 60
  characters and the description under about 155 where the language allows.

## Missing keys

If a key is missing from `zh.json`, the site falls back to English for that
string, so a partial translation is safe to ship.
