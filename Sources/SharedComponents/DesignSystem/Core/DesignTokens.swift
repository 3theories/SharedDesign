import SwiftUI

// MARK: - DesignTokens

/// Base protocol for all design token types
public protocol DesignTokens { }

// MARK: - ColorTokens

/// Color tokens protocol
public protocol ColorTokens: DesignTokens {
    // Primary colors
    var primary: Color { get }
    var secondary: Color { get }
    var tertiary: Color { get }

    // Accent colors
    var accent: Color { get }
    var accentLight: Color { get } // Light Orange - Niora Design System v2
    var accentGold: Color { get }
    var accentPink: Color { get }

    // Surface colors - Extended hierarchy
    var background: Color { get }
    var surface: Color { get } // Alias for surface1
    var elevated: Color { get } // Alias for surface2

    // Surface levels
    var surface0: Color { get }
    var surface1: Color { get }
    var surface2: Color { get }
    var surface3: Color { get }
    var surface4: Color { get }
    var surface5: Color { get }

    // System surface mappings
    var systemGroupedBackground: Color { get }
    var systemSecondaryBackground: Color { get }
    var systemTertiaryBackground: Color { get }

    // Fill colors
    var fillPrimary: Color { get }
    var fillSecondary: Color { get }
    var fillTertiary: Color { get }
    var fillQuaternary: Color { get }

    // Content colors
    var onPrimary: Color { get }
    var onSecondary: Color { get }
    var onTertiary: Color { get }
    var onBackground: Color { get }
    var onSurface: Color { get }
    var onElevated: Color { get }

    // Text colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var textDisabled: Color { get }
    var textInverse: Color { get }

    // Border colors
    var borderPrimary: Color { get }
    var borderSecondary: Color { get }
    var borderTertiary: Color { get }
    var borderFocus: Color { get }
    var borderError: Color { get }

    // Semantic colors
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }

    // Semantic background colors
    var successBackground: Color { get }
    var warningBackground: Color { get }
    var errorBackground: Color { get }
    var infoBackground: Color { get }

    // Overlay colors
    var overlayLight: Color { get }
    var overlayMedium: Color { get }
    var overlayHeavy: Color { get }

    // Special colors
    var clear: Color { get }
    var shadow: Color { get }

    // Nutrient colors
    var nutrientProtein: Color { get }
    var nutrientCarbs: Color { get }
    var nutrientFat: Color { get }
    var nutrientWater: Color { get }
}

// MARK: - TypographyTokens

/// Typography tokens protocol
public protocol TypographyTokens: DesignTokens {
    var largeTitle: Font { get }
    var title1: Font { get }
    var title2: Font { get }
    var title3: Font { get }
    var headline: Font { get }
    var body: Font { get }
    var callout: Font { get }
    var subheadline: Font { get }
    var footnote: Font { get }
    var caption1: Font { get }
    var caption2: Font { get }
}

// MARK: - SpacingTokens

/// Spacing tokens protocol
public protocol SpacingTokens: DesignTokens {
    var xxs: CGFloat { get }
    var xs: CGFloat { get }
    var sm: CGFloat { get }
    var md: CGFloat { get }
    var lg: CGFloat { get }
    var xl: CGFloat { get }
    var xxl: CGFloat { get }
    var xxxl: CGFloat { get }
}

// MARK: - SizingTokens

/// Sizing tokens protocol
public protocol SizingTokens: DesignTokens {
    var buttonHeight: SizeScale { get }
    var cornerRadius: SizeScale { get }
    var iconSize: SizeScale { get }
    var borderWidth: SizeScale { get }
}

// MARK: - SizeScale

/// Size scale for different component sizes
public struct SizeScale {
    // MARK: Lifecycle

    public init(small: CGFloat, medium: CGFloat, large: CGFloat, xl: CGFloat) {
        self.small = small
        self.medium = medium
        self.large = large
        self.xl = xl
    }

    // MARK: Public

    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let xl: CGFloat
}

// MARK: - ShadowTokens

/// Shadow tokens protocol
public protocol ShadowTokens: DesignTokens {
    var none: ShadowStyle { get }
    var small: ShadowStyle { get }
    var medium: ShadowStyle { get }
    var large: ShadowStyle { get }
    var xl: ShadowStyle { get }
}

// MARK: - ShadowStyle

/// Shadow style definition
public struct ShadowStyle {
    // MARK: Lifecycle

    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    // MARK: Public

    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

// MARK: - AnimationTokens

/// Animation tokens protocol
public protocol AnimationTokens: DesignTokens {
    var spring: Animation { get }
    var smooth: Animation { get }
    var quick: Animation { get }
    var bounce: Animation { get }
    var easeIn: Animation { get }
    var easeOut: Animation { get }
}
