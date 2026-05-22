import SwiftUI

/// Dark mode color palette - true black theme
public struct DarkColorPalette: ColorTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    // MARK: - Brand Colors (Niora Design System v3)

    public var primary: Color { ColorPalette.VitalOrange.shade300 }
    public var secondary: Color { ColorPalette.SkyClarityBlue.shade500 }
    public var tertiary: Color { Color(hex: 0x26A69A) } // Bright Teal (visible on dark backgrounds)

    // MARK: - Accent Colors

    public var accent: Color { ColorPalette.VitalOrange.shade300 }
    public var accentLight: Color { Color(hex: 0xFFEBD8) } // Soft Sand
    public var accentGold: Color { Color(hex: 0xF5B700) } // Golden Beam
    public var accentPink: Color { Color(hex: 0x26C8B9) } // Aqua Pulse (teal accent)

    // MARK: - Surface Colors

    // Optimized for gradient backgrounds (true black to dark gray gradient)

    public var background: Color { ColorPalette.GreyNeutral.shade600 } // True black
    public var surface: Color { Color(hex: 0x1C1C1E).opacity(0.85) } // Semi-transparent for glass effect
    public var elevated: Color { Color(hex: 0x2C2C2E).opacity(0.95) } // More opaque for elevation

    // Surface levels - optimized for dark gradients with subtle depth
    public var surface0: Color { Color(hex: 0x0A0A0A).opacity(0.7) } // Most transparent
    public var surface1: Color { Color(hex: 0x1C1C1E).opacity(0.85) } // Card backgrounds
    public var surface2: Color { Color(hex: 0x2C2C2E).opacity(0.9) } // Elevated cards
    public var surface3: Color { ColorPalette.GreyNeutral.shade400 } // Higher elevation
    public var surface4: Color { ColorPalette.GreyCool.shade450 } // Dropdowns/menus
    public var surface5: Color { ColorPalette.GreyNeutral.shade350 } // Highest elevation

    /// System surfaces
    public var systemGroupedBackground: Color {
        #if os(watchOS)
            Color(hex: 0x000000) // True black for watchOS
        #else
            Color(UIColor.systemGroupedBackground)
        #endif
    }

    public var systemSecondaryBackground: Color {
        #if os(watchOS)
            Color(hex: 0x1C1C1E)
        #else
            Color(UIColor.secondarySystemBackground)
        #endif
    }

    public var systemTertiaryBackground: Color {
        #if os(watchOS)
            Color(hex: 0x2C2C2E)
        #else
            Color(UIColor.tertiarySystemBackground)
        #endif
    }

    /// Fill colors
    public var fillPrimary: Color {
        #if os(watchOS)
            Color(hex: 0x787880).opacity(0.36)
        #else
            Color(UIColor.systemFill)
        #endif
    }

    public var fillSecondary: Color {
        #if os(watchOS)
            Color(hex: 0x787880).opacity(0.32)
        #else
            Color(UIColor.secondarySystemFill)
        #endif
    }

    public var fillTertiary: Color {
        #if os(watchOS)
            Color(hex: 0x767680).opacity(0.24)
        #else
            Color(UIColor.tertiarySystemFill)
        #endif
    }

    public var fillQuaternary: Color {
        #if os(watchOS)
            Color(hex: 0x747480).opacity(0.18)
        #else
            Color(UIColor.quaternarySystemFill)
        #endif
    }

    // MARK: - Content Colors

    public var onPrimary: Color { .white }
    public var onSecondary: Color { .white }
    public var onTertiary: Color { .white }
    public var onBackground: Color { .white }
    public var onSurface: Color { .white }
    public var onElevated: Color { .white }

    // MARK: - Text Colors

    public var textPrimary: Color { .white }
    public var textSecondary: Color { Color(hex: 0xEBEBF5).opacity(0.75) }
    public var textTertiary: Color { Color(hex: 0xEBEBF5).opacity(0.5) }
    public var textDisabled: Color { Color(hex: 0xEBEBF5).opacity(0.2) }
    public var textInverse: Color { ColorPalette.GreyNeutral.shade600 } // Pure black

    // MARK: - Border Colors

    public var borderPrimary: Color { ColorPalette.GreyCool.shade400 }
    public var borderSecondary: Color { Color(hex: 0x2C2C2E) }
    public var borderTertiary: Color { Color(hex: 0x1C1C1E) }
    public var borderFocus: Color { self.primary }
    public var borderError: Color { self.error }

    // MARK: - Semantic Colors (Industry Standard)

    public var success: Color { Color(hex: 0x30D158) } // iOS system green (dark mode)
    public var warning: Color { Color(hex: 0xFFD60A) } // iOS system yellow (dark mode)
    public var error: Color { Color(hex: 0xFF453A) } // iOS system red (dark mode)
    public var info: Color { Color(hex: 0x0A84FF) } // iOS system blue (dark mode)

    public var successBackground: Color { self.success.opacity(0.2) }
    public var warningBackground: Color { self.warning.opacity(0.2) }
    public var errorBackground: Color { self.error.opacity(0.2) }
    public var infoBackground: Color { self.info.opacity(0.2) }

    // MARK: - Overlay Colors

    // Adjusted for glass effects on dark gradient backgrounds

    public var overlayLight: Color { ColorPalette.TransparentLight.opacity05 } // Subtle light overlay on dark
    public var overlayMedium: Color { ColorPalette.TransparentDark.opacity40 } // Softer medium overlay
    public var overlayHeavy: Color { ColorPalette.TransparentDark.opacity70 } // Softer heavy overlay

    // MARK: - Special Colors

    public var clear: Color { Color.clear }
    public var shadow: Color { ColorPalette.TransparentDark.opacity30
    } // Stronger shadows for depth on dark backgrounds

    // MARK: - Nutrient Colors

    public var nutrientProtein: Color { self.error }
    public var nutrientCarbs: Color { self.primary }
    public var nutrientFat: Color { self.success }
    public var nutrientWater: Color { self.info }
}
