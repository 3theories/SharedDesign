import SwiftUI

/// Semantic color definitions for specific UI contexts.
/// These are separate from the core ColorTokens palette and provide
/// context-aware colors for actions, states, and specialized components.
public enum SemanticColors {
    // MARK: - Action Colors

    /// Colors for action buttons with semantic meaning
    public enum Action {
        /// Positive action (start, confirm, go, accept)
        public static let positive = Color(hex: 0x34C759)

        /// Negative action (stop, cancel, reject, destructive)
        public static let negative = Color(hex: 0xFF3B30)

        /// Neutral action (pause, skip, later)
        public static var neutral: Color { ColorPalette.GreyNeutral.shade300 }

        /// Caution action (warning, needs attention)
        public static var caution: Color { ColorPalette.SunriseAmber.shade300 }
    }

    // MARK: - Widget Colors

    /// Colors specific to widget contexts
    public enum Widget {
        /// Progress arc active color
        public static func progressActive(theme: Theme) -> Color {
            theme.colors.primary
        }

        /// Progress arc inactive/background color (uses surface4 for better contrast)
        public static func progressInactive(theme: Theme) -> Color {
            theme.colors.surface4
        }
    }
}
