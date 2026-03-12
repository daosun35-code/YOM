import SwiftUI
import UIKit

struct SettingsTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var passiveCoordinator: PassiveExperienceCoordinator
    @Environment(\.openURL) private var openURL
    @State private var showsBetaResetConfirmation = false
    @State private var passiveRemindersEnabled = false
    @State private var isUpdatingPassiveToggle = false
    @State private var passiveAlert: PassiveAlert?
    private let launchArguments = ProcessInfo.processInfo.arguments

    private var strings: AppStrings { AppStrings(language: languageStore.language) }
    private var showsBetaTools: Bool {
        isBetaBuild && launchArguments.contains("UITEST_RESET_APP_STATE") == false
    }
    private var passiveRemindersBinding: Binding<Bool> {
        Binding(
            get: { passiveRemindersEnabled },
            set: { newValue in
                guard isUpdatingPassiveToggle == false else { return }
                passiveRemindersEnabled = newValue
                Task {
                    await handlePassiveToggleChanged(newValue)
                }
            }
        )
    }

    private var isBetaBuild: Bool {
#if DEBUG
        return true
#else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }

    private enum PassiveAlert: String, Identifiable {
        case backgroundRefreshUnavailable
        case notificationDenied
        case locationDenied
        case currentLocationUnavailable
        case genericFailure

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack(path: $shellState.settingsRoutes) {
            Form {
                Section(strings.languageSection) {
                    Picker(strings.languageSection, selection: $languageStore.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .accessibilityLabel(strings.languageSection)
                }

                Section(strings.navigationSection) {
                    NavigationLink(value: SettingsRoute.about) {
                        Label(strings.aboutText, systemImage: "info.circle")
                    }
                    .accessibilityLabel(strings.aboutText)
                }

                Section(strings.nearbyMemoryRemindersSection) {
                    Toggle(isOn: passiveRemindersBinding) {
                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(strings.nearbyMemoryRemindersTitle)
                                .dsTextStyle(.body, weight: .medium)
                                .foregroundStyle(DSColor.textPrimary)

                            Text(strings.nearbyMemoryRemindersBody)
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                    }
                    .accessibilityIdentifier("settings_passive_toggle")
                    .accessibilityLabel(strings.nearbyMemoryRemindersTitle)

                    Text(
                        passiveRemindersEnabled
                            ? strings.nearbyMemoryRemindersEnabledBody
                            : strings.nearbyMemoryRemindersDisabledBody
                    )
                    .dsTextStyle(.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityIdentifier("settings_passive_status")
                }

                if showsBetaTools {
                    Section(strings.betaSection) {
                        Button(role: .destructive) {
                            showsBetaResetConfirmation = true
                        } label: {
                            Label(strings.betaReturnToOnboardingText, systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityIdentifier("settings_beta_return_onboarding")
                        .accessibilityHint(strings.betaReturnToOnboardingHint)
                    }
                }
            }
            .confirmationDialog(
                strings.betaResetConfirmationTitle,
                isPresented: $showsBetaResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(strings.betaResetConfirmAction, role: .destructive) {
                    resetOnboardingStateForBeta()
                }
                Button(strings.notNowText, role: .cancel) {}
            } message: {
                Text(strings.betaResetConfirmationMessage)
            }
            .alert(item: $passiveAlert) { alert in
                makePassiveAlert(alert)
            }
            .navigationTitle(strings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .about:
                    AboutView()
                }
            }
            .onAppear {
                syncPassiveToggle()
            }
            .onChange(of: passiveCoordinator.isPassiveEnabled) { _, _ in
                syncPassiveToggle()
            }
        }
    }

    private func resetOnboardingStateForBeta() {
        shellState.settingsRoutes = []
        shellState.selectedTab = .map
        languageStore.resetOnboardingForBeta()
    }

    private func syncPassiveToggle() {
        isUpdatingPassiveToggle = true
        passiveRemindersEnabled = passiveCoordinator.isPassiveEnabled
        isUpdatingPassiveToggle = false
    }

    private func handlePassiveToggleChanged(_ isEnabled: Bool) async {
        isUpdatingPassiveToggle = true
        defer { isUpdatingPassiveToggle = false }

        let result = await passiveCoordinator.setPassiveEnabled(isEnabled)
        switch result {
        case .success:
            passiveRemindersEnabled = passiveCoordinator.isPassiveEnabled
        case .failure(let error):
            passiveRemindersEnabled = false
            passiveAlert = passiveAlert(for: error)
        }
    }

    private func passiveAlert(for error: PassiveReminderError) -> PassiveAlert {
        switch error {
        case .backgroundRefreshUnavailable:
            return .backgroundRefreshUnavailable
        case .notificationPermissionDenied:
            return .notificationDenied
        case .locationPermissionDenied:
            return .locationDenied
        case .currentLocationUnavailable:
            return .currentLocationUnavailable
        case .geofenceRegistrationFailed:
            return .genericFailure
        }
    }

    private func makePassiveAlert(_ alert: PassiveAlert) -> Alert {
        switch alert {
        case .backgroundRefreshUnavailable:
            return Alert(
                title: Text(strings.backgroundRefreshUnavailableTitle),
                message: Text(strings.backgroundRefreshUnavailableBody),
                primaryButton: .default(Text(strings.openSettingsText), action: openAppSettings),
                secondaryButton: .cancel(Text(strings.notNowText))
            )
        case .notificationDenied:
            return Alert(
                title: Text(strings.nearbyMemoryRemindersPermissionTitle),
                message: Text(strings.nearbyMemoryRemindersNotificationDeniedBody),
                primaryButton: .default(Text(strings.openSettingsText), action: openAppSettings),
                secondaryButton: .cancel(Text(strings.notNowText))
            )
        case .locationDenied:
            return Alert(
                title: Text(strings.nearbyMemoryRemindersPermissionTitle),
                message: Text(strings.nearbyMemoryRemindersLocationDeniedBody),
                primaryButton: .default(Text(strings.openSettingsText), action: openAppSettings),
                secondaryButton: .cancel(Text(strings.notNowText))
            )
        case .currentLocationUnavailable:
            return Alert(
                title: Text(strings.nearbyMemoryRemindersPermissionTitle),
                message: Text(strings.nearbyMemoryRemindersLocationUnavailableBody),
                dismissButton: .default(Text(strings.closeText))
            )
        case .genericFailure:
            return Alert(
                title: Text(strings.nearbyMemoryRemindersPermissionTitle),
                message: Text(strings.nearbyMemoryRemindersGenericFailureBody),
                dismissButton: .default(Text(strings.closeText))
            )
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }
}

struct AboutView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.space24) {
                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                    Text(strings.aboutText)
                        .dsTextStyle(.title, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text(strings.aboutBody)
                        .dsTextStyle(.body)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineSpacing(DSLineSpacing.body)
                }
                .dsReadableContent()

                GroupBox {
                    Text(strings.demoNotesBody)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DSSpacing.space4)
                } label: {
                    Text(strings.demoNotesTitle)
                        .dsTextStyle(.headline)
                }
                .dsReadableContent()
            }
            .padding(.horizontal, DSSpacing.space24)
            .padding(.vertical, DSSpacing.space16)
        }
        .navigationTitle(strings.aboutText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
