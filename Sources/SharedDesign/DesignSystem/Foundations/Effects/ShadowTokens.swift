import SwiftUI

// MARK: - DefaultShadowTokens

/// Default implementation of shadow tokens using color palette
public struct DefaultShadowTokens: ShadowTokens {
    // MARK: Lifecycle

    public init(colors: ColorTokens) {
        self.colors = colors
    }

    // MARK: Public

    public var none: ShadowStyle {
        ShadowStyle(
            color: .clear,
            radius: 0,
            x: 0,
            y: 0
        )
    }

    public var small: ShadowStyle {
        ShadowStyle(
            color: self.colors.overlayLight,
            radius: 4,
            x: 0,
            y: 2
        )
    }

    public var medium: ShadowStyle {
        ShadowStyle(
            color: self.colors.overlayLight,
            radius: 8,
            x: 0,
            y: 4
        )
    }

    public var large: ShadowStyle {
        ShadowStyle(
            color: self.colors.overlayMedium.opacity(0.5),
            radius: 16,
            x: 0,
            y: 8
        )
    }

    public var xl: ShadowStyle {
        ShadowStyle(
            color: self.colors.overlayMedium.opacity(0.5),
            radius: 24,
            x: 0,
            y: 12
        )
    }

    // MARK: Private

    private let colors: ColorTokens
}

// MARK: - ShadowModifier

/// View modifier for applying shadows
public struct ShadowModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .shadow(
                color: self.shadow.color,
                radius: self.shadow.radius,
                x: self.shadow.x,
                y: self.shadow.y
            )
    }

    // MARK: Internal

    let shadow: ShadowStyle
}

extension View {
    /// Apply a shadow style from the theme
    public func shadow(_ style: ShadowStyle) -> some View {
        modifier(ShadowModifier(shadow: style))
    }
}
