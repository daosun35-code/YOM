import SwiftUI
import UIKit

struct MemoryDetailView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    let memoryPoint: MemoryPoint
    let onComplete: (() -> Void)?

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.space24) {
                heroSection
                infoSection
                mediaSection
                completeSection
            }
            .padding(.horizontal, DSSpacing.space24)
            .padding(.vertical, DSSpacing.space16)
        }
        .navigationTitle(strings.memoryDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack {
            Spacer(minLength: 0)
            Text(memoryPoint.title(in: languageStore.language))
                .dsTextStyle(.title, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .padding(DSSpacing.space16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: DSControl.detailHeroHeight)
        .dsSurfaceCard()
        .accessibilityHidden(true)
        .dsReadableContent()
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            Text(memoryPoint.title(in: languageStore.language))
                .dsTextStyle(.title, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("memory_detail_title")

            Text("\(memoryPoint.year)")
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            Text(memoryPoint.summary(in: languageStore.language))
                .dsTextStyle(.body)
                .foregroundStyle(DSColor.textPrimary)
                .lineSpacing(DSLineSpacing.body)

            let story = memoryPoint.story(in: languageStore.language)
            if !story.isEmpty {
                Divider()
                    .padding(.vertical, DSSpacing.space4)

                Text(strings.memoryDetailStorySection)
                    .dsTextStyle(.headline, weight: .semibold)
                    .foregroundStyle(DSColor.textPrimary)

                Text(story)
                    .dsTextStyle(.body)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineSpacing(DSLineSpacing.body)
            }
        }
        .dsReadableContent()
    }

    // MARK: - Media

    private var mediaSection: some View {
        Group {
            let imageMedia = memoryPoint.media.filter { $0.type == .image }
            if !imageMedia.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                    Text(strings.memoryDetailMediaSection)
                        .dsTextStyle(.headline, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)

                    ForEach(imageMedia) { media in
                        memoryImageView(for: media)
                    }
                }
            }

            let otherMedia = memoryPoint.media.filter { $0.type != .image }
            if !otherMedia.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.space8) {
                    ForEach(otherMedia) { media in
                        mediaPlaceholderRow(for: media)
                    }
                }
            }
        }
        .dsReadableContent()
    }

    @ViewBuilder
    private func memoryImageView(for media: MemoryMedia) -> some View {
        // Try loading from asset catalog first
        if let uiImage = UIImage(named: media.localAssetName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous))
                .accessibilityLabel(memoryPoint.title(in: languageStore.language))
        } else {
            // Placeholder when asset is not yet bundled
            RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                .fill(DSColor.surfaceSecondary)
                .frame(height: 200)
                .overlay {
                    VStack(spacing: DSSpacing.space8) {
                        Image(systemName: "photo")
                            .font(DSTypography.iconLarge)
                            .foregroundStyle(DSColor.textSecondary)
                        Text(media.localAssetName)
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                    }
                }
        }
    }

    private func mediaPlaceholderRow(for media: MemoryMedia) -> some View {
        HStack(spacing: DSSpacing.space12) {
            Image(systemName: iconName(for: media.type))
                .font(DSTypography.iconMedium)
                .foregroundStyle(DSColor.accentPrimary)
                .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
                .background(DSColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: DSRadius.r8, style: .continuous))

            VStack(alignment: .leading, spacing: DSSpacing.space4) {
                Text(mediaTypeLabel(for: media.type))
                    .dsTextStyle(.body, weight: .medium)
                    .foregroundStyle(DSColor.textPrimary)

                if let duration = media.duration {
                    Text(formattedDuration(duration))
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }

            Spacer()

            Text(strings.memoryMediaComingSoon)
                .dsTextStyle(.caption)
                .foregroundStyle(DSColor.textSecondary)
        }
        .padding(DSSpacing.space12)
        .dsSurfaceCard()
    }

    // MARK: - Complete

    private var completeSection: some View {
        Group {
            if let onComplete = onComplete {
                Button(strings.memoryExperienceComplete) {
                    onComplete()
                }
                .dsPrimaryCTAStyle()
                .accessibilityIdentifier("memory_experience_complete")
            }
        }
        .dsReadableContent()
    }

    private func iconName(for type: MemoryMedia.MediaType) -> String {
        switch type {
        case .image: return "photo"
        case .audio: return "waveform"
        case .video: return "play.rectangle"
        case .ar: return "arkit"
        }
    }

    private func mediaTypeLabel(for type: MemoryMedia.MediaType) -> String {
        switch type {
        case .image: return strings.memoryMediaTypeImage
        case .audio: return strings.memoryMediaTypeAudio
        case .video: return strings.memoryMediaTypeVideo
        case .ar: return strings.memoryMediaTypeAR
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? ""
    }
}
