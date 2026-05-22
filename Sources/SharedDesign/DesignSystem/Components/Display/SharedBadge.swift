import SwiftUI

// MARK: - SharedBadge

/// A versatile badge component for displaying status, labels, or counts
public struct SharedBadge: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        _ text: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .medium,
        isPill: Bool = true
    ) {
        self.text = text
        self.icon = icon
        self.style = style
        self.size = size
        self.isPill = isPill
    }

    // MARK: Public

    // MARK: - Types

    public enum Style {
        case primary
        case secondary
        case success
        case warning
        case error
        case info
        case custom(background: Color, foreground: Color)
    }

    public enum Size {
        case small
        case medium
        case large
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: self.iconSpacing) {
            if let icon {
                Image(systemName: icon)
                    .font(self.iconFont)
                    .accessibilityHidden(true)
            }

            Text(self.text)
                .font(self.textFont)
                .fontWeight(self.fontWeight)
        }
        .foregroundColor(self.foregroundColor)
        .padding(.horizontal, self.horizontalPadding)
        .padding(.vertical, self.verticalPadding)
        .background(self.backgroundView)
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let text: String
    private let icon: String?
    private let style: Style
    private let size: Size
    private let isPill: Bool

    private var backgroundColor: Color {
        switch self.style {
        case .primary:
            self.theme.colors.primary
        case .secondary:
            self.theme.colors.secondary
        case .success:
            self.theme.colors.success
        case .warning:
            self.theme.colors.warning
        case .error:
            self.theme.colors.error
        case .info:
            self.theme.colors.info
        case let .custom(background, _):
            background
        }
    }

    private var foregroundColor: Color {
        switch self.style {
        case .primary:
            self.theme.colors.onPrimary
        case .secondary:
            self.theme.colors.onSecondary
        case .success, .warning, .error, .info:
            .white
        case let .custom(_, foreground):
            foreground
        }
    }

    private var horizontalPadding: CGFloat {
        switch self.size {
        case .small:
            self.theme.spacing.xs
        case .medium:
            self.theme.spacing.sm
        case .large:
            self.theme.spacing.md
        }
    }

    private var verticalPadding: CGFloat {
        switch self.size {
        case .small:
            self.theme.spacing.xs / 2
        case .medium:
            self.theme.spacing.xs
        case .large:
            self.theme.spacing.sm
        }
    }

    private var textFont: Font {
        switch self.size {
        case .small:
            .caption2
        case .medium:
            .caption
        case .large:
            .footnote
        }
    }

    private var iconFont: Font {
        switch self.size {
        case .small:
            .system(size: 10)
        case .medium:
            .system(size: 12)
        case .large:
            .system(size: 14)
        }
    }

    private var fontWeight: Font.Weight {
        switch self.size {
        case .small, .medium:
            .medium
        case .large:
            .semibold
        }
    }

    private var iconSpacing: CGFloat {
        switch self.size {
        case .small:
            2
        case .medium:
            3
        case .large:
            4
        }
    }

    private var cornerRadius: CGFloat {
        self.theme.sizing.cornerRadius.small
    }

    @ViewBuilder
    private var backgroundView: some View {
        if self.isPill {
            Capsule()
                .fill(self.backgroundColor)
        } else {
            RoundedRectangle(cornerRadius: self.cornerRadius)
                .fill(self.backgroundColor)
        }
    }
}

// MARK: - Convenience Initializers

extension SharedBadge {
    /// Create a count badge (e.g., for notifications)
    public static func count(_ value: Int, style: Style = .error) -> SharedBadge {
        SharedBadge(
            value > 99 ? "99+" : "\(value)",
            style: style,
            size: .small
        )
    }

    /// Create a status badge
    public static func status(_ text: String, isActive: Bool) -> SharedBadge {
        SharedBadge(
            text,
            style: isActive ? .success : .secondary,
            size: .small
        )
    }
}

// MARK: - SharedBadge_Previews

struct SharedBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Styles
            HStack(spacing: 10) {
                SharedBadge("Primary", style: .primary)
                SharedBadge("Secondary", style: .secondary)
                SharedBadge("Success", style: .success)
            }

            HStack(spacing: 10) {
                SharedBadge("Warning", style: .warning)
                SharedBadge("Error", style: .error)
                SharedBadge("Info", style: .info)
            }

            Divider()

            // Sizes
            HStack(spacing: 10) {
                SharedBadge("Small", size: .small)
                SharedBadge("Medium", size: .medium)
                SharedBadge("Large", size: .large)
            }

            Divider()

            // With icons
            HStack(spacing: 10) {
                SharedBadge("Premium", icon: "crown.fill", style: .primary)
                SharedBadge("Trial", icon: "clock.fill", style: .warning)
                SharedBadge("Free", icon: "star.fill", style: .secondary)
            }

            Divider()

            // Special badges
            HStack(spacing: 10) {
                SharedBadge.count(5)
                SharedBadge.count(99)
                SharedBadge.count(150)
            }

            HStack(spacing: 10) {
                SharedBadge.status("Active", isActive: true)
                SharedBadge.status("Inactive", isActive: false)
            }

            // Non-pill shape
            HStack(spacing: 10) {
                SharedBadge("Rectangle", isPill: false)
                SharedBadge("With Icon", icon: "bolt.fill", isPill: false)
            }
        }
        .padding()
        .environment(\.theme, DefaultTheme())
    }
}
