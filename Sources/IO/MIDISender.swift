import Core

/// MF64 の LED 色は Note On(`0x90 + (channel-1)`, note, velocity) で設定する。
/// velocity が色コード、velocity 0 は消灯。
///
/// - Parameters:
///   - note: MIDI ノート番号（0..127 を想定）。
///   - velocity: 色コード（0 で消灯）。
///   - channel: MIDI チャンネル（1..16）。範囲外は 1..16 にクランプする。
public func noteOnBytes(note: Int, velocity: UInt8, channel: Int) -> [UInt8] {
    let clamped = min(max(channel, 1), 16)
    let status = UInt8(0x90 + (clamped - 1))
    return [status, UInt8(note & 0x7F), velocity]
}

/// LED 点灯のための MIDI 送信境界。色レイアウトを padMap でノート番号に解決して送る。
public protocol MIDISender {
    /// 各パッドの色を padMap でノート番号に解決して送信する。
    func send(_ pads: [(pad: Int, color: LEDColor)], padMap: [Int])
}

/// note/velocity を直接指定して Note On を送る境界。off / colorscan で使う。
public protocol RawMIDISender {
    /// 単発の Note On を送る。
    func sendNoteOn(note: Int, velocity: UInt8)

    /// 全 64 パッドに velocity 0 を送って消灯する。
    func sendAllOff(padMap: [Int])
}

/// 送信内容を標準出力にログ出力するだけのスタブ。実機なしでパイプライン確認に使う。
public struct LoggingMIDISender: MIDISender, RawMIDISender {
    public init() {}

    public func send(_ pads: [(pad: Int, color: LEDColor)], padMap: [Int]) {
        let channel = Devices.midiChannel
        for (pad, color) in pads {
            // padMap 範囲外のパッドは送信対象から外す。
            guard pad < padMap.count else { continue }
            let note = padMap[pad]
            let velocity = Devices.velocity(for: color)
            let bytes = noteOnBytes(note: note, velocity: velocity, channel: channel)
            print(
                "MIDI send pad=\(pad) note=\(note) velocity=\(velocity) color=\(color) bytes=\(bytes)"
            )
        }
    }

    public func sendNoteOn(note: Int, velocity: UInt8) {
        let bytes = noteOnBytes(note: note, velocity: velocity, channel: Devices.midiChannel)
        print("MIDI send note=\(note) velocity=\(velocity) bytes=\(bytes)")
    }

    public func sendAllOff(padMap: [Int]) {
        for note in padMap {
            sendNoteOn(note: note, velocity: 0)
        }
    }
}
