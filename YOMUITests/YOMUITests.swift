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

    func testEndNavigationRequiresConfirmation() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
        app.launch()

        completeOnboarding(in: app)

        let endButton = app.buttons["map_end_navigation"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 8))

        endButton.tap()
        let confirmButton = app.buttons
            .matching(identifier: "map_confirm_end_navigation")
            .firstMatch
        let confirmButtonByTitle = app.buttons["End Navigation"].firstMatch
        let firstDialogShown =
            confirmButton.waitForExistence(timeout: 5) ||
            confirmButtonByTitle.waitForExistence(timeout: 1)
        XCTAssertTrue(firstDialogShown)
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        } else {
            XCTAssertTrue(confirmButtonByTitle.waitForExistence(timeout: 5))
            confirmButtonByTitle.tap()
        }

        XCTAssertTrue(waitForDisappearance(of: endButton, timeout: 5))
    }

    func testMapRouteRetryFlowAfterFailure() {
        let app = makeApp(
            extraArguments: [
                "UITEST_FORCE_LOCATION_AUTHORIZED",
                "UITEST_FORCE_ROUTE_FAILURE"
            ]
        )
        app.launch()

        completeOnboarding(in: app)

        let pointButton = app.buttons["map_point_1935"]
        XCTAssertTrue(pointButton.waitForExistence(timeout: 8))
        pointButton.tap()

        let goButton = app.buttons["map_preview_primary_action"]
        XCTAssertTrue(goButton.waitForExistence(timeout: 5))
        goButton.tap()

        let retryButton = app.buttons
            .matching(identifier: "map_route_retry")
            .matching(NSPredicate(format: "label == %@", "Retry"))
            .firstMatch
        XCTAssertTrue(retryButton.waitForExistence(timeout: 8))

        retryButton.tap()
        XCTAssertTrue(waitForDisappearance(of: retryButton, timeout: 3))
        XCTAssertTrue(retryButton.waitForExistence(timeout: 8))
    }

    func testArchiveCardShowsOpenActionAndNavigatesToRetrieval() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let archiveCard = app.buttons["archive_item_1935"]
        XCTAssertTrue(archiveCard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Open Retrieval"].firstMatch.exists)

        archiveCard.tap()
        XCTAssertTrue(app.navigationBars["Retrieval"].waitForExistence(timeout: 5))
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

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

}
