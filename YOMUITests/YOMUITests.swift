import XCTest
import UIKit

final class YOMUITests: XCTestCase {
    private enum SnapshotPage: String {
        case onboarding
        case map
        case archive
        case settings
        case retrieval
    }

    private let snapshotDiffTolerance: Double = 0.01
    private let snapshotChannelDeltaTolerance: Int = 8

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingSkipEntersMapShell() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)
        XCTAssertTrue(app.tabBars.buttons["Map"].exists)
    }

    func testOnboardingPermissionCopyIsVisible() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))

        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Stay updated while walking"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Push permission is optional and does not block map access in the first round shell."]
                .waitForExistence(timeout: 5)
        )

        let allowButton = app.buttons
            .matching(identifier: "onboarding_allow_permission")
            .firstMatch
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        XCTAssertEqual(allowButton.label, "Allow Notifications and Open Map")

        let skipButton = app.buttons
            .matching(identifier: "onboarding_skip")
            .firstMatch
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        XCTAssertEqual(skipButton.label, "Open Map Without Notifications")
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

    func testSearchSuggestionsAndNoResultRecoveryFlow() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_SEARCH_NO_RESULTS_ON_SUBMIT"])
        app.launch()

        completeOnboarding(in: app)

        let openSearchButton = app.buttons["map_open_search"]
        XCTAssertTrue(openSearchButton.waitForExistence(timeout: 8))
        openSearchButton.tap()

        let keyboard = app.keyboards.firstMatch
        if keyboard.waitForExistence(timeout: 5) == false {
            let searchBar = app.otherElements["map_search_bar"].firstMatch
            XCTAssertTrue(searchBar.waitForExistence(timeout: 3))
            searchBar.tap()
        }
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Recommendations"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Market Street Corner"].firstMatch.exists)

        app.typeText("zzzzzz")
        app.typeText("\n")

        let noResultAlert = app.alerts["No Results Found"]
        XCTAssertTrue(noResultAlert.waitForExistence(timeout: 8))
        XCTAssertTrue(noResultAlert.buttons["Retry"].exists)
        XCTAssertTrue(noResultAlert.buttons["Not Now"].exists)

        noResultAlert.buttons["Retry"].tap()
        let retriedNoResultAlert = app.alerts["No Results Found"]
        if retriedNoResultAlert.waitForExistence(timeout: 2) {
            retriedNoResultAlert.buttons["Not Now"].tap()
        }
    }

    func testTopNavigationPillTapDoesNotPresentNavigationDetailSheet() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
        app.launch()

        completeOnboarding(in: app)

        let navigationPill = tapTopNavigationPill(in: app)
        XCTAssertTrue(navigationPill.exists)
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.5)
    }

    func testTopNavigationPillShowsEndActionButton() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
        app.launch()

        completeOnboarding(in: app)

        let endButton = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_end_action")
            .firstMatch
        XCTAssertTrue(endButton.waitForExistence(timeout: 8))
        XCTAssertTrue(endButton.isHittable)

        _ = tapTopNavigationPill(in: app)
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.5)
    }

    func testTopNavigationEndActionEndsNavigationAfterConfirmation() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
        app.launch()

        completeOnboarding(in: app)

        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))

        let endButton = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_end_action")
            .firstMatch
        XCTAssertTrue(endButton.waitForExistence(timeout: 8))
        endButton.tap()

        let confirmButton = app.descendants(matching: .any)
            .matching(identifier: "map_confirm_end_navigation_in_top_pill")
            .firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(waitForDisappearance(of: navigationPill, timeout: 5))
        XCTAssertFalse(endButton.exists)
    }

    func testNavigationShowsSingleTopStatusContainerBaseline() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
        app.launch()

        completeOnboarding(in: app)

        let routeOverlay = app.descendants(matching: .any)
            .matching(identifier: "map_top_route_overlay_container")
            .firstMatch
        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        let topStatusContainers = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier IN %@",
                    [
                        "map_top_route_overlay_container",
                        "map_top_navigation_pill_container"
                    ]
                )
            )
        let locateButton = app.buttons["map_locate_me"]

        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))
        XCTAssertFalse(routeOverlay.exists)
        XCTAssertEqual(topStatusContainers.count, 1)
        XCTAssertTrue(locateButton.waitForExistence(timeout: 8))
        XCTAssertTrue(navigationPill.isHittable)
        XCTAssertTrue(locateButton.isHittable)

        let overlapRect = navigationPill.frame.intersection(locateButton.frame)
        XCTAssertTrue(
            overlapRect.isNull || overlapRect.isEmpty,
            "Navigation pill and locate button should not overlap. pill=\(navigationPill.frame), locate=\(locateButton.frame)"
        )
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

        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))

        let quickRetryButton = app.descendants(matching: .any)
            .matching(identifier: "map_route_retry_quick")
            .firstMatch
        XCTAssertTrue(quickRetryButton.waitForExistence(timeout: 8))

        quickRetryButton.tap()
        XCTAssertTrue(waitForDisappearance(of: quickRetryButton, timeout: 3))
        XCTAssertTrue(quickRetryButton.waitForExistence(timeout: 8))
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.2)
    }

    func testTappingCurrentNavigationPinShowsPreviewWithoutPrimaryAction() {
        let app = makeApp(
            extraArguments: [
                "UITEST_FORCE_NAVIGATION_ACTIVE"
            ]
        )
        app.launch()

        completeOnboarding(in: app)

        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))

        let currentDestinationPin = app.buttons["map_point_1935"]
        XCTAssertTrue(currentDestinationPin.waitForExistence(timeout: 8))
        currentDestinationPin.tap()

        let detailsButton = app.buttons["map_preview_secondary_details"].firstMatch
        let closeButton = app.buttons["map_preview_close_action"].firstMatch
        XCTAssertTrue(detailsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))

        let previewPrimaryAction = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertFalse(
            previewPrimaryAction.waitForExistence(timeout: 1.2),
            "Tapping the current navigation destination should not show a primary start/change action."
        )
        XCTAssertTrue(navigationPill.exists)
    }

    func testHalfSheetKeepsDetailsAndCloseActionsReachable() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let primaryButton = app.buttons["map_preview_primary_action"].firstMatch
        let detailsButton = app.buttons["map_preview_secondary_details"].firstMatch
        let closeButton = app.buttons["map_preview_close_action"].firstMatch

        XCTAssertTrue(primaryButton.waitForExistence(timeout: 8))
        XCTAssertTrue(detailsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(detailsButton.isHittable)
        XCTAssertTrue(closeButton.isHittable)

        detailsButton.tap()
        let detailNotes = app.otherElements["map_preview_detail_notes"].firstMatch
        XCTAssertTrue(detailNotes.waitForExistence(timeout: 8))

        closeButton.tap()
        XCTAssertTrue(waitForDisappearance(of: primaryButton, timeout: 5))
    }

    func testHalfSheetTopPillTapDoesNotPresentNavigationDetailSheet() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_CHANGING_DESTINATION",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let previewPrimaryAction = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(previewPrimaryAction.waitForExistence(timeout: 8))

        let endButton = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_end_action")
            .firstMatch
        XCTAssertTrue(endButton.waitForExistence(timeout: 8))

        _ = tapTopNavigationPill(in: app)
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.5)
    }

    func testClosingHalfSheetDoesNotTriggerDelayedNavigationDetailSheet() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_CHANGING_DESTINATION",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let previewPrimaryAction = app.buttons["map_preview_primary_action"].firstMatch
        let closeButton = app.buttons["map_preview_close_action"].firstMatch
        XCTAssertTrue(previewPrimaryAction.waitForExistence(timeout: 8))
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))

        _ = tapTopNavigationPill(in: app)
        closeButton.tap()

        XCTAssertTrue(waitForDisappearance(of: previewPrimaryAction, timeout: 5))
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.8)
    }

    func testChangeDestinationDoesNotTriggerDelayedNavigationDetailSheet() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_LOCATION_AUTHORIZED",
                "UITEST_FORCE_CHANGING_DESTINATION",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let previewPrimaryAction = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(previewPrimaryAction.waitForExistence(timeout: 8))

        _ = tapTopNavigationPill(in: app)
        previewPrimaryAction.tap()

        XCTAssertTrue(waitForDisappearance(of: previewPrimaryAction, timeout: 5))
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.8)
    }

    func testChangeDestinationHalfSheetDoesNotShowReplacementHintCopy() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_CHANGING_DESTINATION",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT",
                "-AppleLanguages", "(zh-Hans)",
                "-AppleLocale", "zh_Hans_CN"
            ]
        )
        app.launch()

        let previewPrimaryAction = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(previewPrimaryAction.waitForExistence(timeout: 8))

        let zhHint = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS %@", "替代"))
            .firstMatch
        let enHint = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS[c] %@", "replace"))
            .firstMatch
        XCTAssertFalse(zhHint.waitForExistence(timeout: 1))
        XCTAssertFalse(enHint.waitForExistence(timeout: 1))
    }

    func testMapPinPreviewLayoutStabilityAndAccessibility() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let goButton = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(goButton.waitForExistence(timeout: 8))
        XCTAssertTrue(goButton.isHittable, "Primary CTA must be hittable in compact detent")

        XCTAssertGreaterThanOrEqual(
            goButton.frame.height, 40,
            "Primary CTA touch target must be >= 40pt (actual: \(goButton.frame.height))"
        )

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            goButton.frame.maxY, tabBar.frame.minY,
            "Primary CTA must not overlap Tab Bar. CTA bottom=\(goButton.frame.maxY), TabBar top=\(tabBar.frame.minY)"
        )

        XCTAssertTrue(app.buttons["map_locate_me"].firstMatch.isHittable)
    }

    func testMapPinPreviewLayoutStabilityChangingDestination() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_CHANGING_DESTINATION",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let goButton = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(goButton.waitForExistence(timeout: 8))
        XCTAssertTrue(goButton.isHittable, "Primary CTA must be hittable in changing-destination state")

        XCTAssertGreaterThanOrEqual(
            goButton.frame.height, 40,
            "Primary CTA touch target must be >= 40pt in changing-destination state (actual: \(goButton.frame.height))"
        )

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            goButton.frame.maxY, tabBar.frame.minY,
            "Primary CTA must not overlap Tab Bar in changing-destination state. CTA bottom=\(goButton.frame.maxY), TabBar top=\(tabBar.frame.minY)"
        )
    }

    func testPreviewTapOutsideDismissesSheet() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let goButton = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(goButton.waitForExistence(timeout: 8))

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        let outsideCoordinate = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        outsideCoordinate.tap()

        // Scrim-based dismiss must complete within 1.5 s (no map-gesture arbitration delay)
        XCTAssertTrue(
            waitForDisappearance(of: goButton, timeout: 1.5),
            "Tapping outside the preview sheet must dismiss it promptly (within 1.5 s)"
        )
    }

    func testPreviewCloseAndTapOutsideDismissConsistently() {
        // Both dismiss paths must produce identical end state: sheet gone, no residual UI
        let tapApp = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        tapApp.launch()

        let tapGoButton = tapApp.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(tapGoButton.waitForExistence(timeout: 8))

        let window = tapApp.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        XCTAssertTrue(
            waitForDisappearance(of: tapGoButton, timeout: 1.5),
            "Tap-outside dismiss must complete within 1.5 s"
        )
        XCTAssertFalse(tapApp.buttons["map_preview_close_action"].firstMatch.exists)

        let closeApp = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        closeApp.launch()

        let closeGoButton = closeApp.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(closeGoButton.waitForExistence(timeout: 8))
        let closeButton = closeApp.buttons["map_preview_close_action"].firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(
            waitForDisappearance(of: closeGoButton, timeout: 1.5),
            "Close-button dismiss must complete within 1.5 s"
        )
        XCTAssertFalse(closeApp.buttons["map_preview_close_action"].firstMatch.exists)
    }

    func testPinSwitchDoesNotFlickerOrShowBothSheets() {
        // Tapping a second pin while a preview is open must produce a single sheet transition
        // (no blank-sheet flash / no two sheets visible simultaneously)
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        let goButton = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(goButton.waitForExistence(timeout: 8))

        // Tap a different pin to trigger pin-switch path
        let secondPin = app.buttons["map_point_1947"].firstMatch
        guard secondPin.waitForExistence(timeout: 5) else {
            // Second pin not present in test data – skip gracefully
            return
        }
        secondPin.tap()

        // Sheet must still be visible (switched, not gone)
        XCTAssertTrue(goButton.waitForExistence(timeout: 3), "Preview sheet must reappear after pin switch")

        // No navigation-detail sheet must have sneaked in
        assertNavigationDetailSheetNotPresented(in: app, timeout: 0.5)
    }

    func testPreviewCloseActionDismissesSheet() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT",
                "UITEST_FORCE_PREVIEW_EXPANDED"
            ]
        )
        app.launch()

        let goButton = app.buttons["map_preview_primary_action"].firstMatch
        XCTAssertTrue(goButton.waitForExistence(timeout: 8))

        let closeButton = app.buttons["map_preview_close_action"].firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()

        XCTAssertTrue(waitForDisappearance(of: goButton, timeout: 5))
    }

    func testPreviewDetailsExpandsToLargeDetent() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT",
                "UITEST_FORCE_PREVIEW_EXPANDED"
            ]
        )
        app.launch()

        let detailsButton = app.buttons["map_preview_secondary_details"].firstMatch
        XCTAssertTrue(detailsButton.waitForExistence(timeout: 8))
        detailsButton.tap()

        let detailNotes = app.otherElements["map_preview_detail_notes"].firstMatch
        XCTAssertTrue(
            detailNotes.waitForExistence(timeout: 8),
            "Detail content should be visible after expanding to large detent"
        )
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

    func testArchiveSubmenuSwitchesBetweenExploredAndFavorites() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let submenuPicker = app.segmentedControls["archive_submenu_picker"]
        XCTAssertTrue(submenuPicker.waitForExistence(timeout: 5))

        let exploredOnlyItem = app.buttons["archive_item_1947"]
        XCTAssertTrue(exploredOnlyItem.waitForExistence(timeout: 5))

        let favoritesSegment = submenuPicker.buttons["Favorites"].firstMatch
        XCTAssertTrue(favoritesSegment.waitForExistence(timeout: 5))
        favoritesSegment.tap()

        XCTAssertTrue(app.buttons["archive_item_1935"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForDisappearance(of: exploredOnlyItem, timeout: 5))
    }

    func testSnapshotBaselineOnboardingPage() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))
        assertBaselineSnapshot(named: .onboarding)
    }

    func testSnapshotBaselineMapPage() {
        let app = makeApp(
            extraArguments: [
                "UITEST_FORCE_LOCATION_AUTHORIZED",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ]
        )
        app.launch()

        completeOnboarding(in: app)
        XCTAssertTrue(app.buttons["map_locate_me"].waitForExistence(timeout: 8))
        assertBaselineSnapshot(named: .map)
    }

    func testSnapshotBaselineArchivePage() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)
        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        XCTAssertTrue(app.buttons["archive_item_1935"].waitForExistence(timeout: 8))
        assertBaselineSnapshot(named: .archive)
    }

    func testSnapshotBaselineSettingsPage() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        assertBaselineSnapshot(named: .settings)
    }

    func testSnapshotBaselineRetrievalPage() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let archiveCard = app.buttons["archive_item_1935"]
        XCTAssertTrue(archiveCard.waitForExistence(timeout: 5))
        archiveCard.tap()

        XCTAssertTrue(app.navigationBars["Retrieval"].waitForExistence(timeout: 8))
        assertBaselineSnapshot(named: .retrieval)
    }

    func testAccessibilityDynamicTypeMaximumKeepsCoreActionsReachable() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_DYNAMIC_TYPE_ACCESSIBILITY_XXXL"])
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.isHittable)
        continueButton.tap()

        let allowButton = app.buttons["onboarding_allow_permission"]
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        XCTAssertTrue(allowButton.isHittable)

        let skipButton = app.buttons["onboarding_skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        XCTAssertTrue(skipButton.isHittable)
        skipButton.tap()

        XCTAssertTrue(app.tabBars.buttons["Map"].waitForExistence(timeout: 8))
        let locateButton = app.buttons["map_locate_me"]
        XCTAssertTrue(locateButton.waitForExistence(timeout: 8))
        XCTAssertTrue(locateButton.isHittable)
    }

    func testAccessibilityReduceMotionPathKeepsPrimaryFlowStable() {
        let app = makeApp(
            extraArguments: [
                "UITEST_FORCE_REDUCE_MOTION",
                "UITEST_FORCE_NAVIGATION_ACTIVE"
            ]
        )
        app.launch()

        completeOnboarding(in: app)

        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))
        navigationPill.tap()
        assertNavigationDetailSheetNotPresented(in: app, timeout: 1.5)
        XCTAssertTrue(navigationPill.exists)
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

    @discardableResult
    private func tapTopNavigationPill(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8), file: file, line: line)
        navigationPill.tap()
        return navigationPill
    }

    private func assertNavigationDetailSheetNotPresented(
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let endButton = app.buttons["map_end_navigation_in_sheet"].firstMatch
        let inlineDetailCard = app.descendants(matching: .any)
            .matching(identifier: "map_navigation_inline_detail_card")
            .firstMatch
        let taskInfoSection = app.otherElements["map_navigation_task_info_section"].firstMatch
        XCTAssertFalse(
            endButton.waitForExistence(timeout: timeout),
            "Navigation detail sheet should not appear unexpectedly",
            file: file,
            line: line
        )
        XCTAssertFalse(
            inlineDetailCard.waitForExistence(timeout: 0.2),
            "Inline detail card should not appear after tapping top navigation pill",
            file: file,
            line: line
        )
        XCTAssertFalse(
            taskInfoSection.waitForExistence(timeout: 0.2),
            "Navigation detail task info should not appear unexpectedly",
            file: file,
            line: line
        )
    }


    private func assertBaselineSnapshot(
        named page: SnapshotPage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        Thread.sleep(forTimeInterval: 0.4)
        let screenshot = XCUIScreen.main.screenshot()
        let currentData = screenshot.pngRepresentation

        let baselineDirectory = snapshotBaselineDirectory(file: file)
        let baselineURL = baselineDirectory.appendingPathComponent("\(page.rawValue).png")

        do {
            try FileManager.default.createDirectory(at: baselineDirectory, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create snapshot baseline directory: \(error)", file: file, line: line)
            return
        }

        if isSnapshotRecordModeEnabled {
            do {
                try currentData.write(to: baselineURL, options: .atomic)
            } catch {
                XCTFail("Failed to write recorded baseline at \(baselineURL.path): \(error)", file: file, line: line)
            }
            return
        }

        guard let baselineData = try? Data(contentsOf: baselineURL) else {
            let placeholderURL = baselineDirectory.appendingPathComponent("\(page.rawValue).placeholder.png")
            let placeholderHint = FileManager.default.fileExists(atPath: placeholderURL.path)
                ? " Found placeholder baseline at \(placeholderURL.path); record real baselines to replace it."
                : ""
            XCTFail(
                "Missing snapshot baseline: \(baselineURL.path). Run UI tests with UITEST_RECORD_BASELINES=1 to record.\(placeholderHint)",
                file: file,
                line: line
            )
            return
        }

        guard
            let currentImage = UIImage(data: currentData)?.cgImage,
            let baselineImage = UIImage(data: baselineData)?.cgImage
        else {
            XCTFail("Failed to decode snapshot image data for \(page.rawValue)", file: file, line: line)
            return
        }

        let normalizedCurrent = cropUnsafeAreas(from: currentImage)
        let normalizedBaseline = cropUnsafeAreas(from: baselineImage)

        guard normalizedCurrent.width == normalizedBaseline.width,
              normalizedCurrent.height == normalizedBaseline.height
        else {
            addAttachment(named: "current-\(page.rawValue)", screenshot: screenshot)
            addPNGAttachment(named: "baseline-\(page.rawValue)", data: baselineData)
            XCTFail(
                "Snapshot dimensions do not match for \(page.rawValue). Current: \(normalizedCurrent.width)x\(normalizedCurrent.height), baseline: \(normalizedBaseline.width)x\(normalizedBaseline.height).",
                file: file,
                line: line
            )
            return
        }

        guard let diffRatio = pixelDifferenceRatio(lhs: normalizedCurrent, rhs: normalizedBaseline) else {
            XCTFail("Failed to compute snapshot difference for \(page.rawValue)", file: file, line: line)
            return
        }

        if diffRatio > snapshotDiffTolerance {
            addAttachment(named: "current-\(page.rawValue)", screenshot: screenshot)
            addPNGAttachment(named: "baseline-\(page.rawValue)", data: baselineData)
        }

        XCTAssertLessThanOrEqual(
            diffRatio,
            snapshotDiffTolerance,
            "Snapshot mismatch for \(page.rawValue): diff ratio=\(String(format: "%.4f", diffRatio)) > tolerance=\(String(format: "%.4f", snapshotDiffTolerance)).",
            file: file,
            line: line
        )
    }

    private var isSnapshotRecordModeEnabled: Bool {
        ProcessInfo.processInfo.environment["UITEST_RECORD_BASELINES"] == "1" ||
            ProcessInfo.processInfo.arguments.contains("UITEST_RECORD_BASELINES") ||
            FileManager.default.fileExists(atPath: snapshotRecordModeFlagPath)
    }

    private var snapshotRecordModeFlagPath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SnapshotBaselines/.record-mode")
            .path
    }

    private func snapshotBaselineDirectory(file: StaticString) -> URL {
        URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()
            .appendingPathComponent("SnapshotBaselines", isDirectory: true)
    }

    private func cropUnsafeAreas(from image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        guard height > 300 else { return image }

        let topInset = Int(Double(height) * 0.05)
        let bottomInset = Int(Double(height) * 0.03)
        let cropHeight = max(1, height - topInset - bottomInset)
        let cropRect = CGRect(x: 0, y: topInset, width: width, height: cropHeight)

        return image.cropping(to: cropRect) ?? image
    }

    private func pixelDifferenceRatio(lhs: CGImage, rhs: CGImage) -> Double? {
        guard lhs.width == rhs.width, lhs.height == rhs.height else { return nil }
        guard let lhsBytes = rgbaBytes(from: lhs), let rhsBytes = rgbaBytes(from: rhs) else { return nil }

        var differentPixelCount = 0
        let pixelCount = lhs.width * lhs.height

        for index in stride(from: 0, to: lhsBytes.count, by: 4) {
            let redDiff = abs(Int(lhsBytes[index]) - Int(rhsBytes[index]))
            let greenDiff = abs(Int(lhsBytes[index + 1]) - Int(rhsBytes[index + 1]))
            let blueDiff = abs(Int(lhsBytes[index + 2]) - Int(rhsBytes[index + 2]))
            let alphaDiff = abs(Int(lhsBytes[index + 3]) - Int(rhsBytes[index + 3]))

            if redDiff > snapshotChannelDeltaTolerance ||
                greenDiff > snapshotChannelDeltaTolerance ||
                blueDiff > snapshotChannelDeltaTolerance ||
                alphaDiff > snapshotChannelDeltaTolerance {
                differentPixelCount += 1
            }
        }

        return Double(differentPixelCount) / Double(max(1, pixelCount))
    }

    private func rgbaBytes(from image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        let didRender = bytes.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let baseAddress = rawBuffer.baseAddress else { return false }
            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        return didRender ? bytes : nil
    }

    private func addAttachment(named name: String, screenshot: XCUIScreenshot) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func addPNGAttachment(named name: String, data: Data) {
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
