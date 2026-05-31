import CoreMIDI
import Foundation

/// 受信した MIDI ボイスメッセージ 1 件。
public struct MIDIMessage: Equatable, Sendable {
    public let status: UInt8
    public let data1: UInt8
    public let data2: UInt8?

    public init(status: UInt8, data1: UInt8, data2: UInt8?) {
        self.status = status
        self.data1 = data1
        self.data2 = data2
    }

    /// 1 始まりのチャンネル番号。
    public var channel: Int { Int(status & 0x0F) + 1 }

    /// メッセージ種別の表示名。
    public var kind: String {
        switch status & 0xF0 {
        case 0x80: return "NoteOff"
        case 0x90: return "NoteOn "
        case 0xA0: return "PolyAT "
        case 0xB0: return "CC     "
        case 0xC0: return "Program"
        case 0xD0: return "ChanAT "
        case 0xE0: return "Pitch  "
        default: return String(format: "0x%02X ", status & 0xF0)
        }
    }

    public var description: String {
        let d2 = data2.map(String.init) ?? "-"
        return "\(kind) ch=\(channel) data1=\(data1) data2=\(d2)"
    }
}

/// パケットの生バイト列を、連結されたボイスメッセージ列へ分解する純粋関数。
///
/// 1 パケットに複数メッセージが入る（例: NoteOn の直後に CC）。ランニングステータスにも対応する。
/// SysEx 等の可変長メッセージは扱わない（MF64 のパッド入力はチャンネルボイスのみ）。
public func parseVoiceMessages(_ bytes: [UInt8]) -> [MIDIMessage] {
    var result: [MIDIMessage] = []
    var running: UInt8?
    var i = 0
    while i < bytes.count {
        let status: UInt8
        if bytes[i] & 0x80 != 0 {
            status = bytes[i]
            running = status
            i += 1
        } else if let rs = running {
            status = rs
        } else {
            // ステータス無しで始まるデータバイトは捨てる。
            i += 1
            continue
        }
        let type = status & 0xF0
        // Program Change / Channel Pressure はデータ 1 バイト、他は 2 バイト。
        let dataCount = (type == 0xC0 || type == 0xD0) ? 1 : 2
        guard i + dataCount <= bytes.count else { break }
        let d1 = bytes[i]
        let d2 = dataCount == 2 ? bytes[i + 1] : nil
        result.append(MIDIMessage(status: status, data1: d1, data2: d2))
        i += dataCount
    }
    return result
}

/// CoreMIDI 入力を購読し、"Midi Fighter 64" の送信を監視する。
public final class CoreMIDIMonitor {
    private let client: MIDIClientRef
    private let port: MIDIPortRef

    /// source を名前一致で探して接続する。1 つも無ければ throw する。
    ///
    /// - Parameters:
    ///   - nameMatch: source 名にこの文字列を含むものを購読する（大文字小文字無視）。
    ///   - onMessage: メッセージ受信ごとに呼ばれる（CoreMIDI のスレッドで実行される）。
    public init(
        nameMatch: String = "Midi Fighter 64",
        onMessage: @escaping (MIDIMessage) -> Void
    ) throws {
        var client = MIDIClientRef()
        let clientStatus = MIDIClientCreate("mf64-monitor" as CFString, nil, nil, &client)
        guard clientStatus == noErr else {
            throw CoreMIDIError.clientCreationFailed(clientStatus)
        }
        self.client = client

        var port = MIDIPortRef()
        let portStatus = MIDIInputPortCreateWithBlock(client, "mf64-monin" as CFString, &port) {
            listPtr,
            _ in
            for packet in listPtr.unsafeSequence() {
                let length = Int(packet.pointee.length)
                var data = packet.pointee.data
                let bytes = withUnsafeBytes(of: &data) { Array($0.prefix(length)) }
                for message in parseVoiceMessages(bytes) {
                    onMessage(message)
                }
            }
        }
        guard portStatus == noErr else {
            MIDIClientDispose(client)
            throw CoreMIDIError.portCreationFailed(portStatus)
        }
        self.port = port

        let needle = nameMatch.lowercased()
        var connected = 0
        for i in 0..<MIDIGetNumberOfSources() {
            let source = MIDIGetSource(i)
            guard source != 0 else { continue }
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(source, kMIDIPropertyDisplayName, &name)
            let display = (name?.takeRetainedValue() as String?) ?? ""
            if display.lowercased().contains(needle) {
                MIDIPortConnectSource(port, source, nil)
                connected += 1
            }
        }
        guard connected > 0 else {
            MIDIClientDispose(client)
            throw CoreMIDIError.destinationNotFound
        }
    }

    deinit {
        MIDIClientDispose(client)
    }
}
