import SwiftUI

struct DSPrimaryCTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTextStyle(.body, weight: .semibold)
            .foregroundStyle(DSColor.accentOnPrimary)
            .padding(.horizontal, DSSpacing.space16)
            .frame(minHeight: DSControl.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                    .fill(DSColor.accentPrimary)
                    .opacity(
                        isEnabled
                            ? (configuration.isPressed ? DSOpacity.primaryPressed : 1)
                            : DSOpacity.controlDisabled
                    )
            )
    }
}

struct DSSecondaryCTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTextStyle(.body, weight: .semibold)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.space16)
            .frame(minHeight: DSControl.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                    .fill(DSColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                    .stroke(
                        DSColor.borderSubtle.opacity(
                            isEnabled ? DSOpacity.secondaryBorderEnabled : DSOpacity.secondaryBorderDisabled
                        ),
                        lineWidth: DSBorder.bw1
                    )
            )
            .opacity(configuration.isPressed ? DSOpacity.secondaryPressed : 1)
    }
}

struct DSSurfaceCardModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                    .fill(isSelected ? DSColor.surfaceElevated : DSColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                    .stroke(
                        isSelected ? DSColor.borderStrong : DSColor.borderSubtle.opacity(DSOpacity.subtleBorder),
                        lineWidth: DSBorder.bw1
                    )
            )
    }
}

extension View {
    func dsPrimaryCTAStyle() -> some View {
        buttonStyle(DSPrimaryCTAButtonStyle())
    }

    func dsSecondaryCTAStyle() -> some View {
        buttonStyle(DSSecondaryCTAButtonStyle())
    }

    func dsSurfaceCard(isSelected: Bool = false) -> some View {
        modifier(DSSurfaceCardModifier(isSelected: isSelected))
    }
}
