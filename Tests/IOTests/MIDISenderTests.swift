import Core
import Foundation
import Testing

@testable import IO

/// 送信を捕捉するテスト用 sink。
private final class CapturingSender: RawMIDISender {
    private(set) var sent: [(note: Int, velocity: UInt8)] = []

    func sendNoteOn(note: Int, velocity: UInt8) {
        sent.append((note, velocity))
    }

    func sendAllOff(padMap: [Int]) {
        for note in padMap {
            sendNoteOn(note: note, velocity: 0)
        }
    }
}

@Suite("MIDISender")
struct MIDISenderTests {
    @Test("noteOnBytes: ch1 は status 0x90、note/velocity がそのまま入る")
    func noteOnBytesChannel1() {
        #expect(noteOnBytes(note: 36, velocity: 45, channel: 1) == [0x90, 36, 45])
    }

    @Test("noteOnBytes: ch3 は status 0x92")
    func noteOnBytesChannel3() {
        #expect(noteOnBytes(note: 99, velocity: 8, channel: 3) == [0x92, 99, 8])
    }

    @Test("noteOnBytes: ch16 は status 0x9F")
    func noteOnBytesChannel16() {
        #expect(noteOnBytes(note: 60, velocity: 0, channel: 16)[0] == 0x9F)
    }

    @Test("noteOnBytes: channel は 1..16 にクランプされる")
    func noteOnBytesChannelClamp() {
        #expect(noteOnBytes(note: 60, velocity: 1, channel: 0)[0] == 0x90)
        #expect(noteOnBytes(note: 60, velocity: 1, channel: 99)[0] == 0x9F)
    }

    @Test("noteOnBytes: note は 7bit にマスクされる")
    func noteOnBytesNoteMask() {
        #expect(noteOnBytes(note: 0x80, velocity: 1, channel: 1)[1] == 0)
        #expect(noteOnBytes(note: 127, velocity: 1, channel: 1)[1] == 127)
    }

    @Test("sendAllOff: 全 64 パッドに velocity 0 を送る")
    func sendAllOffEmitsZeroForAllPads() {
        let sink = CapturingSender()
        sink.sendAllOff(padMap: Devices.defaultPadMap)
        #expect(sink.sent.count == Devices.padCount)
        #expect(sink.sent.allSatisfy { $0.velocity == 0 })
        // padMap のノートが順に出る。
        #expect(sink.sent.map { $0.note } == Devices.defaultPadMap)
    }
}
