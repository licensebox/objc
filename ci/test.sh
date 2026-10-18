#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/env.sh
flags=( $(gnustep-config --objc-flags) )
libs=( $(gnustep-config --base-libs) )
# Ubuntu's GNU Objective-C runtime lives in GCC's private library directory.
# The runner may select Swift's clang, whose search paths omit that directory.
gcc_driver=${GNUSTEP_GCC:-/usr/bin/gcc}
inc="$("$gcc_driver" -print-file-name=include)"
objc_runtime="$("$gcc_driver" -print-file-name=libobjc.so)"
test -f "$objc_runtime"
objc_lib_dir=$(dirname "$objc_runtime")
clang "${flags[@]}" -I"$inc" -I"$LICENSEBOX_INCLUDE_DIR" -Isrc -c src/Licensebox.m -o build/Licensebox.o
ar rcs build/liblicensebox-objc.a build/Licensebox.o
for target in adapter lifetime; do
 clang "${flags[@]}" -I"$inc" -I"$LICENSEBOX_INCLUDE_DIR" -Isrc test/$target.m build/liblicensebox-objc.a -L"$LICENSEBOX_LIB_DIR" -llicensebox -L"$objc_lib_dir" "${libs[@]}" -o build/$target
done
build/lifetime
tar -czf build/licensebox-objc-0.2.0.tar.gz LICENSE src ci test
