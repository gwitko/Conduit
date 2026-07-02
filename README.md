# Conduit: Terminal, SSH, Mosh & SFTP

[![Latest release](https://img.shields.io/github/v/release/gwitko/Conduit)](https://github.com/gwitko/Conduit/releases/latest)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-2ea44f)
[![App Store](https://img.shields.io/badge/App%20Store-Conduit-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/app/id6780054869)
[![F-Droid](https://img.shields.io/f-droid/v/com.gwitko.conduit?label=F-Droid&logo=fdroid)](https://f-droid.org/packages/com.gwitko.conduit/)
[![Obtainium](https://img.shields.io/badge/Obtainium-GitHub%20releases-6f42c1)](https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/gwitko/Conduit)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20Conduit-ff5f5f?logo=kofi&logoColor=white)](https://ko-fi.com/gwitko)
[![Stars](https://img.shields.io/github/stars/gwitko/Conduit)](https://github.com/gwitko/Conduit/stargazers)

> [!CAUTION]
> Android is on track to become a locked-down platform. [Help keep it open](https://keepandroidopen.org).

Conduit's own source code is Apache-2.0. Android builds that include the local
shell also redistribute third-party binaries under their own licenses; see
[Acknowledgements](#acknowledgements) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Conduit is for reaching real machines from your phone without signing into
anything. Hosts, keys, and trusted fingerprints stay on the device - no account,
no cloud sync, no subscription. Open a normal SSH shell, or a Mosh session that
rides out Wi-Fi drops and cellular handoffs instead of dying with them. Sessions
live in tabs, with on-screen modifier, arrow, and function keys for the things a
phone keyboard doesn't have. Per-host tmux integration can attach or create a
session on connect, choose the start directory, and expose tmux prefix, action,
and scrollback controls from the key row.

On Android arm64, Conduit can also run an optional local Arch Linux shell
through `proot`. It downloads an Arch Linux ARM image on first use and opens it
like any other terminal tab.

There's an SFTP browser for moving files around, host-key trust you manage
yourself, an optional device-auth app lock, and a stack of built-in terminal
themes (Catppuccin, Tokyo Night, Gruvbox, Nord, etc.). E-ink device support is
coming!

Mosh runs on [dart_mosh](https://github.com/gwitko/dart_mosh), a clean-room
Dart implementation of the protocol, and the terminal is
[conduit_vt](https://github.com/gwitko/conduit_vt), a fork of xterm.dart.

## Features

- SSH terminal sessions with saved machine profiles, tag and search filters,
  sorting by last connected, name, or date added, and tabbed workspaces.
- Mosh sessions for roaming across Wi-Fi drops and network changes.
- Per-host tmux integration with auto attach/create, start directories, prefix
  key selection, action shortcuts, and scrollback mode.
- SFTP browser for navigating, downloading, uploading, renaming, and deleting files.
- OpenSSH private key, password, hardware security key, and external
  (server-driven) authentication.
- Import private keys from a file or generate an `ed25519` key on device, with
  optional passphrase encryption and one-tap public-key copy and export.
- OpenSSH FIDO security-key auth for `ed25519-sk` and `ecdsa-sk` credentials,
  tested with YubiKey and designed for CTAP-compatible keys.
- Android hardware-key auth over USB or NFC; iOS hardware-key auth over NFC.
  Register multiple hardware keys per host and Conduit tries each until one matches.
- Optional per-host SSH agent forwarding for private-key and hardware-key auth,
  so a remote host can use your key to reach further hosts; forwarded hardware
  keys still require a touch for every onward signature.
- Trusted host key management with explicit fingerprint review.
- Customizable on-screen key row with modifiers, arrows, function keys, key
  repeat, latching modifiers, and your own text snippets and control-key combos.
- Optional device-auth app lock for protecting saved machines and credentials.
- Built-in terminal themes, font sizing, palette choices, and appearance controls.
- On-device **local Arch Linux shell** (Android, arm64) with `pacman`, running
  unprivileged via `proot` - no root, no server. Uses Termux-packaged tooling.
- Local-first storage: no account, no cloud sync, no subscription.

## Acknowledgements

The local shell uses Android builds of open-source tools maintained and packaged
by the [Termux](https://termux.dev) project:

- **[proot](https://github.com/termux/proot)** - the userspace
  `chroot`/`ptrace` engine used for the unprivileged Linux userland.
- The **Arch Linux ARM** root filesystem, distributed via Termux's
  **[proot-distro](https://github.com/termux/proot-distro)**. Arch Linux ARM
  itself is maintained by the [Arch Linux ARM](https://archlinuxarm.org) project.
- `busybox`, GNU `tar`, `xz`/`liblzma`, `libtalloc`, and the `libandroid-*`
  shims.

If the local shell is useful to you, consider supporting
[Termux](https://github.com/sponsors/termux),
[GNU/FSF](https://www.fsf.org/about/ways-to-donate), or
[Arch Linux ARM](https://archlinuxarm.org/about/donate).

Conduit redistributes these components under their own licenses and provides a
corresponding source offer for GPL/LGPL components. The component list, license
texts, upstream source archives, exact package checksums, and pinned source
recipe snapshot are in
**[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)**. GPL/LGPL source-offer
details live in
**[third_party/source-offer](third_party/source-offer)**.

Conduit's own source code is licensed [Apache-2.0](LICENSE). Bundled
third-party binaries and downloaded rootfs packages are not relicensed by
Conduit. Mosh runs on
[dart_mosh](https://github.com/gwitko/dart_mosh) and the terminal is
[conduit_vt](https://github.com/gwitko/conduit_vt), a fork of xterm.dart.

## Contributors

Conduit is improved by community contributions. See [CONTRIBUTORS.md](CONTRIBUTORS.md)
for acknowledgements.

## Screenshots

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/01-terminal-nvim.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/02-theme.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/03-appearance.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/04-sftp.png" width="200">
</p>
<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/05-machines.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/06-terminal-btop.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/07-terminal-claude-code.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/08-terminal-codex.png" width="200">
</p>
<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/09-terminal-unimatrix.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/10-new-machine.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/11-hardware-key.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/12-mosh-settings.png" width="200">
</p>
