import SwiftUI

// MARK: - GradientTokens

/// Gradient definitions for the design system
public struct GradientTokens {
    // MARK: Lifecycle

    public init(colorScheme: ColorScheme = .light) {
        self.colorScheme = colorScheme
    }

    // MARK: Public

    // MARK: - Brand Gradients (Niora Design System v2)

    /// Primary brand gradient (Vital Orange to Light Orange)
    public var brandPrimary: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0xFF9500), // Orange
                Color(hex: 0xFF8E78) // Light Orange
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Secondary brand gradient (Pulse Purple to Sky Blue)
    public var brandSecondary: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.PulsePurple.shade400,
                ColorPalette.SkyClarityBlue.shade200
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Success gradient (Deep Wellness Green shades)
    public var success: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.DeepWellnessGreen.shade500,
                ColorPalette.DeepWellnessGreen.shade300
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Premium/Paywall Gradients

    /// Premium gradient for subscription screens (Niora Design System v2)
    public var premium: LinearGradient {
        LinearGradient(
            colors: self.colorScheme == .dark
                ? [
                    ColorPalette.SunriseAmber.shade500,
                    Color(hex: 0xFFA500), // Orange
                    ColorPalette.PulsePurple.shade300
                ]
                : [
                    ColorPalette.SunriseAmber.shade500,
                    Color(hex: 0xFFA500), // Orange
                    ColorPalette.PulsePurple.shade400
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Dark premium gradient for contrast
    public var premiumDark: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0x1C1C1E), // Dark gray
                Color(hex: 0x2C2C2E), // Medium gray
                ColorPalette.GreyNeutral.shade400 // Light gray (~0x3A3A3A)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Onboarding Gradients

    /// Onboarding welcome gradient (Niora Design System v2)
    public var onboardingPrimary: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0xFF9500).opacity(0.9), // Orange
                Color(hex: 0xFF8E78).opacity(0.9), // Light Orange
                ColorPalette.PulsePurple.shade400.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Onboarding background gradient
    public var onboardingBackground: LinearGradient {
        LinearGradient(
            colors: self.colorScheme == .dark
                ? [
                    Color.black,
                    Color(hex: 0x1C1C1E)
                ]
                : [
                    Color.white,
                    Color(hex: 0xF2F2F7)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Feature Gradients

    /// Fitness gradient
    public var fitness: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.Fitness.calories, // Orange
                ColorPalette.Fitness.heartRate // Red
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Nutrition gradient
    public var nutrition: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.Nutrition.protein, // Blue
                ColorPalette.Nutrition.carbs // Orange
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Overlay Gradients

    /// Dark overlay gradient for text readability
    public var darkOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.0),
                Color.black.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Light overlay gradient
    public var lightOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Radial Gradients

    /// Premium radial gradient (Niora Design System v2)
    public var premiumRadial: RadialGradient {
        RadialGradient(
            colors: [
                ColorPalette.SunriseAmber.shade500.opacity(0.8),
                Color(hex: 0xFF9500).opacity(0.9), // Orange
                ColorPalette.PulsePurple.shade400.opacity(0.4),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }

    /// Glow effect gradient (Niora Design System v2)
    public var glow: RadialGradient {
        RadialGradient(
            colors: [
                Color(hex: 0xFF9500).opacity(0.3),
                ColorPalette.VitalOrange.shade500.opacity(0.1),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }

    // MARK: - Background Gradients

    /// Subtle page background gradient for full-screen views
    /// Creates a unified, calming background across tabs, sheets, and pushed views
    /// Note: For dynamic theme support, use the `pageBackgroundGradient()` view modifier instead
    public func pageBackground(primary: Color, success: Color) -> LinearGradient {
        LinearGradient(
            colors: self.colorScheme == .dark
                ? [
                    primary.opacity(0.08), // Subtle orange at top (dark mode)
                    Color.black // Black at bottom (dark mode)
                ]
                : [
                    primary.opacity(0.18), // Orange tint
                    success.opacity(0.12) // Green tint
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Private

    private let colorScheme: ColorScheme
}

// MARK: - PageBackgroundModifier

/// Applies the unified page background gradient to a view
public struct PageBackgroundModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .background(
                GradientTokens(colorScheme: self.colorScheme)
                    .pageBackground(
                        primary: self.theme.colors.primary.opacity(0.7),
                        success: self.theme.colors.success
                    )
                    .ignoresSafeArea()
            )
    }

    // MARK: Private

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme
}

// MARK: - View Extensions

extension View {
    /// Apply a gradient background
    public func gradientBackground(_ gradient: LinearGradient) -> some View {
        self.background(gradient)
    }

    /// Apply a gradient overlay
    public func gradientOverlay(_ gradient: LinearGradient) -> some View {
        self.overlay(gradient)
    }

    /// Apply a gradient mask
    public func gradientMask(_ gradient: LinearGradient) -> some View {
        self.mask(gradient)
    }

    /// Apply the unified page background gradient
    /// Use this on full-screen views (tabs, sheets, pushed views, fullScreenCovers)
    /// to create a consistent, calming aesthetic across the app
    ///
    /// Example:
    /// ```swift
    /// var body: some View {
    ///     VStack {
    ///         // Your content
    ///     }
    ///     .pageBackgroundGradient()
    /// }
    /// ```
    public func pageBackgroundGradient() -> some View {
        modifier(PageBackgroundModifier())
    }
}

// MARK: - GradientCard

/// A card with gradient background
public struct GradientCard<Content: View>: View {
    // MARK: Lifecycle

    public init(
        gradient: LinearGradient,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradient = gradient
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        self.content()
            .padding(self.theme.spacing.lg)
            .background(self.gradient)
            .cornerRadius(self.theme.sizing.cornerRadius.large)
    }

    // MARK: Internal

    let gradient: LinearGradient
    let content: () -> Content

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - PremiumBadge

/// A premium badge with gradient
public struct PremiumBadge: View {
    // MARK: Lifecycle

    public init(_ text: String = "PRO") {
        self.text = text
    }

    // MARK: Public

    public var body: some View {
        Text(self.text)
            .font(self.theme.typography.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, self.theme.spacing.sm)
            .padding(.vertical, self.theme.spacing.xxs)
            .background(
                Capsule()
                    .fill(GradientTokens().premium)
            )
    }

    // MARK: Internal

    let text: String

    // MARK: Private

    @Environment(\.theme) private var theme
}
