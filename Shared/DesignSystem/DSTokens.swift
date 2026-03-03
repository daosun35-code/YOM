import SwiftUI

enum DSColor {
    static let surfacePrimary = Color(uiColor: .systemBackground)
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    static let surfaceElevated = Color(uiColor: .tertiarySystemBackground)

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textInverse = Color(uiColor: .systemBackground)

    static let accentPrimary = Color.accentColor
    static let accentOnPrimary = Color(uiColor: .systemBackground)

    static let borderSubtle = Color(uiColor: .separator)
    static let borderStrong = Color.accentColor.opacity(DSOpacity.controlDisabled)

    static let statusSuccess = Color(uiColor: .systemGreen)
    static let statusWarning = Color(uiColor: .systemOrange)
    static let statusError = Color(uiColor: .systemRed)
}

enum DSSpacing {
    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
}

enum DSRadius {
    static let r8: CGFloat = 8
    static let r12: CGFloat = 12
    static let r16: CGFloat = 16
}

enum DSBorder {
    static let bw1: CGFloat = 1
    static let bw2: CGFloat = 2
    static let routeLine: CGFloat = bw2 * 3
}

enum DSLineSpacing {
    static let body: CGFloat = 3
}

enum DSOpacity {
    static let subtleBorder: Double = 0.55
    static let controlDisabled: Double = 0.45
    static let primaryPressed: Double = 0.82
    static let secondaryPressed: Double = 0.9
    static let secondaryBorderEnabled: Double = 0.7
    static let secondaryBorderDisabled: Double = 0.4
    static let overlayShadow: Double = controlDisabled
}

enum DSMotion {
    static let durationFast = 0.2
    static let durationNormal = 0.35

    static func shell(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: durationFast)
            : .spring(response: durationNormal, dampingFraction: 0.9)
    }

    static func routeTransition(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: durationFast)
            : .spring(response: durationNormal, dampingFraction: 0.88)
    }
}

enum DSLayout {
    static let readableContentMaxWidth: CGFloat = 680
    static let onboardingContentMaxWidth: CGFloat = 520
}

enum DSControl {
    static let minTouchTarget: CGFloat = 44
    static let largeButtonHeight: CGFloat = 52
    static let listThumbnailSize: CGFloat = 64
    static let listItemMinHeight: CGFloat = 72
    static let navigationBannerHeight: CGFloat = 72
    static let floatingActionTopInsetWithBanner: CGFloat = 68
    static let detailHeroHeight: CGFloat = 220
    static let overlayPanelMaxHeight: CGFloat = 280
    static let searchPanelMaxWidth: CGFloat = 360
}
