import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - FontFamily

/// Font family definitions - Niora Design System v2
public enum FontFamily {
    // MARK: Public

    // Custom fonts
    public static let headline = "InstrumentSans" // For headlines, titles, buttons
    public static let body = "Manrope" // For body text, descriptions

    // System fonts (retained for specific uses)
    public static let rounded = "SF Pro Rounded" // For metrics/numbers
    public static let mono = "SF Mono" // For code

    /// Register custom fonts from the bundle (call once at app launch)
    public static func registerFonts() {
        let fontNames = [
            "InstrumentSans-Bold",
            "InstrumentSans-SemiBold",
            "InstrumentSans-Medium",
            "InstrumentSans-Regular",
            "Manrope-Bold",
            "Manrope-SemiBold",
            "Manrope-Medium",
            "Manrope-Regular"
        ]

        for fontName in fontNames {
            self.registerFont(named: fontName)
        }
    }

    /// Create a custom font with fallback to system font
    public static func custom(
        _ name: String,
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        // Map weight to font file suffix
        let suffix =
            switch weight {
            case .bold, .heavy, .black:
                "-Bold"
            case .semibold:
                "-SemiBold"
            case .medium:
                "-Medium"
            default:
                "-Regular"
            }

        let fontName = "\(name)\(suffix)"
        return Font.custom(fontName, size: size, relativeTo: textStyle)
    }

    /// Headline font (Instrument Sans)
    public static func headlineFont(
        size: CGFloat,
        weight: Font.Weight = .semibold,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        self.custom(self.headline, size: size, weight: weight, relativeTo: textStyle)
    }

    /// Body font (Manrope)
    public static func bodyFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        self.custom(self.body, size: size, weight: weight, relativeTo: textStyle)
    }

    public static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }

    // MARK: Private

    private static func registerFont(named fontName: String) {
        guard let fontURL = Bundle.module.url(forResource: fontName, withExtension: "ttf"),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            print("Failed to load font: \(fontName)")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            if let error = error?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(error)
                // Font may already be registered, which is fine
                if !String(describing: errorDescription).contains("already registered") {
                    print("Error registering font \(fontName): \(String(describing: errorDescription))")
                }
            }
        }
    }
}

// MARK: - FontWeights

/// Font weight definitions
public enum FontWeights {
    public static let ultraLight: Font.Weight = .ultraLight
    public static let thin: Font.Weight = .thin
    public static let light: Font.Weight = .light
    public static let regular: Font.Weight = .regular
    public static let medium: Font.Weight = .medium
    public static let semibold: Font.Weight = .semibold
    public static let bold: Font.Weight = .bold
    public static let heavy: Font.Weight = .heavy
    public static let black: Font.Weight = .black
}

// MARK: - DefaultTypographyTokens

/// Default implementation of typography tokens - Niora Design System v2
/// Headlines use Instrument Sans, body text uses Manrope
public struct DefaultTypographyTokens: TypographyTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    /// Headlines - Instrument Sans
    public var largeTitle: Font {
        FontFamily.headlineFont(size: 34, weight: .bold, relativeTo: .largeTitle)
    }

    public var title1: Font {
        FontFamily.headlineFont(size: 28, weight: .bold, relativeTo: .title)
    }

    public var title2: Font {
        FontFamily.headlineFont(size: 22, weight: .bold, relativeTo: .title2)
    }

    public var title3: Font {
        FontFamily.headlineFont(size: 20, weight: .semibold, relativeTo: .title3)
    }

    public var headline: Font {
        FontFamily.headlineFont(size: 17, weight: .semibold, relativeTo: .headline)
    }

    /// Body text - Manrope (medium weight for better legibility)
    public var body: Font {
        FontFamily.bodyFont(size: 17, weight: .medium, relativeTo: .body)
    }

    public var callout: Font {
        FontFamily.bodyFont(size: 16, weight: .medium, relativeTo: .callout)
    }

    public var subheadline: Font {
        FontFamily.bodyFont(size: 15, weight: .medium, relativeTo: .subheadline)
    }

    public var footnote: Font {
        FontFamily.bodyFont(size: 14, weight: .medium, relativeTo: .footnote)
    }

    public var caption1: Font {
        FontFamily.bodyFont(size: 13, weight: .medium, relativeTo: .caption)
    }

    public var caption2: Font {
        FontFamily.bodyFont(size: 12, weight: .medium, relativeTo: .caption2)
    }
}

// MARK: - ExtendedTypography

/// Extended typography styles for specific use cases - Niora Design System v2
public enum ExtendedTypography {
    /// Display styles for large, impactful text (Instrument Sans)
    public static let display1 = FontFamily.headlineFont(size: 56, weight: .bold, relativeTo: .largeTitle)
    public static let display2 = FontFamily.headlineFont(size: 45, weight: .bold, relativeTo: .largeTitle)
    public static let display3 = FontFamily.headlineFont(size: 36, weight: .bold, relativeTo: .largeTitle)

    /// Metric styles for numbers and data (SF Pro Rounded - retained for numeric clarity)
    public static let metricLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    public static let metricMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    public static let metricSmall = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Button styles (Instrument Sans)
    public static let buttonLarge = FontFamily.headlineFont(size: 16, weight: .semibold, relativeTo: .headline)
    public static let buttonMedium = FontFamily.headlineFont(size: 14, weight: .semibold, relativeTo: .callout)
    public static let buttonSmall = FontFamily.headlineFont(size: 12, weight: .semibold, relativeTo: .footnote)

    /// Navigation styles (Instrument Sans)
    public static let navTitle = FontFamily.headlineFont(size: 17, weight: .semibold, relativeTo: .headline)
    public static let tabLabel = FontFamily.bodyFont(size: 10, weight: .medium, relativeTo: .caption2)

    /// Form styles (Manrope)
    public static let formLabel = FontFamily.bodyFont(size: 15, weight: .medium, relativeTo: .subheadline)
    public static let formInput = FontFamily.bodyFont(size: 17, weight: .regular, relativeTo: .body)
    public static let formHelper = FontFamily.bodyFont(size: 13, weight: .regular, relativeTo: .caption)

    /// Card title style (SF Pro Rounded - used for hero overlay cards)
    public static let cardTitle = Font.system(size: 24, weight: .bold, design: .rounded)

    /// Code and monospaced styles (System - retained)
    public static let codeLarge = Font.system(size: 16, weight: .regular, design: .monospaced)
    public static let codeSmall = Font.system(size: 13, weight: .regular, design: .monospaced)

    /// Widget-specific styles (System fonts for widget reliability)
    public static let widgetTitle = Font.system(size: 16, weight: .bold, design: .default)
    public static let widgetHeadline = Font.system(size: 14, weight: .semibold, design: .default)
    public static let widgetBody = Font.system(size: 13, weight: .regular, design: .default)
    public static let widgetBodyBold = Font.system(size: 13, weight: .bold, design: .rounded)
    public static let widgetCaption = Font.system(size: 11, weight: .medium, design: .default)
    public static let widgetCaptionBold = Font.system(size: 11, weight: .bold, design: .default)
    public static let widgetXSmall = Font.system(size: 8, weight: .semibold, design: .default)
    public static let widgetSmall = Font.system(size: 10, weight: .semibold, design: .default)
    public static let widgetMetric = Font.system(size: 24, weight: .bold, design: .rounded)
    public static let widgetMetricLarge = Font.system(size: 22, weight: .bold, design: .rounded)
    public static let widgetIconSmall = Font.system(size: 18, weight: .semibold, design: .default)
    public static let widgetIcon = Font.system(size: 22, weight: .semibold, design: .default)
    public static let widgetIconLarge = Font.system(size: 28, weight: .semibold, design: .default)
    public static let widgetButton = Font.system(size: 13, weight: .semibold, design: .default)
    public static let widgetButtonSmall = Font.system(size: 12, weight: .bold, design: .default)
}
