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
    func testCurrentHeadingsAndSetupPathsAreLocalized() throws {
        let headings = ["Type, over the air", "Setup for connection name", "Setup for\nconnection name.", "Type guide.", "Try AirType", "Privacy Policy."]
        for language in ["en", "zh-Hant", "zh-Hans"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in headings {
                let text = bundle.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertFalse(text.isEmpty)
                if language != "en" { XCTAssertNotEqual(text, key, "Missing \(language): \(key)") }
            }
            let heading = bundle.localizedString(forKey: "Setup for\nconnection name.", value: nil, table: nil)
            XCTAssertEqual(heading.components(separatedBy: "\n").count, 2)
            let pathText = bundle.localizedString(forKey: "Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType. Then enable Allow Full Access.", value: nil, table: nil)
            if language == "zh-Hant" { XCTAssertTrue(pathText.contains("一般")); XCTAssertTrue(pathText.contains("加入新鍵盤")) }
            if language == "zh-Hans" { XCTAssertTrue(pathText.contains("通用")); XCTAssertTrue(pathText.contains("添加新键盘")) }
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
