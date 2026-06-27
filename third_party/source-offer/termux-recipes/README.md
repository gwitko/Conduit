# Termux recipe snapshot

This directory contains the Termux package recipes and patches relevant to the
native Android/aarch64 binaries redistributed by Conduit for the local shell.

Snapshot source:
<https://github.com/termux/termux-packages/tree/ac296452b8ebec390cad3bce9060577c96099b10>

Snapshot commit:
`ac296452b8ebec390cad3bce9060577c96099b10`

Included package directories:

- `packages/proot`
- `packages/busybox`
- `packages/tar`
- `packages/libtalloc`
- `packages/attr`
- `packages/libiconv`
- `packages/liblzma`
- `packages/libandroid-shmem`
- `packages/libandroid-selinux`
- `packages/libandroid-glob`
- `packages/pcre2`

`acl` is produced by `packages/attr`. `xz-utils` is produced by
`packages/liblzma/xz-utils.subpackage.sh`.

The package scripts and patches in `packages/` follow the licensing policy in
[`LICENSE.md`](LICENSE.md), copied from the Termux `termux-packages` repository.
