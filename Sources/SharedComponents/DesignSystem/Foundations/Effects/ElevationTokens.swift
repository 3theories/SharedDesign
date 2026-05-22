import SwiftUI

// MARK: - ElevationLevel

/// Semantic elevation levels for consistent visual hierarchy
public enum ElevationLevel: Int, CaseIterable, Sendable {
    /// Flat content with no elevation - embedded in surface
    case none = 0

    /// Subtle elevation for list items, chips, input fields
    case low = 1

    /// Standard elevation for cards, tiles, grouped content
    case medium = 2

    /// High elevation for floating elements, popovers, FABs
    case high = 3

    /// Maximum elevation for sheets, modals, overlays
    case overlay = 4
}

// MARK: - ElevationStyle

/// Complete elevation style combining surface, shadow, border, and corner radius
public struct ElevationStyle: Sendable {
    // MARK: Lifecycle

    public init(
        level: ElevationLevel,
        backgroundColor: Color,
        shadow: ShadowStyle,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0,
        cornerRadius: CGFloat = 12
    ) {
        self.level = level
        self.backgroundColor = backgroundColor
        self.shadow = shadow
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }

    // MARK: Public

    public let level: ElevationLevel
    public let backgroundColor: Color
    public let shadow: ShadowStyle
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
}

// MARK: - ElevationTokens

/// Protocol defining elevation styles for the design system
public protocol ElevationTokens: DesignTokens {
    /// No elevation - flat content
    var none: ElevationStyle { get }

    /// Low elevation - chips, list items
    var low: ElevationStyle { get }

    /// Medium elevation - standard cards
    var medium: ElevationStyle { get }

    /// High elevation - floating elements
    var high: ElevationStyle { get }

    /// Overlay elevation - sheets, modals
    var overlay: ElevationStyle { get }

    /// Get elevation style for a specific level
    func style(for level: ElevationLevel) -> ElevationStyle
}

// MARK: - DefaultElevationTokens

/// Default elevation tokens implementation
public struct DefaultElevationTokens: ElevationTokens {
    // MARK: Lifecycle

    public init(colors: ColorTokens, shadows: ShadowTokens) {
        self.colors = colors
        self.shadows = shadows
    }

    // MARK: Public

    public var none: ElevationStyle {
        ElevationStyle(
            level: .none,
            backgroundColor: self.colors.surface0,
            shadow: self.shadows.none,
            borderColor: .clear,
            borderWidth: 0,
            cornerRadius: 0
        )
    }

    public var low: ElevationStyle {
        ElevationStyle(
            level: .low,
            backgroundColor: self.colors.surface1,
            shadow: self.shadows.small,
            borderColor: self.colors.borderTertiary.opacity(0.3),
            borderWidth: 0.5,
            cornerRadius: 8
        )
    }

    public var medium: ElevationStyle {
        ElevationStyle(
            level: .medium,
            backgroundColor: self.colors.surface2,
            shadow: self.shadows.medium,
            borderColor: self.colors.borderTertiary.opacity(0.2),
            borderWidth: 0.5,
            cornerRadius: 12
        )
    }

    public var high: ElevationStyle {
        ElevationStyle(
            level: .high,
            backgroundColor: self.colors.surface3,
            shadow: self.shadows.large,
            borderColor: self.colors.borderSecondary.opacity(0.15),
            borderWidth: 0.5,
            cornerRadius: 16
        )
    }

    public var overlay: ElevationStyle {
        ElevationStyle(
            level: .overlay,
            backgroundColor: self.colors.surface4,
            shadow: self.shadows.xl,
            borderColor: self.colors.borderPrimary.opacity(0.1),
            borderWidth: 1,
            cornerRadius: 20
        )
    }

    public func style(for level: ElevationLevel) -> ElevationStyle {
        switch level {
        case .none: self.none
        case .low: self.low
        case .medium: self.medium
        case .high: self.high
        case .overlay: self.overlay
        }
    }

    // MARK: Private

    private let colors: ColorTokens
    private let shadows: ShadowTokens
}

// MARK: - ElevationModifier

/// View modifier for applying elevation styles
public struct ElevationModifier: ViewModifier {
    // MARK: Lifecycle

    public init(elevation: ElevationStyle, isInteractive: Bool = false) {
        self.elevation = elevation
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        content
            .background(self.elevation.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: self.elevation.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: self.elevation.cornerRadius)
                    .strokeBorder(
                        self.elevation.borderColor,
                        lineWidth: self.elevation.borderWidth
                    )
            )
            .shadow(self.elevation.shadow)
            .scaleEffect(self.isPressed && self.isInteractive ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .if(self.isInteractive) { view in
                view.simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in self.isPressed = true }
                        .onEnded { _ in self.isPressed = false }
                )
            }
    }

    // MARK: Internal

    let elevation: ElevationStyle
    let isInteractive: Bool

    // MARK: Private

    @State private var isPressed = false
}

// MARK: - View Extensions

extension View {
    /// Apply an elevation style to this view
    /// - Parameters:
    ///   - style: The elevation style to apply
    ///   - isInteractive: Whether to add press state feedback
    /// - Returns: A view with elevation applied
    public func elevation(_ style: ElevationStyle, isInteractive: Bool = false) -> some View {
        modifier(ElevationModifier(elevation: style, isInteractive: isInteractive))
    }

    /// Apply elevation for a specific level using the theme
    /// - Parameters:
    ///   - level: The elevation level to apply
    ///   - theme: The theme providing elevation tokens
    ///   - isInteractive: Whether to add press state feedback
    /// - Returns: A view with elevation applied
    public func elevation(
        _ level: ElevationLevel,
        from elevations: ElevationTokens,
        isInteractive: Bool = false
    ) -> some View {
        self.elevation(elevations.style(for: level), isInteractive: isInteractive)
    }
}

// MARK: - Conditional Modifier Helper

extension View {
    /// Apply a transform only if a condition is true
    @ViewBuilder
    public func conditionalModifier(
        _ condition: Bool,
        transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Convenience alias for conditionalModifier
    @ViewBuilder
    public func `if`(
        _ condition: Bool,
        transform: (Self) -> some View
    ) -> some View {
        self.conditionalModifier(condition, transform: transform)
    }
}
