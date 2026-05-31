import CoreText
import Foundation

/// 同梱 `.ttf` を `Bundle.module` から CoreText に登録する。
///
/// `Resources/Fonts` 直下の ttf を `.process` スコープで登録し、`Font.custom` で
/// PostScript 名から参照できるようにする。`SettingsApp` の起動時に一度呼ぶ。
enum FontRegistration {
    /// 登録対象フォントの PostScript 名（`Typography` の参照名と一致させる）。
    static let postScriptNames = [
        "Anton-Regular",
        "Oswald-Regular",
        "JetBrainsMono-Regular",
        "PermanentMarker-Regular",
    ]

    /// 同梱 ttf をすべて登録する。
    ///
    /// すでに登録済みのフォント（重複登録）は CoreText がエラーを返すが成功扱いとし、
    /// 「最終的に参照可能か」を `registeredCount` で判定する。
    /// - Returns: 起動後に参照可能だった想定フォント名の数。`postScriptNames.count` と一致すれば全登録成功。
    @discardableResult
    static func registerBundledFonts() -> Int {
        let urls = fontURLs()
        if !urls.isEmpty {
            CTFontManagerRegisterFontURLs(urls as CFArray, .process, true) { _, _ in true }
        }
        return registeredCount()
    }

    /// 同梱 ttf の URL を集める。
    ///
    /// SwiftPM の `Bundle.module` は「`Bundle.main.bundleURL` 直下」か「ビルド時の絶対パス」しか
    /// 見ないため、.app に同梱して配布すると解決できず `fatalError` でクラッシュする。
    /// そのため Bundle.module は使わず、実行ファイル/.app から辿れる実在パスを自分で探す。
    /// 見つからなければ空を返す（システム代替フォントにフォールバックし、クラッシュしない）。
    static func fontURLs() -> [URL] {
        let bundleName = "mf64-key-light_GUI.bundle"
        let fileManager = FileManager.default

        // 候補ディレクトリ: .app 起動時は Contents/Resources、`swift run` 時は .build/<config> 等。
        var candidates: [URL] = []
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL)
        }
        candidates.append(Bundle.main.bundleURL)
        if let executableDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            candidates.append(executableDir)
        }

        for directory in candidates {
            let bundleURL = directory.appendingPathComponent(bundleName)
            guard fileManager.fileExists(atPath: bundleURL.path),
                let bundle = Bundle(url: bundleURL),
                let urls = bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil),
                !urls.isEmpty
            else {
                continue
            }
            return urls
        }
        return []
    }

    /// PostScript 名で CoreText から実体を引けるフォント数を数える。
    static func registeredCount() -> Int {
        postScriptNames.filter { isRegistered($0) }.count
    }

    /// 指定 PostScript 名のフォントが参照可能かを返す。
    static func isRegistered(_ postScriptName: String) -> Bool {
        // CTFontCreateWithName は未登録名でもシステム代替を返すため、
        // 生成結果の PostScript 名が一致するかで実登録を判定する。
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        let actual = CTFontCopyPostScriptName(font) as String
        return actual == postScriptName
    }
}
