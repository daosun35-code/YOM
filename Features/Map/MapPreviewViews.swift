import MapKit
import SwiftUI

private struct SheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MapPreviewSheetView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let point: PointOfInterest
    let language: AppLanguage
    let isCompact: Bool
    let showsPrimaryAction: Bool
    let primaryActionTitle: String
    let detailsTitle: String
    let closeTitle: String
    let retrievalModeText: String
    let demoNotesTitle: String
    let demoNotesBody: String
    let onPrimaryAction: () -> Void
    let onDetails: () -> Void
    let onClose: () -> Void
    let onContentHeightMeasured: (CGFloat) -> Void

    private var summaryLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 4 : 2
    }

    private var usesVerticalActions: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var shouldStackSecondaryActionsVertically: Bool {
        isCompact || usesVerticalActions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.space16) {
                VStack(alignment: .leading, spacing: DSSpacing.space16) {
                    VStack(alignment: .leading, spacing: DSSpacing.space12) {
                        Text(point.title(in: language))
                            .dsTextStyle(.title, weight: .semibold)
                            .foregroundStyle(DSColor.textPrimary)
                            .lineLimit(2)
                            .accessibilityAddTraits(.isHeader)

                        HStack(spacing: DSSpacing.space8) {
                            PreviewMetadataChip(systemName: "calendar", text: String(point.year))
                            PreviewMetadataChip(systemName: "location.fill", text: point.distanceText(in: language))
                        }
                    }

                    Text(point.summary(in: language))
                        .dsTextStyle(.body)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(summaryLineLimit)

                    Divider()

                    actionSection
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: SheetContentHeightKey.self, value: geo.size.height)
                    }
                )

                if !isCompact {
                    detailContentSection
                }
            }
            .padding(.horizontal, DSSpacing.space24)
            .padding(.top, DSSpacing.space16)
            .padding(.bottom, DSSpacing.space24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onPreferenceChange(SheetContentHeightKey.self) { height in
            guard height > 0 else { return }
            onContentHeightMeasured(height)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: DSSpacing.space12) {
            if showsPrimaryAction {
                primaryActionButton
            }
            if shouldStackSecondaryActionsVertically {
                VStack(spacing: DSSpacing.space8) {
                    if isCompact {
                        secondaryActionButton
                    }
                    closeActionButton
                }
            } else {
                if isCompact {
                    HStack(spacing: DSSpacing.space12) {
                        secondaryActionButton
                        closeActionButton
                    }
                } else {
                    closeActionButton
                }
            }
        }
    }

    private var primaryActionButton: some View {
        Button(primaryActionTitle) {
            onPrimaryAction()
        }
        .dsPrimaryCTAStyle()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityIdentifier("map_preview_primary_action")
    }

    private var secondaryActionButton: some View {
        Button {
            onDetails()
        } label: {
            Text(detailsTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_preview_secondary_details")
    }

    private var closeActionButton: some View {
        Button {
            onClose()
        } label: {
            Text(closeTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_preview_close_action")
    }

    @ViewBuilder
    private var detailContentSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            Divider()

            Text(point.summary(in: language))
                .dsTextStyle(.body)
                .foregroundStyle(DSColor.textPrimary)
                .lineSpacing(DSLineSpacing.body)
                .accessibilityIdentifier("map_preview_detail_summary")

            Text(retrievalModeText)
                .dsTextStyle(.caption)
                .foregroundStyle(DSColor.textSecondary)
                .accessibilityIdentifier("map_preview_detail_mode")

            GroupBox {
                Text(demoNotesBody)
                    .dsTextStyle(.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DSSpacing.space4)
            } label: {
                Text(demoNotesTitle)
                    .dsTextStyle(.headline)
            }
            .accessibilityIdentifier("map_preview_detail_notes")
        }
    }
}

private struct PreviewMetadataChip: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(spacing: DSSpacing.space4) {
            Image(systemName: systemName)
                .font(DSTypography.iconSmall.weight(.semibold))
                .foregroundStyle(DSColor.textSecondary)
                .accessibilityHidden(true)

            Text(text)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DSSpacing.space8)
        .padding(.vertical, DSSpacing.space4)
        .background(
            Capsule(style: .continuous)
                .fill(DSColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(DSColor.borderSubtle.opacity(DSOpacity.subtleBorder), lineWidth: DSBorder.bw1)
        )
    }
}

struct NavigationPillView: View {
    let point: PointOfInterest
    let language: AppLanguage
    let onEndTap: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        HStack(spacing: DSSpacing.space8) {
            Image(systemName: "location.north.line.fill")
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.space4) {
                Text(strings.navigationActive)
                    .dsTextStyle(.caption, weight: .semibold)
                    .foregroundStyle(DSColor.textSecondary)
                Text(point.title(in: language))
                    .dsTextStyle(.body)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(role: .destructive) {
                onEndTap()
            } label: {
                Label(strings.endNavigation, systemImage: "xmark")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(DSColor.statusError)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(strings.endNavigation)
            .accessibilityIdentifier("map_top_navigation_end_action")
        }
        .padding(.horizontal, DSSpacing.space12)
        .padding(.vertical, DSSpacing.space12)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map_top_navigation_pill_container")
    }
}

struct NavigationInlineDetailCard: View {
    let point: PointOfInterest
    let route: MKRoute?
    let routeStatus: MapScreenState.RouteStatus
    let language: AppLanguage
    let onExpandDetail: () -> Void
    let onCollapse: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            HStack(alignment: .top, spacing: DSSpacing.space8) {
                VStack(alignment: .leading, spacing: DSSpacing.space4) {
                    Text(strings.navigationInlineCardTitle)
                        .dsTextStyle(.caption, weight: .semibold)
                        .foregroundStyle(DSColor.textSecondary)

                    Text(point.title(in: language))
                        .dsTextStyle(.body, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(1)
                        .accessibilityIdentifier("map_navigation_inline_destination")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    onCollapse()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(DSTypography.iconMedium.weight(.semibold))
                        .foregroundStyle(DSColor.textSecondary)
                        .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.navigationInlineCollapseAction)
                .accessibilityIdentifier("map_navigation_inline_collapse")
            }

            inlineMetricRow(
                label: strings.navigationInlineNextActionLabel,
                value: nextActionText,
                valueIdentifier: "map_navigation_inline_next_action_value"
            )
            inlineMetricRow(
                label: strings.navigationTaskDistanceLabel,
                value: nextDistanceText,
                valueIdentifier: "map_navigation_inline_distance_value"
            )
            inlineMetricRow(
                label: strings.navigationTaskStatusLabel,
                value: routeStatusText,
                valueIdentifier: "map_navigation_inline_status_value"
            )

            Button(strings.navigationInlineExpandDetailAction) {
                onExpandDetail()
            }
            .dsSecondaryCTAStyle()
            .accessibilityIdentifier("map_navigation_inline_expand_full_detail")
        }
        .padding(DSSpacing.space12)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                .stroke(DSColor.borderSubtle.opacity(DSOpacity.subtleBorder), lineWidth: DSBorder.bw1)
        )
    }

    private func inlineMetricRow(label: String, value: String, valueIdentifier: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.space8) {
            Text(label)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            Spacer(minLength: DSSpacing.space8)

            Text(value)
                .dsTextStyle(.caption)
                .foregroundStyle(DSColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .accessibilityIdentifier(valueIdentifier)
        }
    }

    private var nextActionText: String {
        guard routeStatus == .ready else {
            return fallbackNextActionText
        }
        guard let route else {
            return fallbackNextActionText
        }
        if let nextStep = route.steps.first(where: { step in
            step.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }) {
            return nextStep.instructions
        }
        return fallbackNextActionText
    }

    private var fallbackNextActionText: String {
        switch routeStatus {
        case .loading:
            strings.routeLoading
        case .failed, .unavailable, .idle, .ready:
            strings.navigationInlineNextActionPlaceholder
        }
    }

    private var nextDistanceText: String {
        guard let route else { return strings.navigationInlineValuePlaceholder }
        let stepDistance = route.steps
            .first(where: { step in
                step.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            })?.distance ?? route.distance
        return formattedDistance(stepDistance)
    }

    private var routeStatusText: String {
        switch routeStatus {
        case .idle:
            strings.navigationTaskStatusPending
        case .loading:
            strings.routeLoading
        case .ready:
            strings.navigationTaskStatusReady
        case .unavailable:
            strings.routeUnavailable
        case .failed:
            strings.routeFailedRetry
        }
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .naturalScale
        measurementFormatter.locale = language.locale
        return measurementFormatter.string(
            from: Measurement(value: distance, unit: UnitLength.meters)
        )
    }
}

struct NavigationDetailSheet: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let point: PointOfInterest?
    let route: MKRoute?
    let routeStatus: MapScreenState.RouteStatus
    let language: AppLanguage
    let onRetry: () -> Void
    let onEnd: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }
    private let missingRouteValuePlaceholder = "--"

    private var pointTitleLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 2
    }

    private var pointSummaryLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 2
    }

    var body: some View {
        NavigationStack {
            List {
                Section(strings.navigationActive) {
                    navigationTaskInfoSection
                }

                if let routeIssueMessage {
                    Section(strings.navigationTaskStatusLabel) {
                        Text(routeIssueMessage)
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)

                        Button(strings.retryText) {
                            onRetry()
                        }
                        .accessibilityIdentifier("map_route_retry")
                    }
                }

                if point != nil {
                    Section {
                        placeSummarySection
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onEnd()
                    } label: {
                        Text(strings.endNavigation)
                    }
                    .accessibilityIdentifier("map_end_navigation_in_sheet")
                }
            }
            .navigationTitle(strings.navigationActive)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var navigationTaskInfoSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            Text(strings.navigationTaskInfoTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            NavigationTaskInfoRow(
                title: strings.navigationTaskETALabel,
                value: routeETAText,
                systemName: "clock",
                valueIdentifier: "map_navigation_task_eta_value"
            )
            .accessibilityIdentifier("map_navigation_task_eta_row")

            NavigationTaskInfoRow(
                title: strings.navigationTaskDistanceLabel,
                value: routeDistanceText,
                systemName: "ruler",
                valueIdentifier: "map_navigation_task_distance_value"
            )
            .accessibilityIdentifier("map_navigation_task_distance_row")

            NavigationTaskInfoRow(
                title: strings.navigationTaskStatusLabel,
                value: routeStatusText,
                systemName: "dot.radiowaves.left.and.right",
                valueIdentifier: "map_navigation_task_status_value"
            )
            .accessibilityIdentifier("map_navigation_task_status_row")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map_navigation_task_info_section")
    }

    private var routeDistanceText: String {
        guard let route else { return missingRouteValuePlaceholder }
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .naturalScale
        measurementFormatter.locale = language.locale
        return measurementFormatter.string(
            from: Measurement(value: route.distance, unit: UnitLength.meters)
        )
    }

    private var routeETAText: String {
        guard let route else { return missingRouteValuePlaceholder }
        let etaFormatter = DateComponentsFormatter()
        etaFormatter.unitsStyle = .short
        etaFormatter.allowedUnits = route.expectedTravelTime >= 3600 ? [.hour, .minute] : [.minute]
        return etaFormatter.string(from: route.expectedTravelTime) ?? missingRouteValuePlaceholder
    }

    private var routeStatusText: String {
        switch routeStatus {
        case .idle:
            strings.navigationTaskStatusPending
        case .loading:
            strings.routeLoading
        case .ready:
            strings.navigationTaskStatusReady
        case .unavailable:
            strings.routeUnavailable
        case .failed:
            strings.routeFailedRetry
        }
    }

    private var routeIssueMessage: String? {
        switch routeStatus {
        case .failed:
            strings.routeFailedRetry
        case .unavailable:
            strings.routeUnavailable
        case .idle, .loading, .ready:
            nil
        }
    }

    @ViewBuilder
    private var placeSummarySection: some View {
        if let point {
            Text(point.title(in: language))
                .dsTextStyle(.body, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(pointTitleLineLimit)
                .accessibilityIdentifier("map_navigation_detail_point_title")
            Text(point.summary(in: language))
                .dsTextStyle(.caption)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(pointSummaryLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("map_navigation_detail_point_summary")
        }
    }
}

private struct NavigationTaskInfoRow: View {
    let title: String
    let value: String
    let systemName: String
    let valueIdentifier: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.space8) {
            Label {
                Text(title)
                    .dsTextStyle(.caption, weight: .semibold)
                    .foregroundStyle(DSColor.textSecondary)
            } icon: {
                Image(systemName: systemName)
                    .font(DSTypography.iconSmall.weight(.semibold))
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier(valueIdentifier)
        }
    }
}
