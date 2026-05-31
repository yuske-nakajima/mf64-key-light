#!/usr/bin/env bash
set -euo pipefail

# swift-testing のフレームワークと lib_TestingInterop.dylib は Command Line Tools 環境では
# `swift test` の既定探索パスに無く、テストバイナリの dlopen が実行時に失敗する。
# CLT 配下に両方が存在する場合のみパスを明示する。フル Xcode / CI 環境では
# 素の `swift test` が解決できるためフォールバックする。
DEV="$(xcode-select -p)"
FW="$DEV/Library/Developer/Frameworks"
LIB="$DEV/Library/Developer/usr/lib"

if [ -d "$FW" ] && [ -f "$LIB/lib_TestingInterop.dylib" ]; then
  exec env DYLD_LIBRARY_PATH="$LIB" DYLD_FRAMEWORK_PATH="$FW" \
    swift test \
    -Xswiftc -F"$FW" \
    -Xlinker -F"$FW" \
    -Xlinker -rpath -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$LIB" \
    "$@"
else
  exec swift test "$@"
fi
