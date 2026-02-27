import XCTest

final class YOMUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingSkipEntersMapShell() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)
        XCTAssertTrue(app.tabBars.buttons["Map"].exists)
    }

    func testLocateMeShowsRecoveryAlertWhenPermissionDenied() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_LOCATION_DENIED"])
        app.launch()

        completeOnboarding(in: app)
        let locateButton = app.buttons["map_locate_me"]
        XCTAssertTrue(locateButton.waitForExistence(timeout: 5))
        locateButton.tap()

        let permissionAlert = app.alerts["Location Access Needed"]
        XCTAssertTrue(permissionAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(permissionAlert.buttons["Open Settings"].exists)
        XCTAssertTrue(permissionAlert.buttons["Not Now"].exists)
        permissionAlert.buttons["Not Now"].tap()
    }

    func testSearchNoResultShowsRecoveryAlert() {
        let app = makeApp(extraArguments: ["UITEST_SHOW_SEARCH_NO_RESULT_ALERT"])
        app.launch()

        completeOnboarding(in: app)
        let noResultAlert = app.alerts["No Results Found"]
        XCTAssertTrue(noResultAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(noResultAlert.buttons["Retry"].exists)
        XCTAssertTrue(noResultAlert.buttons["Not Now"].exists)
        noResultAlert.buttons["Not Now"].tap()
    }

    private func makeApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITEST_RESET_APP_STATE",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launchArguments += extraArguments
        return app
    }

    private func completeOnboarding(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))

        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Stay updated while walking"].waitForExistence(timeout: 5))
        let skipButton = app.buttons["onboarding_skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8))
    }
}
