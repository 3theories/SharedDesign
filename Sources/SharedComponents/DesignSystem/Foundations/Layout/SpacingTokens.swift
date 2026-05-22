import SwiftUI

// MARK: - DefaultSpacingTokens

/// Default implementation of spacing tokens
public struct DefaultSpacingTokens: SpacingTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    /// 4pt - Minimal spacing for tight layouts
    public var xxs: CGFloat { 4 }

    /// 8pt - Small spacing between related elements
    public var xs: CGFloat { 8 }

    /// 12pt - Compact spacing for grouped items
    public var sm: CGFloat { 12 }

    /// 16pt - Standard spacing (default padding)
    public var md: CGFloat { 16 }

    /// 24pt - Large spacing between sections
    public var lg: CGFloat { 24 }

    /// 32pt - Extra large spacing for major sections
    public var xl: CGFloat { 32 }

    /// 48pt - Huge spacing for prominent separation
    public var xxl: CGFloat { 48 }

    /// 64pt - Maximum spacing for hero sections
    public var xxxl: CGFloat { 64 }
}

// MARK: - Spacing

/// Spacing utilities for common use cases
public enum Spacing {
    /// Stack spacing values
    public enum Stack: CGFloat, CaseIterable {
        case tight = 4
        case compact = 8
        case standard = 12
        case loose = 16
        case relaxed = 24
    }

    /// Padding values for containers
    public enum Padding: CGFloat, CaseIterable {
        case minimal = 8
        case compact = 12
        case standard = 16
        case comfortable = 20
        case spacious = 24
        case luxurious = 32
    }

    /// Margin values for layout
    public enum Margin: CGFloat, CaseIterable {
        case small = 16
        case medium = 20
        case large = 24
        case xlarge = 32
    }

    /// Grid spacing values
    public enum Grid: CGFloat, CaseIterable {
        case tight = 8
        case standard = 16
        case loose = 24
    }

    /// Safe area insets
    public enum SafeArea: CGFloat, CaseIterable {
        case minimal = 8
        case standard = 16
        case extended = 24
    }

    /// Widget-specific spacing
    public enum Widget: CGFloat, CaseIterable {
        case minimal = 2
        case tight = 4
        case compact = 6
        case small = 7
        case standard = 8
        case medium = 10
        case comfortable = 12
        case large = 14
        case spacious = 16
    }
}

// MARK: - EdgeInsetsPreset

/// Edge insets preset configurations
public enum EdgeInsetsPreset: CaseIterable {
    case zero
    case minimal
    case compact
    case standard
    case comfortable
    case spacious
    case listItem
    case cardContent
    case section

    // MARK: Public

    public var insets: EdgeInsets {
        switch self {
        case .zero:
            EdgeInsets()
        case .minimal:
            EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        case .compact:
            EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .standard:
            EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .comfortable:
            EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        case .spacious:
            EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        case .listItem:
            EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .cardContent:
            EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .section:
            EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)
        }
    }
}
