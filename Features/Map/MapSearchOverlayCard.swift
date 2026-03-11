import MapKit
import SwiftUI

struct SearchOverlayCard: View {
    let language: AppLanguage
    let completions: [MKLocalSearchCompletion]
    let recommendations: [PointOfInterest]
    let recents: [PointOfInterest]
    let completionText: (MKLocalSearchCompletion) -> String
    let onSelectCompletion: (MKLocalSearchCompletion) -> Void
    let onSelect: (PointOfInterest) -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.space16) {
                if completions.isEmpty {
                    Text(strings.searchInputHint)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)

                    if recommendations.isEmpty == false {
                        section(title: strings.searchRecommendations, items: recommendations)
                    }

                    recentsSection
                } else {
                    completionSection
                }
            }
            .padding(DSSpacing.space12)
        }
        .frame(maxWidth: .infinity, maxHeight: DSControl.overlayPanelMaxHeight, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous))
        .shadow(color: DSColor.borderSubtle.opacity(DSOpacity.overlayShadow), radius: DSRadius.r8, y: DSSpacing.space4)
    }

    @ViewBuilder
    private func section(title: String, items: [PointOfInterest]) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(title)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            ForEach(items) { point in
                Button {
                    onSelect(point)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(point.title(in: language))
                                .dsTextStyle(.body)
                                .foregroundStyle(DSColor.textPrimary)
                            Text("\(point.year) · \(point.distanceText(in: language))")
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, DSSpacing.space4)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(point.accessibilityLabel(in: language))
                .accessibilityHint(strings.detailsText)
            }
        }
    }

    private var completionSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(strings.searchPrompt)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            ForEach(Array(completions.enumerated()), id: \.offset) { _, completion in
                Button {
                    onSelectCompletion(completion)
                } label: {
                    HStack(alignment: .top, spacing: DSSpacing.space8) {
                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(completion.title)
                                .dsTextStyle(.body)
                                .foregroundStyle(DSColor.textPrimary)
                            if completion.subtitle.isEmpty == false {
                                Text(completion.subtitle)
                                    .dsTextStyle(.caption)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, DSSpacing.space4)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completionText(completion))
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(strings.searchRecents)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            if recents.isEmpty {
                Text(strings.searchNoRecents)
                    .dsTextStyle(.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
            } else {
                ForEach(recents) { point in
                    Button {
                        onSelect(point)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: DSSpacing.space4) {
                                Text(point.title(in: language))
                                    .dsTextStyle(.body)
                                    .foregroundStyle(DSColor.textPrimary)
                                Text("\(point.year) · \(point.distanceText(in: language))")
                                    .dsTextStyle(.caption)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "clock.arrow.circlepath")
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, DSSpacing.space4)
                        .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(point.accessibilityLabel(in: language))
                }
            }
        }
    }
}
