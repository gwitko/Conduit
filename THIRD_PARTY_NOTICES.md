# Third-party notices

Conduit's own source code is licensed under Apache-2.0. This file covers
third-party components that are redistributed with Android builds of Conduit and
remain under their own licenses.

Conduit bundles prebuilt native binaries to provide the on-device local Arch
Linux shell. They live in `android/app/src/main/jniLibs/arm64-v8a/` (renamed to
`lib*.so` so Android packages and extracts them) and are obtained from the
[Termux](https://github.com/termux) package repository, which builds them for
Android's bionic libc.

GPL/LGPL license texts are included under
[`third_party/licenses`](third_party/licenses). Component-specific notices for
permissive/public-domain components are included under
[`third_party/notices`](third_party/notices). GPL/LGPL corresponding-source
details, exact upstream source archives, exact Termux package checksums, pinned
Termux package recipes, and the Conduit-side binary rewrite notes are included under
[`third_party/source-offer`](third_party/source-offer).

| File in jniLibs | Upstream package | Version | License / notice |
| --- | --- | --- | --- |
| `libproot.so`, `libproot_loader.so` | [proot](https://github.com/termux/proot) | 5.1.107.81 | [`GPL-2.0-only`](third_party/licenses/GPL-2.0-only.txt) |
| `libtarbin.so` | [GNU tar](https://www.gnu.org/software/tar/) | 1.35-2 | [`GPL-3.0-or-later`](third_party/licenses/GPL-3.0-or-later.txt) |
| `liblzma.so` | [liblzma](https://tukaani.org/xz/) | 5.8.3 | [`0BSD`](third_party/notices/xz.txt) |
| `libxzbin.so` | [xz-utils](https://tukaani.org/xz/) | 5.8.3 | [`0BSD`](third_party/notices/xz.txt) |
| `libbusyboxbin.so`, `libbusybox.so` | [busybox](https://busybox.net) | 1.38.0-1 | [`GPL-2.0-only`](third_party/licenses/GPL-2.0-only.txt) |
| `libtalloc.so` | [libtalloc](https://talloc.samba.org) | 2.4.3 | [`LGPL-3.0-or-later`](third_party/licenses/LGPL-3.0-or-later.txt) |
| `libandroid-shmem.so` | [libandroid-shmem](https://github.com/termux/libandroid-shmem) | 0.7 | [`libandroid-shmem notice`](third_party/notices/libandroid-shmem.txt) |
| `libandroid-selinux.so` | libandroid-selinux (AOSP libselinux port) | 14.0.0.11-1 | [`libandroid-selinux notice`](third_party/notices/libandroid-selinux.txt) |
| `libpcre2-8.so` | [PCRE2](https://github.com/PCRE2Project/pcre2) | 10.47 | [`PCRE2 notice`](third_party/notices/pcre2.txt) |
| `libacl.so`, `libattr.so` | acl/attr (GNU tar deps) | 2.5.2-1 | [`LGPL-2.1-or-later`](third_party/licenses/LGPL-2.1-or-later.txt) |
| `libiconv.so`, `libcharset.so` | [GNU libiconv](https://www.gnu.org/software/libiconv/) | 1.18-1 | [`LGPL-2.1-or-later`](third_party/licenses/LGPL-2.1-or-later.txt) |
| `libandroid-glob.so` | libandroid-glob (Termux package) | 0.6-3 | [`libandroid-glob notice`](third_party/notices/libandroid-glob.txt) |

The root filesystem downloaded at runtime is an **Arch Linux ARM** (aarch64)
image distributed by Termux's
[proot-distro](https://github.com/termux/proot-distro) as a GitHub release
asset. Arch Linux ARM itself is maintained by the
[Arch Linux ARM](https://archlinuxarm.org) project; its packages carry their own
respective licenses. Conduit downloads this image to the device on first use and
does not redistribute it inside the app package.

## GPL/LGPL source offer

`proot` and `busybox` are GPL-2.0, GNU `tar` is GPL-3.0-or-later, and several
support libraries are LGPL. If you distribute Conduit with these binaries, make
the corresponding source available for the exact versions shipped. Conduit's
source-offer index is in
[`third_party/source-offer/README.md`](third_party/source-offer/README.md).

**Written offer.** This is a written offer, valid for at least three years from
the date Conduit distributes these binaries, to give any third party — for a
charge no more than the cost of physically performing source distribution — a
complete machine-readable copy of the corresponding source for the GPL- and
LGPL-licensed binaries listed above, for the exact versions shipped. The
corresponding source is published at <https://github.com/gwitko/Conduit> under
[`third_party/source-offer`](third_party/source-offer); requests may also be
sent to the repository maintainer there. For the GPL-3.0 component (GNU `tar`)
this offer is additionally satisfied by access to the same Corresponding Source
from that network server at no charge (GPL-3.0 §6(d)).

Conduit includes a snapshot of the relevant Termux build recipes and patches at
[`third_party/source-offer/termux-recipes`](third_party/source-offer/termux-recipes),
pinned to Termux `termux-packages` commit
`ac296452b8ebec390cad3bce9060577c96099b10`. Conduit makes no source-code
changes to those projects. The only Conduit-side binary change is an in-place
rewrite of two `DT_NEEDED`/`SONAME` strings
(`libtalloc.so.2` -> `libtalloc.so`, `libbusybox.so.1.38.0` -> `libbusybox.so`)
so the libraries resolve under Android's `lib*.so`-only extraction. See the
source-offer index for the exact transformation and verification command.
