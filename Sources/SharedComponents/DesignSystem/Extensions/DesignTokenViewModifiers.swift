import SwiftUI

// MARK: - SpacingToken

/// Spacing token enum for convenient access to spacing values
public enum SpacingToken {
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
    case xxxl

    // MARK: Public

    /// Get the spacing value from theme
    public func value(from theme: Theme) -> CGFloat {
        switch self {
        case .xxs: theme.spacing.xxs
        case .xs: theme.spacing.xs
        case .sm: theme.spacing.sm
        case .md: theme.spacing.md
        case .lg: theme.spacing.lg
        case .xl: theme.spacing.xl
        case .xxl: theme.spacing.xxl
        case .xxxl: theme.spacing.xxxl
        }
    }
}

// MARK: - TypographyStyle

/// Typography style enum for convenient access to typography tokens
public enum TypographyStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2

    // MARK: Public

    /// Get the font from theme
    public func font(from theme: Theme) -> Font {
        switch self {
        case .largeTitle: theme.typography.largeTitle
        case .title1: theme.typography.title1
        case .title2: theme.typography.title2
        case .title3: theme.typography.title3
        case .headline: theme.typography.headline
        case .body: theme.typography.body
        case .callout: theme.typography.callout
        case .subheadline: theme.typography.subheadline
        case .footnote: theme.typography.footnote
        case .caption1: theme.typography.caption1
        case .caption2: theme.typography.caption2
        }
    }
}

// MARK: - CornerRadiusSize

/// Corner radius size enum for convenient access to corner radius tokens
public enum CornerRadiusSize {
    case small
    case medium
    case large
    case xl

    // MARK: Public

    /// Get the corner radius value from theme
    public func value(from theme: Theme) -> CGFloat {
        switch self {
        case .small: theme.sizing.cornerRadius.small
        case .medium: theme.sizing.cornerRadius.medium
        case .large: theme.sizing.cornerRadius.large
        case .xl: theme.sizing.cornerRadius.xl
        }
    }
}

// MARK: - ThemeColor

/// Theme color enum for convenient access to theme colors
public enum ThemeColor {
    case primary
    case secondary
    case tertiary
    case background
    case surface
    case surface2
    case surface3
    case textPrimary
    case textSecondary
    case textTertiary
    case error
    case success
    case warning

    // MARK: Public

    /// Get the color from theme
    public func color(from theme: Theme) -> Color {
        switch self {
        case .primary: theme.colors.primary
        case .secondary: theme.colors.secondary
        case .tertiary: theme.colors.tertiary
        case .background: theme.colors.background
        case .surface: theme.colors.surface
        case .surface2: theme.colors.surface2
        case .surface3: theme.colors.surface3
        case .textPrimary: theme.colors.textPrimary
        case .textSecondary: theme.colors.textSecondary
        case .textTertiary: theme.colors.textTertiary
        case .error: theme.colors.error
        case .success: theme.colors.success
        case .warning: theme.colors.warning
        }
    }
}

// MARK: - Stack Spacing Helper

extension VStack {
    /// Create VStack with spacing token
    public init(
        spacing token: SpacingToken,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        // Note: This requires accessing theme which isn't available in init
        // Users should use: VStack(spacing: theme.spacing.md) { }
        // Or we provide a custom VStackWithToken view
        self.init(alignment: alignment, spacing: nil, content: content)
    }
}
