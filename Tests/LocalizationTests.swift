import XCTest
@testable import AirType

final class LocalizationTests: XCTestCase {
    func testDeviceLanguageNegotiationDoesNotDependOnBrowser() {
        XCTAssertEqual(L10n.language(for: ["en-US"]), "en")
        XCTAssertEqual(L10n.language(for: ["zh-Hant-HK"]), "zh-Hant")
        XCTAssertEqual(L10n.language(for: ["zh-Hans-CN"]), "zh-Hans")
        XCTAssertEqual(L10n.language(for: ["fr-FR", "zh-Hant"]), "zh-Hant")
    }
    func testNativeCatalogAndPermissionCopyExistForBothChineseVariants() throws {
        for (language, title) in [("zh-Hant", "設定鍵盤"), ("zh-Hans", "设置键盘")] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            XCTAssertEqual(bundle.localizedString(forKey: "Set up the keyboard", value: nil, table: nil), title)
            let permission = bundle.localizedString(forKey: "NSLocalNetworkUsageDescription", value: nil, table: "InfoPlist")
            XCTAssertNotEqual(permission, "NSLocalNetworkUsageDescription")
            XCTAssertTrue(permission.contains("AirType"))
        }
    }
    func testPortalResponseInjectsOnlyServingDeviceLanguageAndTranslations() throws {
        let source = try String(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "Portal", withExtension: "html")), encoding: .utf8)
        for (language, text) in [("en", "<html lang=\"en\">"), ("zh-Hant", "<html lang=\"zh-Hant\">"), ("zh-Hans", "<html lang=\"zh-Hans\">")] {
            let html = L10n.portalHTML(source, language: language)
            XCTAssertTrue(html.contains(text))
            XCTAssertFalse(html.contains("/*AIRTYPE_I18N*/"))
            if language == "zh-Hant" { XCTAssertTrue(html.contains("重新連線")); XCTAssertTrue(html.contains("配對碼")) }
            if language == "zh-Hans" { XCTAssertTrue(html.contains("重新连接")) }
        }
        XCTAssertFalse(source.contains("navigator.language"))
    }
}
