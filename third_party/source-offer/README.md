# Corresponding source offer for bundled local-shell binaries

Conduit bundles prebuilt Android/aarch64 binaries in
`android/app/src/main/jniLibs/arm64-v8a/` for the optional on-device local Arch
Linux shell. This directory records the source-offer information for those
binaries.

Conduit redistributes these binaries; it does not claim authorship of them. They
are built and packaged by the Termux project through the `termux-packages`
repository.

The bundled files and versions are listed in
[`../../THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md). GPL/LGPL license
texts and component-specific notices are in [`../licenses`](../licenses) and
[`../notices`](../notices).

The exact binaries currently shipped by this repository are identified by
[`bundled-binaries.sha256`](bundled-binaries.sha256).

The GPL/LGPL upstream source archives named by the pinned Termux recipes are
included in [`upstream-sources`](upstream-sources) and identified by
[`upstream-sources.sha256`](upstream-sources.sha256).

The exact Termux `.deb` packages used as source material are identified in
[`termux-package-checksums.md`](termux-package-checksums.md). The relevant
Termux package recipes and patches are snapshotted in
[`termux-recipes`](termux-recipes), pinned to upstream commit:

`ac296452b8ebec390cad3bce9060577c96099b10`

Original upstream repository:
<https://github.com/termux/termux-packages/tree/ac296452b8ebec390cad3bce9060577c96099b10>

## GPL / LGPL corresponding source

For GPL and LGPL components, the corresponding source is the local upstream
source archive plus the Termux package build recipe and patches for the exact
package version shipped by Conduit.

| Component | Bundled files | License | Source / build recipe |
| --- | --- | --- | --- |
| proot 5.1.107.81 | `libproot.so`, `libproot_loader.so` | GPL-2.0 | [`upstream-sources/proot-5.1.107.81.zip`](upstream-sources/proot-5.1.107.81.zip) and [`termux-recipes/packages/proot`](termux-recipes/packages/proot) |
| busybox 1.38.0-1 | `libbusyboxbin.so`, `libbusybox.so` | GPL-2.0 | [`upstream-sources/busybox-1.38.0.tar.bz2`](upstream-sources/busybox-1.38.0.tar.bz2) and [`termux-recipes/packages/busybox`](termux-recipes/packages/busybox) |
| GNU tar 1.35-2 | `libtarbin.so` | GPL-3.0-or-later | [`upstream-sources/tar-1.35.tar.xz`](upstream-sources/tar-1.35.tar.xz) and [`termux-recipes/packages/tar`](termux-recipes/packages/tar) |
| xz-utils / liblzma 5.8.3 | `libxzbin.so`, `liblzma.so` | 0BSD (the `xz` tool and liblzma are both 0BSD; only the GPL-2.0+ shell scripts in xz-utils, which are not bundled, are copyleft) | [`upstream-sources/xz-5.8.3.tar.xz`](upstream-sources/xz-5.8.3.tar.xz) and [`termux-recipes/packages/liblzma`](termux-recipes/packages/liblzma) |
| libtalloc 2.4.3 | `libtalloc.so` | LGPL-3.0-or-later | [`upstream-sources/talloc-2.4.3.tar.gz`](upstream-sources/talloc-2.4.3.tar.gz) and [`termux-recipes/packages/libtalloc`](termux-recipes/packages/libtalloc) |
| acl / attr 2.5.2-1 | `libacl.so`, `libattr.so` | LGPL-2.1-or-later | [`upstream-sources/attr-2.5.2.tar.gz`](upstream-sources/attr-2.5.2.tar.gz) and [`termux-recipes/packages/attr`](termux-recipes/packages/attr) |
| GNU libiconv 1.18-1 | `libiconv.so`, `libcharset.so` | LGPL-2.1-or-later | [`upstream-sources/libiconv-1.18.tar.gz`](upstream-sources/libiconv-1.18.tar.gz) and [`termux-recipes/packages/libiconv`](termux-recipes/packages/libiconv) |

For public release builds, do not replace any bundled `.so` without updating
`bundled-binaries.sha256`, `upstream-sources/*`, `upstream-sources.sha256`,
`termux-package-checksums.md`, `termux-recipes/packages/*`, this table, and
`THIRD_PARTY_NOTICES.md` in the same change.

## Conduit-side binary changes

Android only extracts native libraries named like `lib*.so` from `jniLibs`, so
Conduit renames executable files into that shape. Two dynamic-linker names were
also rewritten in place so the renamed files resolve from `nativeLibraryDir`:

- `libtalloc.so.2` -> `libtalloc.so`
- `libbusybox.so.1.38.0` -> `libbusybox.so`

The rewrite is a byte-preserving string replacement with trailing NUL padding;
the replacement strings are shorter than the originals. No source code changes
are made by Conduit.

The exact, reproducible transformation is the script
[`rewrite-soname.sh`](rewrite-soname.sh) in this directory. Run it from the repo
root after refreshing the binaries from the pinned Termux packages, then refresh
`bundled-binaries.sha256`:

```bash
third_party/source-offer/rewrite-soname.sh
sha256sum android/app/src/main/jniLibs/arm64-v8a/*.so \
  > third_party/source-offer/bundled-binaries.sha256
```

Verify the shipped binaries with either:

```bash
third_party/source-offer/rewrite-soname.sh --verify
# or, manually:
for f in android/app/src/main/jniLibs/arm64-v8a/*.so; do
  echo "== $f =="
  readelf -d "$f" | grep -E 'NEEDED|SONAME'
done
```

## Root filesystem

The Arch Linux ARM root filesystem is not bundled in the APK. It is downloaded
on first use from the pinned URL and SHA-256 in
`lib/features/local_shell/local_shell_config.dart`. It is distributed via
Termux's `proot-distro` release assets and maintained by Arch Linux ARM.
