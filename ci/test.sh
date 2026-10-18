#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/env.sh
flags=( $(gnustep-config --objc-flags) )
libs=( $(gnustep-config --base-libs) )
inc="$(gcc -print-file-name=include)"
clang "${flags[@]}" -I"$inc" -I"$LICENSEBOX_INCLUDE_DIR" -Isrc -c src/Licensebox.m -o build/Licensebox.o
ar rcs build/liblicensebox-objc.a build/Licensebox.o
for target in adapter lifetime; do
 clang "${flags[@]}" -I"$inc" -I"$LICENSEBOX_INCLUDE_DIR" -Isrc test/$target.m build/liblicensebox-objc.a -L"$LICENSEBOX_LIB_DIR" -llicensebox "${libs[@]}" -o build/$target
done
build/lifetime
tar -czf build/licensebox-objc-0.1.0.tar.gz LICENSE src ci test
