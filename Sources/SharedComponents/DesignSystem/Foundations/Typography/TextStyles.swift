import SwiftUI

// MARK: - TextStyle

/// Predefined text styles with semantic names
public struct TextStyle {
    // MARK: Lifecycle

    public init(font: Font, lineSpacing: CGFloat = 0, tracking: CGFloat = 0) {
        self.font = font
        self.lineSpacing = lineSpacing
        self.tracking = tracking
    }

    // MARK: Public

    public let font: Font
    public let lineSpacing: CGFloat
    public let tracking: CGFloat
}

// MARK: - TextStyles

/// Collection of predefined text styles - Niora Design System v2
/// Headlines use Instrument Sans, body text uses Manrope, metrics use SF Pro Rounded
public enum TextStyles {
    /// Hero styles (Instrument Sans)
    public static let hero = TextStyle(
        font: FontFamily.headlineFont(size: 56, weight: .bold),
        lineSpacing: 4,
        tracking: -0.5
    )

    public static let heroSubtitle = TextStyle(
        font: FontFamily.bodyFont(size: 24, weight: .medium),
        lineSpacing: 2,
        tracking: 0
    )

    /// Section styles (Instrument Sans)
    public static let sectionTitle = TextStyle(
        font: FontFamily.headlineFont(size: 28, weight: .bold),
        lineSpacing: 2,
        tracking: -0.3
    )

    public static let sectionSubtitle = TextStyle(
        font: FontFamily.bodyFont(size: 18, weight: .medium),
        lineSpacing: 1,
        tracking: 0
    )

    /// Card styles
    public static let cardTitle = TextStyle(
        font: FontFamily.headlineFont(size: 20, weight: .semibold),
        lineSpacing: 1,
        tracking: -0.2
    )

    public static let cardBody = TextStyle(
        font: FontFamily.bodyFont(size: 16, weight: .regular),
        lineSpacing: 2,
        tracking: 0
    )

    /// Metric styles (SF Pro Rounded - retained for numeric clarity)
    public static let metricValue = TextStyle(
        font: .system(size: 36, weight: .bold, design: .rounded),
        lineSpacing: 0,
        tracking: -0.5
    )

    public static let metricLabel = TextStyle(
        font: FontFamily.bodyFont(size: 14, weight: .medium),
        lineSpacing: 0,
        tracking: 0.1
    )

    /// List styles (Manrope)
    public static let listItemTitle = TextStyle(
        font: FontFamily.bodyFont(size: 17, weight: .medium),
        lineSpacing: 0,
        tracking: 0
    )

    public static let listItemSubtitle = TextStyle(
        font: FontFamily.bodyFont(size: 15, weight: .regular),
        lineSpacing: 0,
        tracking: 0
    )

    /// Form styles (Manrope)
    public static let inputLabel = TextStyle(
        font: FontFamily.bodyFont(size: 15, weight: .medium),
        lineSpacing: 0,
        tracking: 0
    )

    public static let inputText = TextStyle(
        font: FontFamily.bodyFont(size: 17, weight: .regular),
        lineSpacing: 0,
        tracking: 0
    )

    public static let helperText = TextStyle(
        font: FontFamily.bodyFont(size: 13, weight: .regular),
        lineSpacing: 1,
        tracking: 0
    )

    public static let errorText = TextStyle(
        font: FontFamily.bodyFont(size: 13, weight: .medium),
        lineSpacing: 1,
        tracking: 0
    )

    // MARK: - Activity Styles (SF Pro Rounded - retained for glanceable numeric display)

    /// 72pt bold rounded for primary timer display
    public static let activityHero = TextStyle(
        font: .system(size: 72, weight: .bold, design: .rounded),
        lineSpacing: 0,
        tracking: -1
    )

    /// 48pt bold rounded for primary scores
    public static let activityPrimary = TextStyle(
        font: .system(size: 48, weight: .bold, design: .rounded),
        lineSpacing: 0,
        tracking: -0.5
    )

    /// 32pt semibold rounded for supporting metrics
    public static let activitySecondary = TextStyle(
        font: .system(size: 32, weight: .semibold, design: .rounded),
        lineSpacing: 0,
        tracking: -0.3
    )

    /// 11pt semibold with letter spacing for ALL CAPS labels (Instrument Sans)
    public static let activityLabel = TextStyle(
        font: FontFamily.headlineFont(size: 11, weight: .semibold),
        lineSpacing: 0,
        tracking: 1.5
    )

    /// 24pt semibold rounded for secondary activity metrics
    public static let activityMetric = TextStyle(
        font: .system(size: 24, weight: .semibold, design: .rounded),
        lineSpacing: 0,
        tracking: -0.2
    )

    /// 18pt medium for activity control labels (Instrument Sans)
    public static let activityControl = TextStyle(
        font: FontFamily.headlineFont(size: 18, weight: .semibold),
        lineSpacing: 0,
        tracking: 0
    )
}

// MARK: - TextStyleModifier

/// View modifier for applying text styles
public struct TextStyleModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .font(self.style.font)
            .tracking(self.style.tracking)
            .lineSpacing(self.style.lineSpacing)
    }

    // MARK: Internal

    let style: TextStyle
}

extension View {
    /// Apply a predefined text style
    public func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

extension Text {
    /// Apply a predefined text style to Text
    public func style(_ style: TextStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}
