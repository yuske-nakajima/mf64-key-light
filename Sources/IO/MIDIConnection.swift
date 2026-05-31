import CoreMIDI

/// MF64 が CoreMIDI の destination として存在するかを軽量に判定する。
///
/// `MIDIGetNumberOfDestinations` を名前一致で走査するだけで、`MIDIClient` / `OutputPort` は作らない。
/// ヘッダの接続ステータス表示をポーリングで更新する用途。`CoreMIDISender` の初期化コストを避ける。
///
/// - Parameter nameMatch: 表示名に含まれていれば一致とみなす部分文字列（大文字小文字無視）。
/// - Returns: 一致する destination が 1 つ以上あれば true。
public func isMF64Connected(nameMatch: String = "Midi Fighter 64") -> Bool {
    let needle = nameMatch.lowercased()
    let count = MIDIGetNumberOfDestinations()
    for i in 0..<count {
        let endpoint = MIDIGetDestination(i)
        guard endpoint != 0 else { continue }
        if endpointDisplayName(endpoint).lowercased().contains(needle) {
            return true
        }
    }
    return false
}

/// endpoint の表示名（kMIDIPropertyDisplayName）。取得失敗時は空文字。
private func endpointDisplayName(_ endpoint: MIDIEndpointRef) -> String {
    var unmanaged: Unmanaged<CFString>?
    let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &unmanaged)
    guard status == noErr, let cf = unmanaged?.takeRetainedValue() else {
        return ""
    }
    return cf as String
}
