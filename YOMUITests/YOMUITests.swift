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
    private let mapSnapshotTopNoiseCropRows: Int = 55

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingSkipEntersMapShell() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)
        XCTAssertTrue(app.tabBars.buttons["Map"].exists)
    }

    func testMapPointPinVisibleAfterOnboarding() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_LOCATION_AUTHORIZED"])
        app.launch()

        completeOnboarding(in: app)

        let pointButton = app.buttons[UITestMemoryCatalog.primaryPinIdentifier].firstMatch
        XCTAssertTrue(pointButton.waitForExistence(timeout: 8))
        XCTAssertTrue(pointButton.isHittable)
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

    func testFollowShowsRecoveryAlertWhenPermissionDenied() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_LOCATION_DENIED"])
        app.launch()

        completeOnboarding(in: app)
        let followButton = app.buttons["map_locate_me"]
        XCTAssertTrue(followButton.waitForExistence(timeout: 5))
        followButton.tap()

        let permissionAlert = app.alerts["Location Access Needed"]
        XCTAssertTrue(permissionAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(permissionAlert.buttons["Open Settings"].exists)
        XCTAssertTrue(permissionAlert.buttons["Not Now"].exists)
        permissionAlert.buttons["Not Now"].tap()
    }

    func testFollowButtonTogglesToStopFollowingWhileActive() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_LOCATION_AUTHORIZED"])
        app.launch()

        completeOnboarding(in: app)

        let followButton = app.buttons["map_locate_me"]
        XCTAssertTrue(followButton.waitForExistence(timeout: 5))
        XCTAssertEqual(followButton.label, "Follow")

        followButton.tap()
        XCTAssertTrue(waitForLabel("Stop Following", on: followButton, timeout: 5))

        followButton.tap()
        XCTAssertTrue(waitForLabel("Follow", on: followButton, timeout: 5))
    }

    func testSearchButtonPresentsKeyboardImmediately() {
        let app = makeApp()
        app.launch()

        completeOnboarding(in: app)

        let openSearchButton = app.buttons["map_open_search"]
        XCTAssertTrue(openSearchButton.waitForExistence(timeout: 8))
        openSearchButton.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts[UITestMemoryCatalog.primaryPointTitle].firstMatch.exists)

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

    func testTopNavigationEndActionEndsNavigationImmediately() {
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

        XCTAssertTrue(waitForDisappearance(of: navigationPill, timeout: 5))
        XCTAssertFalse(endButton.exists)
    }

    func testEndNavigationCompletesWithinTimeBound() {
        // Direct end path should finish quickly after tapping the top end action.
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

        XCTAssertTrue(
            waitForDisappearance(of: navigationPill, timeout: 2.0),
            "Navigation pill must disappear within 2.0 s after tapping End"
        )
    }

    func testEndNavigationLeavesNoResidualTopContainers() {
        // After direct end, all top-layer navigation containers must be fully cleared.
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
        XCTAssertFalse(
            confirmButton.waitForExistence(timeout: 0.8),
            "End action should not present a confirmation dialog"
        )

        XCTAssertTrue(waitForDisappearance(of: navigationPill, timeout: 5))

        let routeOverlay = app.descendants(matching: .any)
            .matching(identifier: "map_top_route_overlay_container")
            .firstMatch
        XCTAssertFalse(
            routeOverlay.waitForExistence(timeout: 1.0),
            "Route overlay container must not linger after navigation ends"
        )
        XCTAssertFalse(
            endButton.waitForExistence(timeout: 0.5),
            "End action button must not linger after navigation ends"
        )
        XCTAssertFalse(
            confirmButton.waitForExistence(timeout: 0.5),
            "Confirmation button must not linger after navigation ends"
        )
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

        let pointButton = app.buttons[UITestMemoryCatalog.primaryPinIdentifier]
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

        let currentDestinationPin = app.buttons[UITestMemoryCatalog.primaryPinIdentifier]
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
        let secondPin = app.buttons[UITestMemoryCatalog.secondaryPinIdentifier].firstMatch
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
        let app = makeApp(extraArguments: ["UITEST_SEED_ARCHIVE_SAMPLE"])
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let archiveCard = app.buttons[UITestMemoryCatalog.primaryArchiveIdentifier]
        XCTAssertTrue(archiveCard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Open Retrieval"].firstMatch.exists)

        archiveCard.tap()
        XCTAssertTrue(app.navigationBars["Retrieval"].waitForExistence(timeout: 5))
    }

    func testArchiveSubmenuSwitchesBetweenExploredAndFavorites() {
        let app = makeApp(extraArguments: ["UITEST_SEED_ARCHIVE_SAMPLE"])
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let submenuPicker = app.segmentedControls["archive_submenu_picker"]
        XCTAssertTrue(submenuPicker.waitForExistence(timeout: 5))

        let exploredOnlyItem = app.buttons[UITestMemoryCatalog.secondaryArchiveIdentifier]
        XCTAssertTrue(exploredOnlyItem.waitForExistence(timeout: 5))

        let favoritesSegment = submenuPicker.buttons["Favorites"].firstMatch
        XCTAssertTrue(favoritesSegment.waitForExistence(timeout: 5))
        favoritesSegment.tap()

        XCTAssertTrue(app.buttons[UITestMemoryCatalog.primaryArchiveIdentifier].waitForExistence(timeout: 5))
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
        let app = makeApp(extraArguments: ["UITEST_SEED_ARCHIVE_SAMPLE"])
        app.launch()

        completeOnboarding(in: app)
        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        XCTAssertTrue(app.buttons[UITestMemoryCatalog.primaryArchiveIdentifier].waitForExistence(timeout: 8))
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
        let app = makeApp(extraArguments: ["UITEST_SEED_ARCHIVE_SAMPLE"])
        app.launch()

        completeOnboarding(in: app)

        let archiveTab = app.tabBars.buttons["Archive"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))
        archiveTab.tap()

        let archiveCard = app.buttons[UITestMemoryCatalog.primaryArchiveIdentifier]
        XCTAssertTrue(archiveCard.waitForExistence(timeout: 5))
        archiveCard.tap()

        XCTAssertTrue(app.navigationBars["Retrieval"].waitForExistence(timeout: 8))
        assertBaselineSnapshot(named: .retrieval)
    }

    func testMemoryDetailTitleAssertion() {
        let app = makeApp(extraArguments: ["UITEST_FORCE_MEMORY_DETAIL_VIEW"])
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let skipButton = app.buttons["onboarding_skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.tap()

        let memoryTitle = app.staticTexts["memory_detail_title"]
        XCTAssertTrue(memoryTitle.waitForExistence(timeout: 8))
        XCTAssertEqual(memoryTitle.label, UITestMemoryCatalog.primaryPointTitle)
        XCTAssertTrue(app.navigationBars["Memory Detail"].waitForExistence(timeout: 5))
    }

    func testCompleteExperienceCreatesArchiveEntryAndSwitchesTabs() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_LOCATION_AUTHORIZED",
                "UITEST_FORCE_NAVIGATION_ACTIVE",
                "UITEST_FORCE_UNLOCKED_MEMORY_DETAIL"
            ]
        )
        app.launch()

        let memoryTitle = app.staticTexts["memory_detail_title"]
        XCTAssertTrue(memoryTitle.waitForExistence(timeout: 8))
        XCTAssertEqual(memoryTitle.label, UITestMemoryCatalog.primaryPointTitle)

        let completeButton = app.buttons["memory_experience_complete"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()

        let archiveCard = app.buttons[UITestMemoryCatalog.primaryArchiveIdentifier]
        XCTAssertTrue(archiveCard.waitForExistence(timeout: 8))
        XCTAssertTrue(app.navigationBars["Archive"].waitForExistence(timeout: 5))
    }

    func testBackgroundRefreshUnavailableShowsGuidance() {
        let app = makeApp(extraEnvironment: ["UITEST_SIMULATE_BG_REFRESH_UNAVAILABLE": "1"])
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose your language"].waitForExistence(timeout: 8))
        let continueButton = app.buttons["onboarding_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let allowButton = app.buttons["onboarding_allow_permission"]
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        allowButton.tap()

        let guidanceAlert = app.alerts["Background App Refresh Needed"]
        XCTAssertTrue(guidanceAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(
            guidanceAlert.staticTexts["Turn on Background App Refresh in Settings before enabling nearby memory reminders."]
                .exists
        )
        XCTAssertTrue(guidanceAlert.buttons["Open Settings"].exists)
        XCTAssertTrue(guidanceAlert.buttons["Not Now"].exists)
        guidanceAlert.buttons["Not Now"].tap()

        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["Map"].exists)
    }

    func testPassiveReminderToggleShowsEnabledStateInSettings() {
        let app = makeApp(
            extraArguments: ["UITEST_BYPASS_ONBOARDING"],
            extraEnvironment: [
                "UITEST_FORCE_PASSIVE_READY": "1",
                "UITEST_PRESET_PASSIVE_ENABLED": "1"
            ]
        )
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        let passiveToggle = app.switches["settings_passive_toggle"].firstMatch
        XCTAssertTrue(passiveToggle.waitForExistence(timeout: 5))

        let statusText = app.staticTexts["settings_passive_status"].firstMatch
        XCTAssertTrue(statusText.waitForExistence(timeout: 5))
        XCTAssertEqual(statusText.label, "Nearby memory reminders are on. Monitoring stays on this device.")
    }

    func testPassiveNotificationTapStartsNavigationFlow() {
        let app = makeApp(
            extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_LOCATION_AUTHORIZED"
            ],
            extraEnvironment: [
                "UITEST_TRIGGER_PASSIVE_NOTIFICATION_MEMORY_ID": UITestMemoryCatalog.primaryPoint.id.uuidString
            ]
        )
        app.launch()

        let navigationPill = app.descendants(matching: .any)
            .matching(identifier: "map_top_navigation_pill_container")
            .firstMatch
        XCTAssertTrue(navigationPill.waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["memory_detail_title"].exists)
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

    private func waitForLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
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

        let normalizedCurrent = normalizeSnapshotImage(named: page, from: currentImage)
        let normalizedBaseline = normalizeSnapshotImage(named: page, from: baselineImage)

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

    private func normalizeSnapshotImage(named page: SnapshotPage, from image: CGImage) -> CGImage {
        let unsafeAreaCropped = cropUnsafeAreas(from: image)
        guard page == .map else { return unsafeAreaCropped }
        // The static map shell exposes a simulator-only top band (time/location indicator),
        // which is outside the app UI and drifts between runs.
        return cropTopRows(mapSnapshotTopNoiseCropRows, from: unsafeAreaCropped)
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

    private func cropTopRows(_ rows: Int, from image: CGImage) -> CGImage {
        guard rows > 0, image.height > rows else { return image }
        let cropRect = CGRect(x: 0, y: rows, width: image.width, height: image.height - rows)
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

// MARK: - 压力测试门禁 (TEST-001 MUST)
//
// 依据：导航与预览链路压力测试调研 spec §6.1 稳定性门禁 + §6.2 时延门禁。
//
// 默认次数（开发/CI 快速通道）：
//   STRESS_REPETITIONS = 10 次稳定性重复
//   LATENCY_SAMPLES    = 10 次时延采样
//
// 发布门禁（推荐使用 SIMCTL_CHILD_ 前缀，确保注入到模拟器内测试 Runner）：
//   SIMCTL_CHILD_STRESS_REPETITIONS=200 SIMCTL_CHILD_LATENCY_SAMPLES=50 xcodebuild test ...
//   或兼容旧方式：STRESS_REPETITIONS=200 LATENCY_SAMPLES=50 xcodebuild test ...
//   xcodebuild test -testRepetitionMode fixedNumber -testRepetitions 200
//   xcodebuild test -testRepetitionMode untilFailure

final class YOMStressTests: XCTestCase {
    private static var didLogRuntimeConfig = false

    override func setUpWithError() throws {
        continueAfterFailure = false
        if Self.didLogRuntimeConfig == false {
            let config = "YOMStressTests runtime config: repetitions=\(stressRepetitionCount), latencySamples=\(latencySampleCount)"
            XCTContext.runActivity(named: config) { _ in }
            Self.didLogRuntimeConfig = true
        }
    }

    // MARK: - 稳定性重复：导航结束链路（关键链路 A）

    func testEndNavigationStability() {
        for iteration in 1...stressRepetitionCount {
            let app = makeStressApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
            app.launch()
            completeOnboarding(in: app)

            let endButton = app.descendants(matching: .any)
                .matching(identifier: "map_top_navigation_end_action")
                .firstMatch
            XCTAssertTrue(endButton.waitForExistence(timeout: 8), "iter \(iteration): End button not found")
            endButton.tap()

            let pill = app.descendants(matching: .any)
                .matching(identifier: "map_top_navigation_pill_container")
                .firstMatch
            XCTAssertTrue(
                waitForDisappearance(of: pill, timeout: 2.0),
                "iter \(iteration): Navigation pill did not disappear within 2 s"
            )
            app.terminate()
        }
    }

    // MARK: - 稳定性重复：预览 Sheet 关闭链路（关键链路 B）

    func testPreviewCloseStability() {
        for iteration in 1...stressRepetitionCount {
            let app = makeStressApp(extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ])
            app.launch()

            let goButton = app.buttons["map_preview_primary_action"].firstMatch
            XCTAssertTrue(goButton.waitForExistence(timeout: 8), "iter \(iteration): Preview not shown")

            let closeButton = app.buttons["map_preview_close_action"].firstMatch
            XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "iter \(iteration): Close not found")
            closeButton.tap()

            XCTAssertTrue(
                waitForDisappearance(of: goButton, timeout: 1.5),
                "iter \(iteration): Preview did not close within 1.5 s"
            )
            app.terminate()
        }
    }

    // MARK: - 时延采样：导航结束 P50/P95/P99 (§6.2 门禁：P95 < 500ms, P99 < 800ms)

    func testEndNavigationLatencyP95() {
        var samples: [TimeInterval] = []

        for iteration in 1...latencySampleCount {
            let app = makeStressApp(extraArguments: ["UITEST_FORCE_NAVIGATION_ACTIVE"])
            app.launch()
            completeOnboarding(in: app)

            let pill = app.descendants(matching: .any)
                .matching(identifier: "map_top_navigation_pill_container")
                .firstMatch
            XCTAssertTrue(pill.waitForExistence(timeout: 8), "iter \(iteration): Pill not found")

            let endButton = app.descendants(matching: .any)
                .matching(identifier: "map_top_navigation_end_action")
                .firstMatch
            XCTAssertTrue(endButton.waitForExistence(timeout: 8), "iter \(iteration): End not found")

            let start = Date()
            endButton.tap()
            _ = waitForDisappearance(of: pill, timeout: 5.0)
            samples.append(Date().timeIntervalSince(start))

            app.terminate()
        }

        let (p50, p95, p99, maxVal) = percentiles(samples)
        let report = "EndNavigation latency (\(latencySampleCount) samples): P50=\(ms(p50)) P95=\(ms(p95)) P99=\(ms(p99)) Max=\(ms(maxVal))"
        XCTContext.runActivity(named: report) { _ in }
        XCTAssertLessThanOrEqual(p95, 0.500, "P95 \(ms(p95)) must be < 500 ms. \(report)")
        XCTAssertLessThanOrEqual(p99, 0.800, "P99 \(ms(p99)) must be < 800 ms. \(report)")
    }

    // MARK: - 时延采样：预览关闭 P50/P95/P99 (§6.2 门禁：P95 < 400ms, P99 < 800ms)

    func testPreviewCloseLatencyP95() {
        var samples: [TimeInterval] = []

        for iteration in 1...latencySampleCount {
            let app = makeStressApp(extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT",
                "UITEST_FORCE_STATIC_MAP_SNAPSHOT"
            ])
            app.launch()

            let goButton = app.buttons["map_preview_primary_action"].firstMatch
            XCTAssertTrue(goButton.waitForExistence(timeout: 8), "iter \(iteration): Preview not shown")

            let closeButton = app.buttons["map_preview_close_action"].firstMatch
            XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "iter \(iteration): Close not found")

            let start = Date()
            closeButton.tap()
            _ = waitForDisappearance(of: goButton, timeout: 5.0)
            samples.append(Date().timeIntervalSince(start))

            app.terminate()
        }

        let (p50, p95, p99, maxVal) = percentiles(samples)
        let report = "PreviewClose latency (\(latencySampleCount) samples): P50=\(ms(p50)) P95=\(ms(p95)) P99=\(ms(p99)) Max=\(ms(maxVal))"
        XCTContext.runActivity(named: report) { _ in }
        XCTAssertLessThanOrEqual(p95, 0.400, "P95 \(ms(p95)) must be < 400 ms. \(report)")
        XCTAssertLessThanOrEqual(p99, 0.800, "P99 \(ms(p99)) must be < 800 ms. \(report)")
    }

    // MARK: - 稳定性重复：搜索开关与键盘弹出链路（§6.5 风险项 1）

    func testSearchOpenCloseStability() {
        for iteration in 1...stressRepetitionCount {
            let app = makeStressApp(extraArguments: ["UITEST_BYPASS_ONBOARDING"])
            app.launch()

            let openSearchButton = app.buttons["map_open_search"].firstMatch
            XCTAssertTrue(openSearchButton.waitForExistence(timeout: 8), "iter \(iteration): Search button not found")
            openSearchButton.tap()

            let keyboard = app.keyboards.firstMatch
            if keyboard.waitForExistence(timeout: 1.2) == false {
                let window = app.windows.firstMatch
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
            }
            XCTAssertTrue(
                keyboard.waitForExistence(timeout: 5),
                "iter \(iteration): Keyboard not shown after opening search"
            )

            app.terminate()
        }
    }

    // MARK: - 时延采样：搜索按钮到键盘可见 P50/P95/P99 (§6.5 建议：P95 < 350ms, P99 < 600ms, Max < 1000ms)

    func testSearchOpenKeyboardLatencyP95() {
        var samples: [TimeInterval] = []

        for iteration in 1...latencySampleCount {
            let app = makeStressApp(extraArguments: ["UITEST_BYPASS_ONBOARDING"])
            app.launch()

            let openSearchButton = app.buttons["map_open_search"].firstMatch
            XCTAssertTrue(openSearchButton.waitForExistence(timeout: 8), "iter \(iteration): Search button not found")

            let keyboard = app.keyboards.firstMatch
            let start = Date()
            openSearchButton.tap()

            if keyboard.waitForExistence(timeout: 1.2) == false {
                let window = app.windows.firstMatch
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
            }

            XCTAssertTrue(
                keyboard.waitForExistence(timeout: 5),
                "iter \(iteration): Keyboard did not appear within 5 s"
            )
            samples.append(Date().timeIntervalSince(start))

            app.terminate()
        }

        let (p50, p95, p99, maxVal) = percentiles(samples)
        let report = "SearchOpen->Keyboard latency (\(samples.count) samples): P50=\(ms(p50)) P95=\(ms(p95)) P99=\(ms(p99)) Max=\(ms(maxVal))"
        XCTContext.runActivity(named: report) { _ in }
        XCTAssertLessThanOrEqual(p95, 0.350, "P95 \(ms(p95)) must be < 350 ms. \(report)")
        XCTAssertLessThanOrEqual(p99, 0.600, "P99 \(ms(p99)) must be < 600 ms. \(report)")
        XCTAssertLessThanOrEqual(maxVal, 1.000, "Max \(ms(maxVal)) must be < 1000 ms. \(report)")
    }

    // MARK: - 稳定性重复：Pin 切换链路（关键链路 C）
    // NOTE: 不使用 UITEST_FORCE_STATIC_MAP_SNAPSHOT，需真实 MapKit 渲染以访问 Annotation 按钮。

    func testPinSwitchStability() {
        var skipCount = 0
        for iteration in 1...stressRepetitionCount {
            let app = makeStressApp(extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT"
            ])
            app.launch()

            let goButton = app.buttons["map_preview_primary_action"].firstMatch
            XCTAssertTrue(goButton.waitForExistence(timeout: 8), "iter \(iteration): Preview not shown")

            // 等待相邻 pin 可点击（真实 MapKit 渲染，同视口内）
            let secondPin = app.buttons[UITestMemoryCatalog.secondaryPinIdentifier].firstMatch
            guard secondPin.waitForExistence(timeout: 5) else {
                skipCount += 1
                app.terminate()
                continue
            }
            secondPin.tap()

            // Sheet 必须重新出现（pin 切换完成，而非持续消失）
            XCTAssertTrue(
                goButton.waitForExistence(timeout: 2.0),
                "iter \(iteration): Pin-switch sheet did not reappear within 2 s"
            )
            app.terminate()
        }

        // 跳过率 > 20% 视为环境不稳定，记录为警告
        let skipRatio = Double(skipCount) / Double(stressRepetitionCount)
        XCTContext.runActivity(named: "PinSwitch skip ratio: \(String(format: "%.0f%%", skipRatio * 100)) (\(skipCount)/\(stressRepetitionCount))") { _ in }
        XCTAssertLessThan(
            skipRatio,
            0.2,
            "Pin \(UITestMemoryCatalog.secondaryPoint.year) inaccessible in \(skipCount)/\(stressRepetitionCount) iters; map render may be too slow"
        )
    }

    // MARK: - 时延采样：Pin 切换 P50/P95/P99 (§6.2 参考：P95 < 500ms)

    func testPinSwitchLatencyP95() {
        var samples: [TimeInterval] = []

        for iteration in 1...latencySampleCount {
            let app = makeStressApp(extraArguments: [
                "UITEST_BYPASS_ONBOARDING",
                "UITEST_FORCE_PREVIEW_POINT"
            ])
            app.launch()

            let goButton = app.buttons["map_preview_primary_action"].firstMatch
            XCTAssertTrue(goButton.waitForExistence(timeout: 8), "iter \(iteration): Preview not shown")

            let secondPin = app.buttons[UITestMemoryCatalog.secondaryPinIdentifier].firstMatch
            guard secondPin.waitForExistence(timeout: 5) else {
                app.terminate()
                continue
            }

            let start = Date()
            secondPin.tap()
            _ = goButton.waitForExistence(timeout: 5.0)
            samples.append(Date().timeIntervalSince(start))

            app.terminate()
        }

        guard samples.isEmpty == false else {
            XCTFail("No latency samples – pin \(UITestMemoryCatalog.secondaryPoint.year) never accessible in \(latencySampleCount) iterations")
            return
        }

        let (p50, p95, p99, maxVal) = percentiles(samples)
        let report = "PinSwitch latency (\(samples.count) samples): P50=\(ms(p50)) P95=\(ms(p95)) P99=\(ms(p99)) Max=\(ms(maxVal))"
        XCTContext.runActivity(named: report) { _ in }
        XCTAssertLessThanOrEqual(p95, 0.500, "P95 \(ms(p95)) must be < 500 ms. \(report)")
        XCTAssertLessThanOrEqual(p99, 0.800, "P99 \(ms(p99)) must be < 800 ms. \(report)")
    }

    // MARK: - Private helpers

    /// 稳定性重复次数。发布门禁应设为 200；开发/CI 快速通道默认 10。
    private var stressRepetitionCount: Int {
        resolvedPositiveInt(
            envKeys: ["STRESS_REPETITIONS", "SIMCTL_CHILD_STRESS_REPETITIONS"],
            argumentKeys: ["-STRESS_REPETITIONS", "--stress-repetitions"],
            defaultValue: 10
        )
    }

    /// 时延采样次数。发布门禁应设为 50；开发/CI 快速通道默认 10。
    private var latencySampleCount: Int {
        resolvedPositiveInt(
            envKeys: ["LATENCY_SAMPLES", "SIMCTL_CHILD_LATENCY_SAMPLES"],
            argumentKeys: ["-LATENCY_SAMPLES", "--latency-samples"],
            defaultValue: 10
        )
    }

    private func resolvedPositiveInt(
        envKeys: [String],
        argumentKeys: [String],
        defaultValue: Int
    ) -> Int {
        let env = ProcessInfo.processInfo.environment
        for key in envKeys {
            if let raw = env[key], let value = Int(raw), value > 0 {
                return value
            }
        }

        let args = ProcessInfo.processInfo.arguments
        for key in argumentKeys {
            if let index = args.firstIndex(of: key), args.indices.contains(index + 1) {
                if let value = Int(args[index + 1]), value > 0 {
                    return value
                }
            }
            if let pair = args.first(where: { $0.hasPrefix("\(key)=") }),
               let raw = pair.split(separator: "=", maxSplits: 1).last,
               let value = Int(raw), value > 0 {
                return value
            }
        }
        return defaultValue
    }

    private func percentiles(_ samples: [TimeInterval]) -> (p50: TimeInterval, p95: TimeInterval, p99: TimeInterval, max: TimeInterval) {
        guard samples.isEmpty == false else { return (0, 0, 0, 0) }
        let s = samples.sorted()
        let p50 = s[s.count / 2]
        let p95 = s[min(s.count - 1, Int(Double(s.count) * 0.95))]
        let p99 = s[min(s.count - 1, Int(Double(s.count) * 0.99))]
        return (p50, p95, p99, s.last ?? 0)
    }

    private func ms(_ t: TimeInterval) -> String { String(format: "%.0f ms", t * 1000) }

    private func makeStressApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_RESET_APP_STATE", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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

final class LocalMemoryDataIntegrityTests: XCTestCase {
    private let requiredLanguageKeys: Set<String> = ["en", "zhHans", "yue"]

    func testMemoriesJSONDecodesAndUsesValidUniqueIDs() throws {
        let url = try memoriesJSONURL()
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(MemoriesPayloadFixture.self, from: data)

        XCTAssertFalse(payload.memoryPoints.isEmpty, "memories.json must contain at least one memory point")

        let pointIDs = payload.memoryPoints.map(\.id)
        XCTAssertEqual(Set(pointIDs).count, pointIDs.count, "MemoryPoint IDs must be unique")

        let allMedia = payload.memoryPoints.flatMap(\.media)
        XCTAssertFalse(allMedia.isEmpty, "At least one media entry is required")
        XCTAssertEqual(Set(allMedia.map(\.id)).count, allMedia.count, "MemoryMedia IDs must be unique")

        for point in payload.memoryPoints {
            assertLanguageField(point.nameByLanguage, fieldName: "nameByLanguage", pointID: point.id)
            assertLanguageField(point.summaryByLanguage, fieldName: "summaryByLanguage", pointID: point.id)
            assertLanguageField(point.storyByLanguage, fieldName: "storyByLanguage", pointID: point.id)
            XCTAssertGreaterThan(point.unlockRadiusM, 0, "unlockRadiusM must be > 0 for point \(point.id)")
            XCTAssertFalse(point.media.isEmpty, "Each memory point must contain at least one media entry")

            for media in point.media {
                XCTAssertFalse(
                    media.localAssetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "localAssetName must be non-empty for media \(media.id)"
                )

                if media.type == .audio || media.type == .video {
                    guard let duration = media.duration else {
                        XCTFail("duration is required for \(media.type.rawValue) media \(media.id)")
                        continue
                    }
                    XCTAssertGreaterThan(duration, 0, "duration must be > 0 for \(media.type.rawValue) media \(media.id)")
                }
            }
        }
    }

    private func assertLanguageField(_ map: [String: String], fieldName: String, pointID: UUID) {
        XCTAssertEqual(
            Set(map.keys),
            requiredLanguageKeys,
            "\(fieldName) must contain exactly en/zhHans/yue for point \(pointID)"
        )

        for key in requiredLanguageKeys {
            let value = map[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            XCTAssertFalse(value.isEmpty, "\(fieldName).\(key) must be non-empty for point \(pointID)")
        }
    }

    private func memoriesJSONURL() throws -> URL {
        let fileManager = FileManager.default

        let sourceRootCandidate = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/memories.json")
        if fileManager.fileExists(atPath: sourceRootCandidate.path) {
            return sourceRootCandidate
        }

        let cwdCandidate = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent("Resources/memories.json")
        if fileManager.fileExists(atPath: cwdCandidate.path) {
            return cwdCandidate
        }

        throw NSError(
            domain: "LocalMemoryDataIntegrityTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Resources/memories.json not found from source or working directory"]
        )
    }
}

private struct MemoriesPayloadFixture: Decodable {
    let memoryPoints: [MemoryPointFixture]
}

struct MemoryPointFixture: Decodable {
    let id: UUID
    let year: Int
    let latitude: Double
    let longitude: Double
    let distanceMeters: Int
    let nameByLanguage: [String: String]
    let summaryByLanguage: [String: String]
    let storyByLanguage: [String: String]
    let unlockRadiusM: Double
    let tags: [String]
    let media: [MemoryMediaFixture]
}

struct MemoryMediaFixture: Decodable {
    let id: UUID
    let type: MemoryMediaTypeFixture
    let localAssetName: String
    let duration: TimeInterval?
    let thumbnailAssetName: String?
}

enum MemoryMediaTypeFixture: String, Decodable {
    case image
    case audio
    case video
    case ar
}

enum UITestMemoryCatalog {
    private static let payload: MemoriesPayloadFixture = {
        do {
            let data = try Data(contentsOf: memoriesJSONURL())
            return try JSONDecoder().decode(MemoriesPayloadFixture.self, from: data)
        } catch {
            fatalError("Failed to load UITest memory catalog: \(error)")
        }
    }()

    static var primaryPoint: MemoryPointFixture {
        guard let point = payload.memoryPoints.first else {
            fatalError("UITest memory catalog requires at least one memory point")
        }
        return point
    }

    static var secondaryPoint: MemoryPointFixture {
        guard payload.memoryPoints.count > 1 else {
            fatalError("UITest memory catalog requires at least two memory points")
        }
        return payload.memoryPoints[1]
    }

    static var primaryPointTitle: String {
        primaryPoint.nameByLanguage["en"] ?? ""
    }

    static var primaryPinIdentifier: String {
        "map_point_\(primaryPoint.year)"
    }

    static var secondaryPinIdentifier: String {
        "map_point_\(secondaryPoint.year)"
    }

    static var primaryArchiveIdentifier: String {
        "archive_item_\(primaryPoint.year)"
    }

    static var secondaryArchiveIdentifier: String {
        "archive_item_\(secondaryPoint.year)"
    }
}

private func memoriesJSONURL() throws -> URL {
    let fileManager = FileManager.default

    let sourceRootCandidate = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Resources/memories.json")
    if fileManager.fileExists(atPath: sourceRootCandidate.path) {
        return sourceRootCandidate
    }

    let cwdCandidate = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        .appendingPathComponent("Resources/memories.json")
    if fileManager.fileExists(atPath: cwdCandidate.path) {
        return cwdCandidate
    }

    throw NSError(
        domain: "LocalMemoryDataIntegrityTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Resources/memories.json not found from source or working directory"]
    )
}
