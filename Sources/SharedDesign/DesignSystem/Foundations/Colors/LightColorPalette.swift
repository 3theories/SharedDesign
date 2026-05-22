import SwiftUI

/// Light mode color palette
public struct LightColorPalette: ColorTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    // MARK: - Brand Colors (Niora Design System v2)

    public var primary: Color { ColorPalette.VitalOrange.shade300 }
    public var secondary: Color { ColorPalette.PulsePurple.shade400 }
    public var tertiary: Color { ColorPalette.DeepWellnessGreen.shade500 }

    // MARK: - Accent Colors

    public var accent: Color { ColorPalette.VitalOrange.shade300 }
    public var accentLight: Color { Color(hex: 0xFF8E78) } // Light Orange
    public var accentGold: Color { ColorPalette.SunriseAmber.shade500 }
    public var accentPink: Color { Color(hex: 0xFF375F) } // Pink accent

    // MARK: - Surface Colors

    // Optimized for gradient backgrounds (orange-tinted gradient in light mode)

    public var background: Color { Color(hex: 0xF2F2F7) } // systemGray6
    public var surface: Color { Color.white.opacity(0.65) } // More transparent for glass effect
    public var elevated: Color { Color.white.opacity(0.8) } // Semi-transparent elevated surfaces

    // Surface levels - more transparent to show gradient through
    public var surface0: Color { Color.white.opacity(0.45) } // Very transparent, gradient visible
    public var surface1: Color { Color.white.opacity(0.65) } // Cards show gradient through
    public var surface2: Color { Color(hex: 0xFFFBF8).opacity(0.75) } // Warm white, more transparent
    public var surface3: Color { Color(hex: 0xF5F0ED).opacity(0.85) } // Subtle warm gray
    public var surface4: Color { ColorPalette.GreyNeutral.shade150 } // Neutral medium gray
    public var surface5: Color { ColorPalette.GreyNeutral.shade200 } // Neutral light gray

    /// System surfaces
    public var systemGroupedBackground: Color {
        #if os(watchOS)
            Color(hex: 0xF2F2F7)
        #else
            Color(UIColor.systemGroupedBackground)
        #endif
    }

    public var systemSecondaryBackground: Color {
        #if os(watchOS)
            Color(hex: 0xFFFFFF)
        #else
            Color(UIColor.secondarySystemBackground)
        #endif
    }

    public var systemTertiaryBackground: Color {
        #if os(watchOS)
            Color(hex: 0xFFFFFF)
        #else
            Color(UIColor.tertiarySystemBackground)
        #endif
    }

    /// Fill colors
    public var fillPrimary: Color {
        #if os(watchOS)
            Color(hex: 0x787880).opacity(0.2)
        #else
            Color(UIColor.systemFill)
        #endif
    }

    public var fillSecondary: Color {
        #if os(watchOS)
            Color(hex: 0x787880).opacity(0.16)
        #else
            Color(UIColor.secondarySystemFill)
        #endif
    }

    public var fillTertiary: Color {
        #if os(watchOS)
            Color(hex: 0x767680).opacity(0.12)
        #else
            Color(UIColor.tertiarySystemFill)
        #endif
    }

    public var fillQuaternary: Color {
        #if os(watchOS)
            Color(hex: 0x747480).opacity(0.08)
        #else
            Color(UIColor.quaternarySystemFill)
        #endif
    }

    // MARK: - Content Colors

    public var onPrimary: Color { .white }
    public var onSecondary: Color { .white }
    public var onTertiary: Color { .white }
    public var onBackground: Color { Color.primary }
    public var onSurface: Color { Color.primary }
    public var onElevated: Color { Color.primary }

    // MARK: - Text Colors

    public var textPrimary: Color { ColorPalette.GreyNeutral.shade600 } // Pure black
    public var textSecondary: Color { Color(hex: 0x3C3C43) } // Darker secondary
    public var textTertiary: Color { Color(hex: 0x3C3C43).opacity(0.6) }
    public var textDisabled: Color { Color(hex: 0x3C3C43).opacity(0.3) }
    public var textInverse: Color { .white }

    // MARK: - Border Colors

    public var borderPrimary: Color { ColorPalette.GreyCool.shade200 }
    public var borderSecondary: Color { ColorPalette.GreyCool.shade200 }
    public var borderTertiary: Color { ColorPalette.GreyCool.shade150 }
    public var borderFocus: Color { self.primary }
    public var borderError: Color { self.error }

    // MARK: - Semantic Colors (Industry Standard)

    public var success: Color { Color(hex: 0x34C759) } // iOS system green
    public var warning: Color { Color(hex: 0xFFCC00) } // iOS system yellow
    public var error: Color { Color(hex: 0xFF3B30) } // iOS system red
    public var info: Color { Color(hex: 0x007AFF) } // iOS system blue

    public var successBackground: Color { self.success.opacity(0.1) }
    public var warningBackground: Color { self.warning.opacity(0.1) }
    public var errorBackground: Color { self.error.opacity(0.1) }
    public var infoBackground: Color { self.info.opacity(0.1) }

    // MARK: - Overlay Colors

    // Adjusted for glass effects on gradient backgrounds

    public var overlayLight: Color { ColorPalette.TransparentDark.opacity05 } // Very subtle on gradients
    public var overlayMedium: Color { ColorPalette.TransparentDark.opacity15 } // Softer overlays
    public var overlayHeavy: Color { Color.black.opacity(0.45) } // Softer heavy overlays

    // MARK: - Special Colors

    public var clear: Color { Color.clear }
    public var shadow: Color { Color.black.opacity(0.08) } // Softer shadows for glass-effect cards on gradients

    // MARK: - Nutrient Colors (Niora Design System v2)

    public var nutrientProtein: Color { ColorPalette.NutritionCategories.protein }
    public var nutrientCarbs: Color { ColorPalette.NutritionCategories.carbs }
    public var nutrientFat: Color { ColorPalette.NutritionCategories.fats }
    public var nutrientWater: Color { ColorPalette.Hydration.water }
}
