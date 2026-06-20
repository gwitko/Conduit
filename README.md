# Conduit: SSH, Mosh & SFTP

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

A modern, privacy-focused SSH, Mosh, and SFTP client for Android and iOS.

Conduit is for reaching real machines from your phone without signing into
anything. Hosts, keys, and trusted fingerprints stay on the device - no account,
no cloud sync, no subscription. Open a normal SSH shell, or a Mosh session that
rides out Wi-Fi drops and cellular handoffs instead of dying with them. Sessions
live in tabs, with on-screen modifier, arrow, and function keys for the things a
phone keyboard doesn't have.

There's an SFTP browser for moving files around, host-key trust you manage
yourself, an optional device-auth app lock, and a stack of built-in terminal
themes (Catppuccin, Tokyo Night, Gruvbox, Nord, etc.). E-ink device support is coming!

Mosh runs on [dart_mosh](https://github.com/gwitko/dart_mosh), a clean-room
Dart implementation of the protocol, and the terminal is
[conduit_vt](https://github.com/gwitko/conduit_vt), a fork of xterm.dart.

## Features

- SSH terminal sessions with saved machine profiles and tabbed workspaces.
- Mosh sessions for roaming across Wi-Fi drops and network changes.
- SFTP browser for navigating, downloading, uploading, renaming, and deleting files.
- OpenSSH private key, password, and hardware security key authentication.
- OpenSSH FIDO security-key auth for `ed25519-sk` and `ecdsa-sk` credentials,
  tested with YubiKey and designed for CTAP-compatible keys.
- Android hardware-key auth over USB or NFC; iOS hardware-key auth over NFC.
- Optional per-host SSH agent forwarding for private-key and hardware-key auth,
  so a remote host can use your key to reach further hosts; forwarded hardware
  keys still require a touch for every onward signature.
- Trusted host key management with explicit fingerprint review.
- On-screen terminal controls for modifiers, arrows, function keys, and common shell input.
- Optional device-auth app lock for protecting saved machines and credentials.
- Built-in terminal themes, font sizing, palette choices, and appearance controls.
- Local-first storage: no account, no cloud sync, no subscription.

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

