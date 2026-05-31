# mf64-key-light

キー（ルート音）とスケールに応じて、その構成音を [MIDI Fighter 64](https://store.djtechtools.com/products/midi-fighter-64) のパッド LED に色で表示する macOS アプリ。Maschine + MIDI Fighter での演奏中、手元の操作でキー / スケールを切り替え、ライトを移調補助に使う。

- **CLI (`mf64`)**: `mf64 set --key C --scale major` 等で状態を更新し、MF64 のライトを切り替える本体機能
- **設定画面 (GUI, `MF64 Key Light.app`)**: 現在状態の表示、キー / スケール操作、MIDI 設定、コマンドカタログを持つダッシュボード
- **キー入力**: アプリでは監視せず、macOS 標準の「ショートカット.app」から CLI を叩く

```
ショートカット.app ──コマンド──▶ mf64 CLI ──MIDI out──▶ MIDI Fighter 64
                                     │
                                   SQLite に現在のキー/スケールを保存
```

## 配色

- ルート音のパッド = 紫
- 構成音のパッド = 水色
- スケール外のパッド = 白

## インストール

1. [Releases](https://github.com/yuske-nakajima/mf64-key-light/releases) から `MF64-Key-Light-<version>.dmg` をダウンロードして開く。
2. **このアプリは無署名です。** ダブルクリックでは「開発元を確認できないため開けません」と出ます。`MF64 Key Light.app` を右クリック →「開く」→ ダイアログで「開く」を選ぶと起動できます（初回のみ。次回以降はダブルクリックで起動）。
3. `MF64 Key Light.app` を `Applications` フォルダへドラッグしてインストール。
4. CLI（`mf64`）をショートカット.app やターミナルから使う場合は、DMG 同梱の `mf64` を PATH の通った場所へコピーします。

   ```sh
   mkdir -p /usr/local/bin
   cp "/Volumes/MF64 Key Light/mf64" /usr/local/bin/mf64
   xattr -d com.apple.quarantine /usr/local/bin/mf64 2>/dev/null || true
   ```

   `.app` 内の `Contents/MacOS/mf64` を直接参照しても同じバイナリです。詳細は DMG 内の `INSTALL.txt` を参照。

## 使い方

### CLI コマンド

| コマンド | 説明 |
| --- | --- |
| `mf64 set --key <name> --scale <name>` | キー / スケールを設定（片方だけでも可） |
| `mf64 scale --up` / `--down` | スケールを巡回方向へ 1 つ進める |
| `mf64 root --up` / `--down` | ルートを半音上下する |
| `mf64 off` | 全 64 パッドを消灯（velocity 0） |
| `mf64 config [--channel N] [--root V] [--member V] [--outside V]` | MIDI チャンネル(1..16)と紫/水色/白の velocity(0..127)を設定。引数なしで現在値を表示 |
| `mf64 colorscan [--note N] [--from A] [--to B] [--delay MS]` | 指定 note に velocity A..B を順送りして色を実機採取 |
| `mf64 monitor` | MF64 の入力を監視しログ出力（Ctrl-C で終了） |

### ショートカット.app 連携

キー / スケール操作は macOS 標準の「ショートカット.app」の「シェルスクリプトを実行」アクションから `mf64` を呼び出します。**ショートカット.app は PATH を引き継がないため、コマンドはフルパスで書く必要があります。**

```sh
/usr/local/bin/mf64 scale --up
```

設定画面の「SHORTCUT COMMANDS」ページに、実行バイナリのフルパス付きのコマンドが並びます（COPY ボタンでコピーしてショートカット.app に貼り付け）。

### 設定画面 (GUI)

`MF64 Key Light.app` はページ遷移式のダッシュボードです。

- **MAIN**: 現在のキー / スケールの表示と操作、パッドグリッドのプレビュー、MF64 の接続状態
- **MIDI OUTPUT**: MIDI チャンネルと 3 色（紫 / 水色 / 白）の velocity をノブで設定
- **SHORTCUT COMMANDS**: ショートカット.app に貼り付けるコマンドのカタログ

GUI と CLI / ショートカットの変更は双方向に同期します（GUI 側は 0.5 秒ポーリングで外部変更を取り込む）。

## 色校正

LED の色は velocity（色コード）で決まり、実機・ファームウェアによって値が異なります。`mf64 colorscan` で velocity を順送りして実機の発色を目視確認し、紫 / 水色 / 白に対応する値を採取します。

```sh
mf64 colorscan --from 0 --to 60 --delay 300
```

採取した値を `config` で設定します（参考値: 紫=54 / 水色=36 / 白=3）。

```sh
mf64 config --channel 2 --root 54 --member 36 --outside 3
```

## 実機の注意

- **MidiFighter Utility のグローバルアニメーション設定は OFF にしてください。** ON のままだとパッドが点滅し、本アプリの LED 表示が安定しません。
- **デバイスのチャンネルを合わせてください。** MF64 の Bank によって出力チャンネルが変わります（例: Bank 2 = ch2）。`mf64 config --channel N`（GUI の MIDI OUTPUT ページでも可）でアプリ側のチャンネルを実機に合わせます。

## 開発

```sh
swift build        # ビルド
./scripts/test.sh  # 単体テスト
swift format lint --strict --recursive Sources Tests   # lint
```

Command Line Tools のみで完結する（Xcode 本体は不要）。

> 単体テストは `swift-testing` を使う。Command Line Tools 環境では `swift test` が
> フレームワーク / `lib_TestingInterop.dylib` を既定パスで解決できず実行時に dlopen 失敗するため、
> `scripts/test.sh` が CLT 配下のパスを補って実行する（フル Xcode / CI では素の `swift test` にフォールバック）。

### リリース

DMG の作成は `scripts/package-dmg.sh` で行います。

```sh
bash scripts/package-dmg.sh 1.0.0   # dist/MF64-Key-Light-1.0.0.dmg を生成
```

`v` 付きタグを push すると、GitHub Actions（`.github/workflows/release.yml`）が DMG をビルドし、GitHub Release に添付します。

```sh
git tag v1.0.0
git push origin v1.0.0
```

Pull Request では Release を作らず、同じスクリプトで DMG を生成して artifact に上げ、パッケージングが壊れていないかを検証します。

## ライセンス

同梱フォントのライセンス（各ファイルはバンドル内に同梱）:

- Anton / Oswald / JetBrains Mono: SIL Open Font License (OFL)
- Permanent Marker: Apache License 2.0
