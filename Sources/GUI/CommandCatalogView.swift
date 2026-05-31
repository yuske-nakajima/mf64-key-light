import AppKit
import Core
import SwiftUI

/// モック下段の「SHORTCUT COMMANDS」セクション。
///
/// 各行は刻印ラベル + 等幅コマンド（JetBrains Mono）+ COPY ボタン。COPY は NSPasteboard へコピーする。
/// ショートカット.app は PATH を引き継がないため、実行ファイルのフルパスを添えて掲示する。
struct CommandCatalogView: View {
    /// 1 コマンド行（表示ラベルと貼り付け用コマンド文字列）。
    private struct CommandRow: Identifiable {
        let id = UUID()
        let label: String
        let command: String
    }

    /// CLI 実行バイナリのフルパス。GUI 実行バイナリと同じディレクトリの `mf64` を指す想定。
    private var binaryPath: String {
        let dir =
            (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent
            ?? "/path/to"
        return (dir as NSString).appendingPathComponent("mf64")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            HStack(alignment: .firstTextBaseline) {
                EngravedText(
                    "SHORTCUT COMMANDS",
                    font: .oswald(13),
                    color: DesignTokens.Engrave.normal
                )
                Spacer()
                EngravedText("paste into Shortcuts.app", font: .oswald(11))
            }
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    commandRow(row)
                }
            }
        }
    }

    /// 掲示するコマンド行（モック忠実の最小集合）。
    private var rows: [CommandRow] {
        [
            CommandRow(
                label: "set key / scale",
                command: "\(binaryPath) set --key C --scale major"
            ),
            CommandRow(label: "scale cycle", command: "\(binaryPath) scale --up"),
            CommandRow(label: "root ± semitone", command: "\(binaryPath) root --up"),
            CommandRow(label: "blackout", command: "\(binaryPath) off"),
            CommandRow(label: "monitor input", command: "\(binaryPath) monitor"),
        ]
    }

    private func commandRow(_ row: CommandRow) -> some View {
        HStack(spacing: 16) {
            EngravedText(row.label, font: .oswald(12))
                .frame(width: 140, alignment: .leading)
            Text(row.command)
                .font(.jetBrainsMono(13))
                .foregroundStyle(DesignTokens.Engrave.strong)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 12)
            SkeuoButton(action: { copy(row.command) }) {
                Text("COPY")
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            // 行間の彫り込み境界線。
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    /// コマンド文字列をペーストボードへコピーする。
    private func copy(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
    }
}

struct CommandCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CommandCatalogView()
            .padding(32)
            .background(PlateBackground().ignoresSafeArea())
            .previewDisplayName("CommandCatalogView")
    }
}
