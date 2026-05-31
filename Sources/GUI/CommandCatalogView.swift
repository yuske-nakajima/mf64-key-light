import AppKit
import Core
import SwiftUI

/// 実行可能な全コマンド文字列を一覧表示し、フルパス付きでコピーできる。
///
/// ショートカット.app は PATH を引き継がないため、実行ファイルのフルパスを添えて掲示する。
struct CommandCatalogView: View {
    /// CLI 実行バイナリのフルパス。GUI 実行バイナリと同じディレクトリの `mf64` を指す想定。
    private var binaryPath: String {
        let dir =
            (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent
            ?? "/path/to"
        return (dir as NSString).appendingPathComponent("mf64")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("コマンドカタログ").font(.headline)
            Text("各行をコピーしてショートカット等から実行できます（フルパス付き）。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(commands.enumerated()), id: \.offset) { _, cmd in
                row(cmd)
            }
        }
    }

    /// 全コマンド文字列（フルパス付き）。
    private var commands: [String] {
        var result: [String] = []
        // set: 全キー × 全スケール。
        for keyName in KeyNames.names {
            for scale in Scale.allCases {
                result.append("\(binaryPath) set --key \(keyName) --scale \(scale.rawValue)")
            }
        }
        // 相対コマンド。
        result.append("\(binaryPath) scale --up")
        result.append("\(binaryPath) scale --down")
        result.append("\(binaryPath) root --up")
        result.append("\(binaryPath) root --down")
        return result
    }

    private func row(_ cmd: String) -> some View {
        HStack {
            Text(cmd)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
            Button("コピー") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(cmd, forType: .string)
            }
            .controlSize(.small)
        }
    }
}
