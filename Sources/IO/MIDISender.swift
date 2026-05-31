import Core

/// LED 点灯のための MIDI 送信境界。実機送信（CoreMIDI）は PR2 で実装に差し替える。
public protocol MIDISender {
    /// 各パッドの色を padMap でノート番号に解決して送信する。
    func send(_ pads: [(pad: Int, color: LEDColor)], padMap: [Int])
}

/// 送信内容（ノート番号・velocity）を標準出力にログ出力するだけのスタブ。
public struct LoggingMIDISender: MIDISender {
    public init() {}

    public func send(_ pads: [(pad: Int, color: LEDColor)], padMap: [Int]) {
        for (pad, color) in pads {
            // padMap 範囲外のパッドは送信対象から外す。
            guard pad < padMap.count else { continue }
            let note = padMap[pad]
            let velocity = Devices.velocity(for: color)
            print("MIDI send pad=\(pad) note=\(note) velocity=\(velocity) color=\(color)")
        }
    }
}
