import SwiftUI

// MARK: - SubtleSurfaceCard

/// A card with surface elevation using subtle shadows instead of glass effects.
/// Use this for activity-related UI where clarity and readability are paramount.
///
/// Design principles:
/// - Uses surface1/surface2 colors with subtle shadows
/// - NO glass effects - maintains high contrast on dark backgrounds
/// - Supports different elevation levels for visual hierarchy
public struct SubtleSurfaceCard<Content: View>: View {
    // MARK: Lifecycle

    /// Creates a subtle surface card with specified elevation
    /// - Parameters:
    ///   - elevation: The visual elevation level (affects shadow intensity)
    ///   - cornerRadius: Corner radius of the card (default: 16)
    ///   - content: The content to display inside the card
    public init(
        elevation: Elevation = .medium,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        self.content
            .background(self.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
            .shadow(
                color: self.shadowColor,
                radius: self.shadowRadius,
                x: 0,
                y: self.shadowY
            )
    }

    // MARK: Internal

    let elevation: Elevation
    let cornerRadius: CGFloat
    let content: Content

    // MARK: Private

    @Environment(\.theme) private var theme

    // MARK: - Private Properties

    private var backgroundColor: Color {
        switch self.elevation {
        case .none:
            self.theme.colors.surface0
        case .low:
            self.theme.colors.surface1
        case .medium:
            self.theme.colors.surface2
        case .high:
            self.theme.colors.surface3
        case .floating:
            self.theme.colors.surface4
        }
    }

    private var shadowColor: Color {
        switch self.elevation {
        case .none:
            .clear
        case .low:
            Color.black.opacity(0.08)
        case .medium:
            Color.black.opacity(0.12)
        case .high:
            Color.black.opacity(0.15)
        case .floating:
            Color.black.opacity(0.2)
        }
    }

    private var shadowRadius: CGFloat {
        switch self.elevation {
        case .none:
            0
        case .low:
            4
        case .medium:
            8
        case .high:
            12
        case .floating:
            20
        }
    }

    private var shadowY: CGFloat {
        switch self.elevation {
        case .none:
            0
        case .low:
            2
        case .medium:
            4
        case .high:
            6
        case .floating:
            10
        }
    }
}

// MARK: SubtleSurfaceCard.Elevation

extension SubtleSurfaceCard {
    /// Visual elevation levels for surface cards
    public enum Elevation {
        /// No elevation - flat surface
        case none
        /// Low elevation - subtle lift
        case low
        /// Medium elevation - standard cards
        case medium
        /// High elevation - prominent sections
        case high
        /// Floating elevation - overlays and modals
        case floating
    }
}

// MARK: - Preview

#Preview("Subtle Surface Cards") {
    VStack(spacing: 24) {
        SubtleSurfaceCard(elevation: .low) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LOW ELEVATION")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Subtle card")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        SubtleSurfaceCard(elevation: .medium) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MEDIUM ELEVATION")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Standard card")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        SubtleSurfaceCard(elevation: .high) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HIGH ELEVATION")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Prominent card")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        SubtleSurfaceCard(elevation: .floating) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FLOATING ELEVATION")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Overlay card")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
}
