import Testing

@testable import Core

@Suite("Music")
struct MusicTests {
    private func pcs(_ ints: [Int]) -> Set<PitchClass> {
        Set(ints.map { PitchClass($0) })
    }

    /// PitchClass の生成は常に 0..11 に正規化される（負値・12 超を含む）。
    @Test func pitchClassNormalization() {
        #expect(PitchClass(0).value == 0)
        #expect(PitchClass(11).value == 11)
        #expect(PitchClass(12).value == 0)
        #expect(PitchClass(13).value == 1)
        #expect(PitchClass(-1).value == 11)
        #expect(PitchClass(-12).value == 0)
        #expect(PitchClass(60).value == 0)  // MIDI C
        #expect(PitchClass(61).value == 1)  // MIDI C#
    }

    /// 代表キー C × 全 7 スケールの構成音集合。
    @Test func scaleNotesKeyC() {
        let key = PitchClass(0)
        #expect(scaleNotes(key: key, scale: .major) == pcs([0, 2, 4, 5, 7, 9, 11]))
        #expect(scaleNotes(key: key, scale: .naturalMinor) == pcs([0, 2, 3, 5, 7, 8, 10]))
        #expect(scaleNotes(key: key, scale: .dorian) == pcs([0, 2, 3, 5, 7, 9, 10]))
        #expect(scaleNotes(key: key, scale: .mixolydian) == pcs([0, 2, 4, 5, 7, 9, 10]))
        #expect(scaleNotes(key: key, scale: .majorPentatonic) == pcs([0, 2, 4, 7, 9]))
        #expect(scaleNotes(key: key, scale: .minorPentatonic) == pcs([0, 3, 5, 7, 10]))
        #expect(scaleNotes(key: key, scale: .blues) == pcs([0, 3, 5, 6, 7, 10]))
    }

    /// 代表キー F#（6）× 全 7 スケール。ルート + offset を mod12 で巡回する。
    @Test func scaleNotesKeyFSharp() {
        let key = PitchClass(6)
        // major: 6 + [0,2,4,5,7,9,11] = [6,8,10,11,1,3,5]
        #expect(scaleNotes(key: key, scale: .major) == pcs([6, 8, 10, 11, 1, 3, 5]))
        // naturalMinor: 6 + [0,2,3,5,7,8,10] = [6,8,9,11,1,2,4]
        #expect(scaleNotes(key: key, scale: .naturalMinor) == pcs([6, 8, 9, 11, 1, 2, 4]))
        // dorian: 6 + [0,2,3,5,7,9,10] = [6,8,9,11,1,3,4]
        #expect(scaleNotes(key: key, scale: .dorian) == pcs([6, 8, 9, 11, 1, 3, 4]))
        // mixolydian: 6 + [0,2,4,5,7,9,10] = [6,8,10,11,1,3,4]
        #expect(scaleNotes(key: key, scale: .mixolydian) == pcs([6, 8, 10, 11, 1, 3, 4]))
        // majorPentatonic: 6 + [0,2,4,7,9] = [6,8,10,1,3]
        #expect(scaleNotes(key: key, scale: .majorPentatonic) == pcs([6, 8, 10, 1, 3]))
        // minorPentatonic: 6 + [0,3,5,7,10] = [6,9,11,1,4]
        #expect(scaleNotes(key: key, scale: .minorPentatonic) == pcs([6, 9, 11, 1, 4]))
        // blues: 6 + [0,3,5,6,7,10] = [6,9,11,0,1,4]
        #expect(scaleNotes(key: key, scale: .blues) == pcs([6, 9, 11, 0, 1, 4]))
    }

    /// ペンタトニックは 5 音、ダイアトニックは 7 音、blues は 6 音であること。
    @Test func scaleNoteCounts() {
        let key = PitchClass(3)
        #expect(scaleNotes(key: key, scale: .major).count == 7)
        #expect(scaleNotes(key: key, scale: .majorPentatonic).count == 5)
        #expect(scaleNotes(key: key, scale: .minorPentatonic).count == 5)
        #expect(scaleNotes(key: key, scale: .blues).count == 6)
    }

    /// padColor: ルート→root, 構成音→member, スケール外→outside。
    @Test func padColorBasic() {
        let key = PitchClass(0)  // C major
        let notes = scaleNotes(key: key, scale: .major)
        #expect(padColor(padNote: 60, key: key, notes: notes) == .root)
        #expect(padColor(padNote: 0, key: key, notes: notes) == .root)
        #expect(padColor(padNote: 64, key: key, notes: notes) == .member)  // E
        #expect(padColor(padNote: 61, key: key, notes: notes) == .outside)  // C#
    }

    /// padColor のルート判定は member 判定より優先される（ルートも notes に含まれるため）。
    @Test func padColorRootPriority() {
        let key = PitchClass(5)  // F
        let notes = scaleNotes(key: key, scale: .major)
        #expect(notes.contains(key))
        #expect(padColor(padNote: 5, key: key, notes: notes) == .root)
    }

    /// layout: 0..63 を 12 で循環させた padMap で各色が正しく割り当たる。
    @Test func layoutAssignsColors() {
        let state = State(key: PitchClass(0), scale: .major)
        let padMap = (0..<64).map { $0 }
        let result = layout(state: state, padMap: padMap)

        #expect(result.count == 64)
        #expect(result.map { $0.pad } == Array(0..<64))

        let notes = scaleNotes(key: state.key, scale: .major)
        for (pad, color) in result {
            let note = padMap[pad]
            #expect(color == padColor(padNote: note, key: state.key, notes: notes))
        }

        #expect(result[0].color == .root)  // note 0 = C
        #expect(result[12].color == .root)  // note 12 = C
        #expect(result[1].color == .outside)  // note 1 = C#
        #expect(result[4].color == .member)  // note 4 = E
    }

    /// 空 padMap は空配列を返す（境界値）。
    @Test func layoutEmpty() {
        let state = State(key: PitchClass(0), scale: .major)
        #expect(layout(state: state, padMap: []).isEmpty)
    }
}
