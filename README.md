# mf64-key-light

キー（ルート音）とスケールに応じて、その構成音を [MIDI Fighter 64](https://store.djtechtools.com/products/midi-fighter-64) のパッド LED に色で表示する macOS アプリ。Maschine + MIDI Fighter での演奏中、手元の操作でキー / スケールを切り替え、ライトを移調補助に使う。

## 構成

- **CLI**: `mf64 set --key C --scale major` 等で状態を更新し、MF64 のライトを切り替える本体機能
- **設定画面 (GUI)**: コマンドカタログ・配色プレビュー・現在状態を表示するダッシュボード。キー監視はしない
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

## 開発

```sh
swift build       # ビルド
swift test        # 単体テスト
swift format lint --recursive Sources Tests   # lint
```

Command Line Tools のみで完結する（Xcode 本体は不要）。
