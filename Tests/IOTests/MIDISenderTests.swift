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

    @Test("LoggingMIDISender.send は Settings の channel と色 velocity を bytes に反映する")
    func loggingSenderReflectsSettings() {
        let settings = Settings(midiChannel: 4, colorRoot: 80, colorMember: 70, colorOutside: 60)
        let sender = LoggingMIDISender(settings: settings)
        // pad0 = root, pad1 = member, pad2 = outside。padMap でノートに解決される。
        let padMap = [36, 40, 44]
        let pads: [(pad: Int, color: LEDColor)] = [
            (0, .root), (1, .member), (2, .outside),
        ]
        let output = captureStdout {
            sender.send(pads, padMap: padMap)
        }
        // status は ch4 = 0x93。
        #expect(output.contains("bytes=[147, 36, 80]"))  // root
        #expect(output.contains("bytes=[147, 40, 70]"))  // member
        #expect(output.contains("bytes=[147, 44, 60]"))  // outside
    }
}

/// クロージャ実行中の標準出力を捕捉して返す。
private func captureStdout(_ body: () -> Void) -> String {
    let pipe = Pipe()
    let original = dup(STDOUT_FILENO)
    fflush(stdout)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

    body()

    fflush(stdout)
    dup2(original, STDOUT_FILENO)
    close(original)
    pipe.fileHandleForWriting.closeFile()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(decoding: data, as: UTF8.self)
}
