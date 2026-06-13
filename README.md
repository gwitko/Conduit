# Conduit

[![Latest release](https://img.shields.io/github/v/release/gwitko/Conduit)](https://github.com/gwitko/Conduit/releases/latest)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-2ea44f)
[![F-Droid](https://img.shields.io/f-droid/v/com.gwitko.conduit?label=F-Droid&logo=fdroid)](https://f-droid.org/packages/com.gwitko.conduit/)
[![Stars](https://img.shields.io/github/stars/gwitko/Conduit)](https://github.com/gwitko/Conduit/stargazers)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20Conduit-ff5f5f?logo=kofi&logoColor=white)](https://ko-fi.com/gwitko)

A local-first SSH, Mosh, and SFTP client for Android and iOS.

Conduit is for reaching real machines from your phone without signing into
anything. Hosts, keys, and trusted fingerprints stay on the device - no account,
no cloud sync, no subscription. Open a normal SSH shell, or a Mosh session that
rides out Wi-Fi drops and cellular handoffs instead of dying with them. Sessions
live in tabs, with on-screen modifier, arrow, and function keys for the things a
phone keyboard doesn't have.

There's an SFTP browser for moving files around, host-key trust you manage
yourself, an optional device-auth app lock, and a stack of built-in terminal
themes (Catppuccin, Tokyo Night, Gruvbox, Nord, and the usual suspects).

Mosh is still experimental. It runs on
[dart_mosh](https://github.com/gwitko/dart_mosh), a clean-room Dart
implementation of the protocol, and the terminal is
[conduit_vt](https://github.com/gwitko/conduit_vt), a fork of xterm.dart.

## Screenshots

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/05-machines.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/01-terminal-nvim.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/06-terminal-btop.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/07-terminal-claude-code.png" width="200">
</p>
<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/08-terminal-codex.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/09-terminal-unimatrix.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/04-sftp.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/03-appearance.png" width="200">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/02-theme.png" width="200">
</p>
