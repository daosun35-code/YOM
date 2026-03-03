import SwiftUI

enum DSTextStyle {
    case display
    case title
    case headline
    case body
    case caption

    var font: Font {
        switch self {
        case .display:
            return .largeTitle
        case .title:
            return .title2
        case .headline:
            return .headline
        case .body:
            return .body
        case .caption:
            return .caption
        }
    }
}

enum DSTypography {
    static let brandDisplay = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let iconLarge = Font.title2
    static let iconMedium = Font.body
}

extension View {
    func dsTextStyle(_ style: DSTextStyle, weight: Font.Weight? = nil) -> some View {
        font(style.font)
            .fontWeight(weight)
    }
}
