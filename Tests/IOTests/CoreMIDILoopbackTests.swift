import CoreMIDI
import Foundation
import Testing

@testable import IO

/// 仮想 destination を立てて CoreMIDISender の送信バイト列を受け取り検証する。
/// CoreMIDI が使えない環境（ヘッドレス/CI）では graceful skip する。
@Suite("CoreMIDILoopback")
struct CoreMIDILoopbackTests {
    /// MIDIClientCreate が通るかで CoreMIDI 利用可否を判定する。
    private static func coreMIDIAvailable() -> Bool {
        var client = MIDIClientRef()
        let status = MIDIClientCreate("mf64-probe" as CFString, nil, nil, &client)
        if status == noErr {
            MIDIClientDispose(client)
            return true
        }
        return false
    }

    @Test("仮想 destination が CoreMIDISender の Note On を受信する")
    func loopbackReceivesNoteOn() throws {
        guard Self.coreMIDIAvailable() else {
            print("skip: CoreMIDI 不可（ヘッドレス/CI 環境）")
            return
        }

        let name = "Midi Fighter 64 Loopback Test \(UUID().uuidString)"

        // 受信バイトを集める。MIDIReadBlock からの参照渡しのため class box で保持。
        final class Box: @unchecked Sendable {
            let lock = NSLock()
            var bytes: [UInt8] = []
        }
        let box = Box()

        var client = MIDIClientRef()
        try #require(
            MIDIClientCreate("mf64-loopback-client" as CFString, nil, nil, &client) == noErr
        )
        defer { MIDIClientDispose(client) }

        var dest = MIDIEndpointRef()
        let createStatus = MIDIDestinationCreateWithBlock(client, name as CFString, &dest) {
            packetList,
            _ in
            var packet = packetList.pointee.packet
            for _ in 0..<packetList.pointee.numPackets {
                let count = Int(packet.length)
                withUnsafeBytes(of: packet.data) { raw in
                    box.lock.lock()
                    for i in 0..<count {
                        box.bytes.append(raw[i])
                    }
                    box.lock.unlock()
                }
                packet = MIDIPacketNext(&packet).pointee
            }
        }
        try #require(createStatus == noErr)
        defer { MIDIEndpointDispose(dest) }

        // destination が CoreMIDI に登録されるまで僅かに待つ。
        Thread.sleep(forTimeInterval: 0.2)

        let sender = try CoreMIDISender(
            nameMatch: name,
            settings: Settings(midiChannel: 1, colorRoot: 54, colorMember: 36, colorOutside: 3)
        )
        sender.sendNoteOn(note: 36, velocity: 45)

        // 非同期配送を待つ。
        Thread.sleep(forTimeInterval: 0.3)

        box.lock.lock()
        let received = box.bytes
        box.lock.unlock()

        #expect(received == [0x90, 36, 45])
    }
}
