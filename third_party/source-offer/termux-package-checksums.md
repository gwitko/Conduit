# Termux package checksums

These records identify the exact Termux Android/aarch64 `.deb` packages used as
the source material for Conduit's bundled local-shell binaries. The records were
copied from the Termux `stable/main/binary-aarch64/Packages` index on
2026-06-27.

Termux package recipes and patches for these packages are snapshotted in
[`termux-recipes`](termux-recipes), pinned to `termux-packages` commit
`ac296452b8ebec390cad3bce9060577c96099b10`.

| Package | Version | Filename | SHA-256 |
| --- | --- | --- | --- |
| `attr` | `2.5.2-1` | `pool/main/a/attr/attr_2.5.2-1_aarch64.deb` | `f81bb14a1ded6c0857b9af94937d68bb2d64ec6c9fb31f3da8c646e54c68dd72` |
| `busybox` | `1.38.0-1` | `pool/main/b/busybox/busybox_1.38.0-1_aarch64.deb` | `1bb7f1d4c00cadd0e1117b6dd7110311b8bf749ef00b486e96cfdc11c98f8fd9` |
| `libandroid-glob` | `0.6-3` | `pool/main/liba/libandroid-glob/libandroid-glob_0.6-3_aarch64.deb` | `2276ae8adedf0db76c2f4ffc94cc4cceb2f4f5d78e021b54e2e046d1233e7826` |
| `libandroid-selinux` | `14.0.0.11-1` | `pool/main/liba/libandroid-selinux/libandroid-selinux_14.0.0.11-1_aarch64.deb` | `00afd8c34087c2864737b51fd9d104dc5e955f6ec3c0f50c0c7ef5b4a56866b9` |
| `libandroid-shmem` | `0.7` | `pool/main/liba/libandroid-shmem/libandroid-shmem_0.7_aarch64.deb` | `0da3a24d558b93c92bcf8d611e0826a99ff96e396b148e6cdf33b47c47c57ff6` |
| `libiconv` | `1.18-1` | `pool/main/libi/libiconv/libiconv_1.18-1_aarch64.deb` | `b19e6f348034bb48d2a5590b5cb242769f682c476717374d134d004cc663dc84` |
| `liblzma` | `5.8.3` | `pool/main/libl/liblzma/liblzma_5.8.3_aarch64.deb` | `594925a313879f590fbd24050305551a78eadd9a9319f6e612389b1a521113c6` |
| `libtalloc` | `2.4.3` | `pool/main/libt/libtalloc/libtalloc_2.4.3_aarch64.deb` | `ac81ad623d74c209718b9f3acb2dd702cc8a88c431e820d212229910b4db29da` |
| `pcre2` | `10.47` | `pool/main/p/pcre2/pcre2_10.47_aarch64.deb` | `51f915d22de639bfca6ec029ae613987bbe3bc73626eede13319fd2e95f50b63` |
| `proot` | `5.1.107.81` | `pool/main/p/proot/proot_5.1.107.81_aarch64.deb` | `6a7847d6cd9783711de6fa86512433180cd7916174dc5657151d41ef4551b241` |
| `tar` | `1.35-2` | `pool/main/t/tar/tar_1.35-2_aarch64.deb` | `f7279dd13a80962e2551ad74b7782c0a97286f5c8d0044e5fbc5017f22197b15` |
| `xz-utils` | `5.8.3` | `pool/main/x/xz-utils/xz-utils_5.8.3_aarch64.deb` | `7e7999d0b967e4aa4f57c0c8f66dcacd83b310252278047404376d171961f03f` |

`acl` is produced by the Termux `attr` package recipe. `xz-utils` is produced by
the Termux `liblzma` package recipe through `xz-utils.subpackage.sh`.
