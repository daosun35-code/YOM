import SwiftUI
import UserNotifications

struct OnboardingFlowView: View {
    enum Step {
        case language
        case permission
    }

    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let launchArguments = ProcessInfo.processInfo.arguments

    let onFinish: () -> Void

    @State private var step: Step = .language
    @State private var isRequestingNotificationPermission = false

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DSColor.surfacePrimary, DSColor.surfaceSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DSSpacing.space24) {
                Spacer(minLength: DSSpacing.space24)

                Text(strings.appTitle)
                    .font(DSTypography.brandDisplay)
                    .foregroundStyle(DSColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(stepTitle)
                    .dsTextStyle(.title, weight: .semibold)
                    .foregroundStyle(DSColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.space16)

                Text(stepBody)
                    .dsTextStyle(.body)
                    .foregroundStyle(DSColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.space24)

                Group {
                    switch step {
                    case .language:
                        languageStep
                    case .permission:
                        permissionStep
                    }
                }
                .frame(maxWidth: DSLayout.onboardingContentMaxWidth)
                .padding(.horizontal, DSSpacing.space24)

                Spacer()

                HStack(spacing: DSSpacing.space8) {
                    Circle()
                        .fill(step == .language ? DSColor.accentPrimary : DSColor.borderSubtle.opacity(DSOpacity.subtleBorder))
                        .frame(width: DSSpacing.space8, height: DSSpacing.space8)
                    Circle()
                        .fill(step == .permission ? DSColor.accentPrimary : DSColor.borderSubtle.opacity(DSOpacity.subtleBorder))
                        .frame(width: DSSpacing.space8, height: DSSpacing.space8)
                }
                .accessibilityLabel(progressLabel)

                Spacer(minLength: DSSpacing.space12)
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case .language:
            strings.onboardingLanguageTitle
        case .permission:
            strings.onboardingPermissionTitle
        }
    }

    private var stepBody: String {
        switch step {
        case .language:
            strings.onboardingLanguageBody
        case .permission:
            strings.onboardingPermissionBody
        }
    }

    private var progressLabel: String {
        switch step {
        case .language:
            strings.onboardingStep1Of2
        case .permission:
            strings.onboardingStep2Of2
        }
    }

    private var languageStep: some View {
        VStack(spacing: DSSpacing.space12) {
            ForEach(AppLanguage.allCases) { language in
                let isSelected = languageStore.language == language

                Button {
                    languageStore.language = language
                } label: {
                    HStack {
                        Text(language.displayName)
                            .dsTextStyle(.body, weight: isSelected ? .semibold : .medium)
                            .foregroundStyle(isSelected ? DSColor.accentPrimary : DSColor.textPrimary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DSColor.accentPrimary)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, DSSpacing.space16)
                    .frame(maxWidth: .infinity, minHeight: DSControl.largeButtonHeight)
                    .padding(.vertical, DSSpacing.space4)
                    .dsSurfaceCard(isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.displayName)
                .accessibilityValue(isSelected ? strings.selectedStateText : "")
                .accessibilityAddTraits(.isButton)
                .animation(stepAnimation, value: languageStore.language)
            }

            Button(strings.continueText) {
                withAnimation(stepAnimation) {
                    step = .permission
                }
            }
            .dsPrimaryCTAStyle()
            .accessibilityIdentifier("onboarding_continue")
            .padding(.top, DSSpacing.space4)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private var permissionStep: some View {
        VStack(spacing: DSSpacing.space12) {
            Button(strings.allowPermission) {
                requestNotificationPermissionAndFinish()
            }
            .dsPrimaryCTAStyle()
            .accessibilityIdentifier("onboarding_allow_permission")
            .frame(minHeight: DSControl.largeButtonHeight)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .disabled(isRequestingNotificationPermission)
            .accessibilityHint("\(strings.onboardingAllowPermissionHint). \(strings.onboardingPermissionOptionalHint).")

            Button(strings.skipForNow) {
                onFinish()
            }
            .dsSecondaryCTAStyle()
            .accessibilityIdentifier("onboarding_skip")
            .frame(minHeight: DSControl.largeButtonHeight)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .accessibilityHint(strings.onboardingSkipPermissionHint)
        }
    }

    private var stepAnimation: Animation {
        DSMotion.shell(reduceMotion: reduceMotion || launchArguments.contains("UITEST_FORCE_REDUCE_MOTION"))
    }

    private func requestNotificationPermissionAndFinish() {
        guard isRequestingNotificationPermission == false else { return }
        isRequestingNotificationPermission = true

        Task {
            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                // Onboarding should not block app entry when authorization request fails.
            }

            await MainActor.run {
                isRequestingNotificationPermission = false
                onFinish()
            }
        }
    }
}
