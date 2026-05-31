import Testing

@testable import IO

@Suite("MidiMonitor")
struct MidiMonitorTests {
    /// MF64 は 1 パッド押下で NoteOn(0x91) と CC(0xB1) を続けて送る。両方を分解する。
    @Test func parsesNoteOnAndCC() {
        let messages = parseVoiceMessages([145, 38, 127, 177, 38, 127])
        #expect(messages.count == 2)
        #expect(messages[0] == MIDIMessage(status: 0x91, data1: 38, data2: 127))
        #expect(messages[0].kind == "NoteOn ")
        #expect(messages[0].channel == 2)  // 0x91 → ch2
        #expect(messages[1] == MIDIMessage(status: 0xB1, data1: 38, data2: 127))
        #expect(messages[1].kind == "CC     ")
    }

    /// NoteOff(0x81, velocity 127) と CC(0xB1, value 0) を分解できる。
    @Test func parsesNoteOff() {
        let messages = parseVoiceMessages([129, 36, 127, 177, 36, 0])
        #expect(messages[0] == MIDIMessage(status: 0x81, data1: 36, data2: 127))
        #expect(messages[0].kind == "NoteOff")
        #expect(messages[1] == MIDIMessage(status: 0xB1, data1: 36, data2: 0))
    }

    /// Program Change(0xC0) はデータ 1 バイトとして扱う。
    @Test func programChangeIsOneDataByte() {
        let messages = parseVoiceMessages([0xC1, 5, 0x91, 60, 100])
        #expect(messages.count == 2)
        #expect(messages[0] == MIDIMessage(status: 0xC1, data1: 5, data2: nil))
        #expect(messages[1] == MIDIMessage(status: 0x91, data1: 60, data2: 100))
    }

    /// ランニングステータス（ステータス省略）を直前のステータスで補う。
    @Test func runningStatus() {
        let messages = parseVoiceMessages([0x91, 36, 127, 38, 100])
        #expect(messages.count == 2)
        #expect(messages[0] == MIDIMessage(status: 0x91, data1: 36, data2: 127))
        #expect(messages[1] == MIDIMessage(status: 0x91, data1: 38, data2: 100))
    }

    /// 中途半端な末尾（データ不足）は安全に切り捨てる。
    @Test func truncatedTail() {
        let messages = parseVoiceMessages([0x91, 36])
        #expect(messages.isEmpty)
    }
}
