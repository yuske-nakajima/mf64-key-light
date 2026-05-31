import Core
import IO
import SwiftUI

/// PitchClass.value → 表示用キー名（シャープ表記）。
enum KeyNames {
    static let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static func name(_ pc: PitchClass) -> String {
        names[pc.value]
    }
}

/// MF64 8×8 グリッドを layout の結果で塗る。root=紫 / member=水色 / outside=白。
struct PadGridView: View {
    let state: Core.State

    private let columns = 8
    private let rows = 8

    var body: some View {
        let pads = layout(state: state, padMap: Devices.defaultPadMap)
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        cell(for: pads[index].color)
                    }
                }
            }
        }
    }

    private func cell(for color: LEDColor) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(fillColor(color))
            .frame(width: 40, height: 40)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.gray.opacity(0.3)))
    }

    private func fillColor(_ color: LEDColor) -> Color {
        switch color {
        case .root: return .purple
        case .member: return .cyan
        case .outside: return .white
        }
    }
}
