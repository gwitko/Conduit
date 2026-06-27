#!/usr/bin/env bash
#
# rewrite-soname.sh — the only Conduit-side change to the bundled local-shell
# binaries. No source code is modified.
#
# Android only extracts native libraries named like `lib*.so` from `jniLibs`,
# so the executables and libraries are renamed into that shape. Two dynamic
# linker name strings additionally have to be rewritten in place so the renamed
# files resolve from `nativeLibraryDir`:
#
#     libtalloc.so.2        -> libtalloc.so      (DT_SONEME / DT_NEEDED)
#     libbusybox.so.1.38.0  -> libbusybox.so     (DT_SONAME / DT_NEEDED)
#
# Each rewrite is byte-length-preserving: the new (shorter) name plus its NUL
# terminator, right-padded with NULs to the original length. File sizes and all
# other bytes are unchanged.
#
# Usage:
#     third_party/source-offer/rewrite-soname.sh            # rewrite in place
#     third_party/source-offer/rewrite-soname.sh --verify   # verify only
#
# Run from the repo root after refreshing the binaries from the pinned Termux
# packages. After rewriting, update bundled-binaries.sha256.

set -euo pipefail

JNI="android/app/src/main/jniLibs/arm64-v8a"

# old -> new string pairs (new must be shorter than or equal to old)
PAIRS=(
  "libtalloc.so.2|libtalloc.so"
  "libbusybox.so.1.38.0|libbusybox.so"
)

rewrite_file() {
  local file="$1" old="$2" new="$3"
  OLD="$old" NEW="$new" perl -0777 -pi -e '
    my ($o, $n) = ($ENV{OLD}, $ENV{NEW});
    die "replacement longer than original" if length($n) > length($o);
    my $pad = $n . ("\0" x (length($o) - length($n)));
    s/\Q$o\E/$pad/g;
  ' "$file"
}

verify=0
[ "${1:-}" = "--verify" ] && verify=1

if [ "$verify" -eq 1 ]; then
  status=0
  for f in "$JNI"/*.so; do
    if command -v readelf >/dev/null 2>&1; then
      leftover=$(readelf -d "$f" 2>/dev/null \
        | grep -E 'NEEDED|SONAME' \
        | grep -E 'libtalloc\.so\.2|libbusybox\.so\.1\.38\.0' || true)
      if [ -n "$leftover" ]; then
        echo "NOT REWRITTEN: $f"
        echo "$leftover"
        status=1
      fi
    fi
  done
  [ "$status" -eq 0 ] && echo "OK: no over-long talloc/busybox names remain."
  exit "$status"
fi

for f in "$JNI"/*.so; do
  for pair in "${PAIRS[@]}"; do
    old="${pair%%|*}"
    new="${pair##*|}"
    rewrite_file "$f" "$old" "$new"
  done
done

echo "Rewrite complete. Now refresh bundled-binaries.sha256:"
echo "  ( cd \"\$(git rev-parse --show-toplevel)\" && sha256sum $JNI/*.so > third_party/source-offer/bundled-binaries.sha256 )"
echo "Verify with: third_party/source-offer/rewrite-soname.sh --verify"
