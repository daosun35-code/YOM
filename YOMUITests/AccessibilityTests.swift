import XCTest

final class AccessibilityTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDynamicTypeXXXLKeepsPrimaryFlowReachable() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_DYNAMIC_TYPE_ACCESSIBILITY_XXXL"])
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))

        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(continueButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(continueButton.isHittable)
        continueButton.tap()

        let allowButton = app.buttons["onboarding_allow_permission"]
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        XCTAssertFalse(allowButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(allowButton.isHittable)

        let skipButton = app.buttons["onboarding_skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        XCTAssertFalse(skipButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(skipButton.isHittable)
        skipButton.tap()

        let locateButton = app.buttons["map_locate_me"]
        XCTAssertTrue(locateButton.waitForExistence(timeout: 8))
        XCTAssertFalse(locateButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(locateButton.isHittable)
    }

    func testMemoryDetailCoreElementsExposeIdentifiersAndLabels() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_MEMORY_DETAIL_VIEW"])
        app.launch()

        completeOnboardingToMemoryDetail(in: app)

        let title = app.staticTexts["memory_detail_title"]
        XCTAssertTrue(title.waitForExistence(timeout: 8))
        XCTAssertEqual(title.label, "Market Street Corner")

        let completeButton = app.buttons["memory_experience_complete"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        XCTAssertFalse(completeButton.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func makeApp(extraArguments: [String] = [], extraEnvironment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITEST_RESET_APP_STATE",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launchArguments += extraArguments
        if extraEnvironment.isEmpty == false {
            app.launchEnvironment.merge(extraEnvironment) { _, new in new }
        }
        return app
    }

    private func completeOnboardingToMemoryDetail(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))

        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let skipButton = app.buttons["onboarding_skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.tap()
    }
}
