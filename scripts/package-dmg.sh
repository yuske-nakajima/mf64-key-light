#!/usr/bin/env bash
set -euo pipefail

# MF64 Key Light の配布 DMG を組む。
#
# 引数: バージョン文字列（例 1.0.0）。省略時は dev。先頭の v は除去する。
#
# 成果物: dist/MF64-Key-Light-<version>.dmg
#   - MF64 Key Light.app（GUI + CLI 同梱）
#   - mf64（CLI 単体, PATH 用）
#   - /Applications への symlink
#   - INSTALL.txt（Gatekeeper 回避・PATH 設定の手順）
#
# Developer ID 署名・notarize はしない。ただし Apple Silicon ではバンドル無署名だと
# ダウンロード時に「壊れている」と判定されるため、最低限の ad-hoc 署名（自己署名）だけ行う。

VERSION_RAW="${1:-dev}"
VERSION="${VERSION_RAW#v}"

# リポジトリルートを基準に動く（scripts/ の 1 つ上）。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="MF64 Key Light"
BUNDLE_ID="xyz.developer-nakajima.mf64-key-light"
GUI_EXECUTABLE="mf64-settings"
CLI_EXECUTABLE="mf64"
RESOURCE_BUNDLE="mf64-key-light_GUI.bundle"

RELEASE_DIR=".build/release"
DIST_DIR="dist"
STAGING_DIR="$DIST_DIR/staging"
APP_DIR="$STAGING_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/MF64-Key-Light-$VERSION.dmg"

echo "==> building release binaries"
swift build -c release

# 必須成果物の存在チェック。
for artifact in "$GUI_EXECUTABLE" "$CLI_EXECUTABLE" "$RESOURCE_BUNDLE"; do
  if [ ! -e "$RELEASE_DIR/$artifact" ]; then
    echo "error: $RELEASE_DIR/$artifact が見つからない（swift build -c release が必要）" >&2
    exit 1
  fi
done

echo "==> staging dist/ (冪等に作り直す)"
rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"

# GUI 実行ファイル。
cp "$RELEASE_DIR/$GUI_EXECUTABLE" "$APP_DIR/Contents/MacOS/$GUI_EXECUTABLE"

# CLI も .app 内に同梱する。
cp "$RELEASE_DIR/$CLI_EXECUTABLE" "$APP_DIR/Contents/MacOS/$CLI_EXECUTABLE"

# FontRegistration は .app 起動時 Bundle.main.resourceURL(= Contents/Resources/) を
# 候補に含めて mf64-key-light_GUI.bundle を探すため、リソースバンドルはここに置く。
mkdir -p "$APP_DIR/Contents/Resources"
cp -R "$RELEASE_DIR/$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/$RESOURCE_BUNDLE"

# SwiftPM のリソースバンドルは Info.plist を持たないフラットディレクトリのため、
# codesign が「bundle format unrecognized」で失敗する。最小 Info.plist を足して
# 署名可能な flat bundle にする（ttf は引き続き直下にあり FontRegistration の取得に影響しない）。
cat >"$APP_DIR/Contents/Resources/$RESOURCE_BUNDLE/Info.plist" <<RBPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID.resources</string>
	<key>CFBundleName</key>
	<string>mf64-key-light_GUI</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
</dict>
</plist>
RBPLIST

echo "==> writing Info.plist"
cat >"$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundleDisplayName</key>
	<string>$APP_NAME</string>
	<key>CFBundleExecutable</key>
	<string>$GUI_EXECUTABLE</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.music</string>
</dict>
</plist>
PLIST

# .app バンドルへ ad-hoc 署名する（`-` = 自己署名）。バンドル構造を組み終えた後に署名する。
# これが無いと、ダウンロードした .app が Apple Silicon で「壊れている」と判定される。
# リソースバンドルへ Info.plist を足したので --deep で .app 全体（メイン実行ファイル・
# 同梱 CLI・リソースバンドル）を ad-hoc 署名できる。
echo "==> ad-hoc 署名"
codesign --force --deep --sign - "$APP_DIR"

echo "==> staging dmg payload"
# /Applications への symlink（ドラッグ&ドロップ導線）。
ln -s /Applications "$STAGING_DIR/Applications"

# PATH 用に CLI 単体も同梱する。
cp "$RELEASE_DIR/$CLI_EXECUTABLE" "$STAGING_DIR/$CLI_EXECUTABLE"

cat >"$STAGING_DIR/INSTALL.txt" <<'INSTALL'
MF64 Key Light インストール手順
================================

1. アプリ（GUI）のインストール
   「MF64 Key Light.app」を「Applications」フォルダへドラッグしてください。

2. 初回起動（Gatekeeper 回避）
   Apple Developer 署名はありません（ad-hoc 署名のみ）。ダブルクリックでは
   「開発元を確認できないため開けません」と表示されます。
   アプリアイコンを右クリック →「開く」→ ダイアログで「開く」を選ぶと
   起動できます（次回以降は通常のダブルクリックで起動します）。

   「壊れているため開けません」と出る場合は quarantine 属性を外してください:

     xattr -dr com.apple.quarantine /Applications/MF64\ Key\ Light.app

3. CLI（mf64）を PATH に通す（任意）
   ショートカット.app やターミナルから mf64 コマンドを使う場合は、
   同梱の「mf64」を PATH の通った場所へコピーしてください。

     mkdir -p /usr/local/bin
     cp /Volumes/MF64\ Key\ Light/mf64 /usr/local/bin/mf64
     xattr -d com.apple.quarantine /usr/local/bin/mf64 2>/dev/null || true

   コピー後、ターミナルで `mf64` が実行できることを確認してください。
   （.app 内の Contents/MacOS/mf64 を直接参照しても同じものが使えます）
INSTALL

echo "==> creating DMG: $DMG_PATH"
mkdir -p "$DIST_DIR"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> cleaning staging"
rm -rf "$STAGING_DIR"

echo "==> done: $DMG_PATH"
