import SwiftUI

// MARK: - Theme

/// Core theme protocol that defines all design tokens for the app
public protocol Theme {
    var colors: ColorTokens { get }
    var typography: TypographyTokens { get }
    var spacing: SpacingTokens { get }
    var sizing: SizingTokens { get }
    var shadows: ShadowTokens { get }
    var elevations: ElevationTokens { get }
    var animations: AnimationTokens { get }
    var gradients: GradientTokens { get }
}

// MARK: - DefaultTheme

/// Default theme implementation that requires color scheme
public struct DefaultTheme: Theme {
    // MARK: Lifecycle

    public init(colorScheme: ColorScheme = .light) {
        // Create palette once during initialization
        self.colors = colorScheme == .dark ? DarkColorPalette() : LightColorPalette()
        self.shadows = DefaultShadowTokens(colors: self.colors)
        self.elevations = DefaultElevationTokens(colors: self.colors, shadows: self.shadows)
        self.gradients = GradientTokens(colorScheme: colorScheme)
    }

    // MARK: Public

    public let colors: ColorTokens
    public let typography: TypographyTokens = DefaultTypographyTokens()
    public let spacing: SpacingTokens = DefaultSpacingTokens()
    public let sizing: SizingTokens = DefaultSizingTokens()
    public let shadows: ShadowTokens
    public let elevations: ElevationTokens
    public let animations: AnimationTokens = DefaultAnimationTokens()
    public let gradients: GradientTokens
}

// MARK: - ThemeKey

/// Environment key for theme access
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = DefaultTheme()
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - ThemeModifier

/// View modifier for applying theme
public struct ThemeModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .environment(\.theme, self.theme)
    }

    // MARK: Internal

    let theme: Theme
}

extension View {
    /// Apply a theme to this view hierarchy
    public func theme(_ theme: Theme) -> some View {
        modifier(ThemeModifier(theme: theme))
    }
}
