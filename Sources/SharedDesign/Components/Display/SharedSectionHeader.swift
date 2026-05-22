import SwiftUI

// MARK: - SectionHeaderStyle

/// Visual style variants for SharedSectionHeader
public enum SectionHeaderStyle: Sendable {
    /// Standard section header
    case `default`

    /// Larger, more prominent header
    case prominent

    /// Smaller, subtle header
    case subtle

    /// Header with background
    case filled
}

// MARK: - SectionAction

/// Action configuration for section headers
public struct SectionAction: Sendable {
    // MARK: Lifecycle

    public init(
        title: String = "See All",
        icon: String? = "chevron.right",
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    // MARK: Public

    public let title: String
    public let icon: String?
    public let action: @Sendable () -> Void

    /// Common "See All" action
    public static func seeAll(action: @escaping @Sendable () -> Void) -> SectionAction {
        SectionAction(title: "See All", icon: "chevron.right", action: action)
    }

    /// Common "Add" action
    public static func add(action: @escaping @Sendable () -> Void) -> SectionAction {
        SectionAction(title: "Add", icon: "plus", action: action)
    }

    /// Common "Edit" action
    public static func edit(action: @escaping @Sendable () -> Void) -> SectionAction {
        SectionAction(title: "Edit", icon: "pencil", action: action)
    }

    /// Custom action with just a title
    public static func custom(title: String, action: @escaping @Sendable () -> Void) -> SectionAction {
        SectionAction(title: title, icon: nil, action: action)
    }
}

// MARK: - SharedSectionHeader

/// A consistent section header component for organizing content sections.
public struct SharedSectionHeader: View {
    // MARK: Lifecycle

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        style: SectionHeaderStyle = .default,
        action: SectionAction? = nil,
        accentColor: Color? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.style = style
        self.action = action
        self.accentColor = accentColor
    }

    // MARK: Public

    public var body: some View {
        Group {
            switch self.style {
            case .default:
                self.defaultContent
            case .prominent:
                self.prominentContent
            case .subtle:
                self.subtleContent
            case .filled:
                self.filledContent
            }
        }
    }

    // MARK: Internal

    // Content
    let title: String
    let subtitle: String?
    let icon: String?
    let badge: String?

    // Configuration
    let style: SectionHeaderStyle
    let action: SectionAction?
    let accentColor: Color?

    // MARK: Private

    private enum BadgeSize {
        case regular
        case small
    }

    @Environment(\.theme) private var theme

    private var effectiveAccentColor: Color {
        self.accentColor ?? self.theme.colors.primary
    }

    // MARK: - Default Style

    private var defaultContent: some View {
        HStack(alignment: .center, spacing: self.theme.spacing.sm) {
            self.leadingContent(
                titleFont: self.theme.typography.headline,
                subtitleFont: self.theme.typography.subheadline
            )

            Spacer()

            self.actionButton
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.sm)
    }

    // MARK: - Prominent Style

    private var prominentContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
            HStack(alignment: .center, spacing: self.theme.spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(self.effectiveAccentColor)
                        .accessibilityHidden(true)
                }

                Text(self.title)
                    .font(self.theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(self.theme.colors.textPrimary)

                if let badge {
                    self.badgeView(badge)
                }

                Spacer()

                self.actionButton
            }

            if let subtitle {
                Text(subtitle)
                    .font(self.theme.typography.subheadline)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.md)
    }

    // MARK: - Subtle Style

    private var subtleContent: some View {
        HStack(alignment: .center, spacing: self.theme.spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .accessibilityHidden(true)
            }

            Text(self.title)
                .font(self.theme.typography.caption1)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(self.theme.colors.textSecondary)
                .tracking(0.5)

            if let badge {
                self.badgeView(badge, size: .small)
            }

            Spacer()

            self.actionButton
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.xs)
    }

    // MARK: - Filled Style

    private var filledContent: some View {
        HStack(alignment: .center, spacing: self.theme.spacing.sm) {
            self.leadingContent(
                titleFont: self.theme.typography.headline,
                subtitleFont: self.theme.typography.footnote
            )

            Spacer()

            self.actionButton
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.sm)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
    }

    @ViewBuilder
    private var actionButton: some View {
        if let action {
            Button {
                HapticManager.shared.trigger(.light)
                action.action()
            } label: {
                HStack(spacing: 4) {
                    Text(action.title)
                        .font(self.theme.typography.subheadline)
                        .fontWeight(.medium)

                    if let icon = action.icon {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(self.effectiveAccentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Shared Components

    private func leadingContent(titleFont: Font, subtitleFont: Font) -> some View {
        HStack(alignment: .center, spacing: self.theme.spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(self.effectiveAccentColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: self.theme.spacing.xs) {
                    Text(self.title)
                        .font(titleFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(self.theme.colors.textPrimary)

                    if let badge {
                        self.badgeView(badge)
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(self.theme.colors.textSecondary)
                }
            }
        }
    }

    private func badgeView(_ text: String, size: BadgeSize = .regular) -> some View {
        Text(text)
            .font(size == .small ? .system(size: 10, weight: .bold) : .system(size: 12, weight: .bold))
            .foregroundStyle(self.effectiveAccentColor)
            .padding(.horizontal, size == .small ? 6 : 8)
            .padding(.vertical, size == .small ? 2 : 4)
            .background(self.effectiveAccentColor.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Convenience Initializers

extension SharedSectionHeader {
    /// Create a simple header with title only
    public static func simple(_ title: String) -> SharedSectionHeader {
        SharedSectionHeader(title: title)
    }

    /// Create a header with "See All" action
    public static func withSeeAll(
        _ title: String,
        subtitle: String? = nil,
        action: @escaping @Sendable () -> Void
    ) -> SharedSectionHeader {
        SharedSectionHeader(
            title: title,
            subtitle: subtitle,
            action: .seeAll(action: action)
        )
    }

    /// Create a header with icon
    public static func withIcon(
        _ title: String,
        icon: String,
        subtitle: String? = nil,
        style: SectionHeaderStyle = .default
    ) -> SharedSectionHeader {
        SharedSectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            style: style
        )
    }

    /// Create a header with count badge
    public static func withCount(
        _ title: String,
        count: Int,
        action: SectionAction? = nil
    ) -> SharedSectionHeader {
        SharedSectionHeader(
            title: title,
            badge: "\(count)",
            action: action
        )
    }

    /// Create a prominent section header (for major sections)
    public static func prominent(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        action: SectionAction? = nil
    ) -> SharedSectionHeader {
        SharedSectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            style: .prominent,
            action: action
        )
    }

    /// Create a subtle section header (for subsections)
    public static func subtle(_ title: String) -> SharedSectionHeader {
        SharedSectionHeader(title: title, style: .subtle)
    }
}

// MARK: - Preview

#Preview("SharedSectionHeader Styles") {
    ScrollView {
        VStack(spacing: 24) {
            Text("SharedSectionHeader Styles")
                .font(.title2.bold())
                .padding(.bottom)

            // Default Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Default").font(.headline)
                SharedSectionHeader.simple("Recent Workouts")
                SharedSectionHeader.withSeeAll("Popular Recipes") { }
                SharedSectionHeader.withCount("Saved Items", count: 12, action: .seeAll { })
            }

            Divider()

            // With Icon
            VStack(alignment: .leading, spacing: 8) {
                Text("With Icon").font(.headline)
                SharedSectionHeader.withIcon("Today's Meals", icon: "fork.knife")
                SharedSectionHeader.withIcon(
                    "Workout Plan",
                    icon: "figure.strengthtraining.traditional",
                    subtitle: "Week 3 of 12"
                )
            }

            Divider()

            // Prominent Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Prominent").font(.headline)
                SharedSectionHeader.prominent(
                    "Nutrition Overview",
                    subtitle: "Track your daily macros and calories",
                    icon: "macroDistribution",
                    action: .seeAll { }
                )
            }

            Divider()

            // Subtle Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Subtle").font(.headline)
                SharedSectionHeader.subtle("Additional Info")
                SharedSectionHeader(
                    title: "Categories",
                    icon: "tag.fill",
                    style: .subtle
                )
            }

            Divider()

            // Filled Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Filled").font(.headline)
                SharedSectionHeader(
                    title: "Quick Actions",
                    subtitle: "Frequently used features",
                    icon: "bolt.fill",
                    style: .filled,
                    action: .edit { }
                )
            }

            Divider()

            // Custom Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Actions").font(.headline)
                SharedSectionHeader(
                    title: "Ingredients",
                    badge: "12",
                    action: .add { }
                )
                SharedSectionHeader(
                    title: "Instructions",
                    action: .custom(title: "Collapse") { }
                )
            }
        }
        .padding()
    }
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
    .environment(\.theme, DefaultTheme())
}
