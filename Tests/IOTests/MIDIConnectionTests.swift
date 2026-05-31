import CoreMIDI
import Foundation
import Testing

@testable import IO

/// `isMF64Connected` の名前一致判定を仮想 destination で検証する。
/// CoreMIDI が使えない環境（ヘッドレス/CI）では graceful skip する。
@Suite("MIDIConnection")
struct MIDIConnectionTests {
    private static func coreMIDIAvailable() -> Bool {
        var client = MIDIClientRef()
        let status = MIDIClientCreate("mf64-conn-probe" as CFString, nil, nil, &client)
        if status == noErr {
            MIDIClientDispose(client)
            return true
        }
        return false
    }

    @Test("名前一致する destination があれば接続と判定する")
    func detectsMatchingDestination() throws {
        guard Self.coreMIDIAvailable() else {
            print("skip: CoreMIDI 不可（ヘッドレス/CI 環境）")
            return
        }

        // ユニークな needle を使い、他テストや実機の干渉を避ける。
        let needle = "MF64ConnTest-\(UUID().uuidString)"
        let name = "Midi Fighter 64 \(needle)"

        // 立てる前は未接続。
        #expect(isMF64Connected(nameMatch: needle) == false)

        var client = MIDIClientRef()
        try #require(
            MIDIClientCreate("mf64-conn-client" as CFString, nil, nil, &client) == noErr
        )
        defer { MIDIClientDispose(client) }

        var dest = MIDIEndpointRef()
        let createStatus = MIDIDestinationCreateWithBlock(client, name as CFString, &dest) { _, _ in
        }
        try #require(createStatus == noErr)
        defer { MIDIEndpointDispose(dest) }

        // 登録が CoreMIDI に伝播するまで僅かに待つ。
        Thread.sleep(forTimeInterval: 0.2)

        // 部分一致（大文字小文字無視）で検出される。
        #expect(isMF64Connected(nameMatch: needle))
        #expect(isMF64Connected(nameMatch: needle.lowercased()))
    }

    @Test("一致しない needle では未接続と判定する")
    func ignoresNonMatchingName() {
        // 実機が刺さっていても一致しないユニーク文字列なら false。
        let needle = "no-such-device-\(UUID().uuidString)"
        #expect(isMF64Connected(nameMatch: needle) == false)
    }
}
