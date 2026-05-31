import Core
import CoreMIDI
import Foundation

/// CoreMIDISender の初期化・送信時のエラー。
public enum CoreMIDIError: Error, CustomStringConvertible {
    /// MIDIClient / OutputPort の生成に失敗（OSStatus 付き）。
    case clientCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
    /// "Midi Fighter 64" を含む destination が見つからない。
    case destinationNotFound

    public var description: String {
        switch self {
        case .clientCreationFailed(let status):
            return "MIDIClientCreate に失敗しました (OSStatus=\(status))"
        case .portCreationFailed(let status):
            return "MIDIOutputPortCreate に失敗しました (OSStatus=\(status))"
        case .destinationNotFound:
            return "Midi Fighter 64 が見つかりません"
        }
    }
}

/// CoreMIDI 経由で MF64 に Note On を送る実送信。
///
/// LED 色は Note On(`0x90 + (channel-1)`, note, velocity) で設定する（velocity が色コード）。
public final class CoreMIDISender: MIDISender, RawMIDISender {
    private let client: MIDIClientRef
    private let port: MIDIPortRef
    private let destination: MIDIEndpointRef
    private let settings: Settings

    private var channel: Int { settings.midiChannel }

    /// destination を名前一致で探して接続する。見つからなければ throw する。
    ///
    /// - Parameters:
    ///   - nameMatch: destination 名にこの文字列を含むものを探す（大文字小文字無視）。
    ///   - settings: 送信チャンネルと色 velocity の供給元。
    public init(nameMatch: String = "Midi Fighter 64", settings: Settings = .default) throws {
        self.settings = settings

        var client = MIDIClientRef()
        let clientStatus = MIDIClientCreate("mf64-key-light" as CFString, nil, nil, &client)
        guard clientStatus == noErr else {
            throw CoreMIDIError.clientCreationFailed(clientStatus)
        }
        self.client = client

        var port = MIDIPortRef()
        let portStatus = MIDIOutputPortCreate(client, "mf64-out" as CFString, &port)
        guard portStatus == noErr else {
            MIDIClientDispose(client)
            throw CoreMIDIError.portCreationFailed(portStatus)
        }
        self.port = port

        guard let dest = Self.findDestination(nameMatch: nameMatch) else {
            MIDIClientDispose(client)
            throw CoreMIDIError.destinationNotFound
        }
        self.destination = dest
    }

    deinit {
        MIDIClientDispose(client)
    }

    /// 名前に nameMatch を含む（大文字小文字無視）最初の destination を返す。
    private static func findDestination(nameMatch: String) -> MIDIEndpointRef? {
        let needle = nameMatch.lowercased()
        let count = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            guard endpoint != 0 else { continue }
            if displayName(of: endpoint).lowercased().contains(needle) {
                return endpoint
            }
        }
        return nil
    }

    /// endpoint の表示名（kMIDIPropertyDisplayName）。取得失敗時は空文字。
    private static func displayName(of endpoint: MIDIEndpointRef) -> String {
        var unmanaged: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &unmanaged)
        guard status == noErr, let cf = unmanaged?.takeRetainedValue() else {
            return ""
        }
        return cf as String
    }

    public func send(_ pads: [(pad: Int, color: LEDColor)], padMap: [Int]) {
        for (pad, color) in pads {
            // padMap 範囲外のパッドはスキップする。
            guard pad >= 0, pad < padMap.count else { continue }
            let note = padMap[pad]
            let velocity = settings.velocity(for: color)
            sendNoteOn(note: note, velocity: velocity)
        }
    }

    public func sendNoteOn(note: Int, velocity: UInt8) {
        let bytes = noteOnBytes(note: note, velocity: velocity, channel: channel)
        sendRaw(bytes)
    }

    public func sendAllOff(padMap: [Int]) {
        for note in padMap {
            sendNoteOn(note: note, velocity: 0)
        }
    }

    /// 3 バイトを 1 つの MIDIPacketList に詰めて MIDISend する。
    private func sendRaw(_ bytes: [UInt8]) {
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        bytes.withUnsafeBufferPointer { buffer in
            _ = MIDIPacketListAdd(
                &packetList,
                MemoryLayout<MIDIPacketList>.size,
                packet,
                0,
                bytes.count,
                buffer.baseAddress!
            )
        }
        MIDISend(port, destination, &packetList)
    }
}
