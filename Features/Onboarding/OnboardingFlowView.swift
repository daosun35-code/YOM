import SwiftUI

struct OnboardingFlowView: View {
    enum Step {
        case language
        case permission
    }

    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinish: () -> Void

    @State private var step: Step = .language

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 20)

                Text(strings.appTitle)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)

                Text(stepTitle)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(stepBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Group {
                    switch step {
                    case .language:
                        languageStep
                    case .permission:
                        permissionStep
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 20)

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(step == .language ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(step == .permission ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .accessibilityLabel(progressLabel)

                Spacer(minLength: 12)
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
        switch (strings.language, step) {
        case (_, .language): return "Step 1 of 2"
        case (_, .permission): return "Step 2 of 2"
        }
    }

    private var languageStep: some View {
        VStack(spacing: 12) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageStore.language = language
                } label: {
                    HStack {
                        Text(language.displayName)
                            .font(.body.weight(.medium))
                        Spacer()
                        if languageStore.language == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.displayName)
                .accessibilityValue(languageStore.language == language ? "Selected" : "")
                .accessibilityAddTraits(.isButton)
            }

            Button(strings.continueText) {
                withAnimation(stepAnimation) {
                    step = .permission
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 4)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 12) {
            Button(strings.allowPermission) {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityHint("Optional in first-round app shell")

            Button(strings.skipForNow) {
                onFinish()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, minHeight: 44)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private var stepAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9)
    }
}
