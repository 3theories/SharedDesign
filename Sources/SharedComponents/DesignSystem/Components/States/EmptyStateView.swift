import SwiftUI

// MARK: - EmptyStateStyle

/// Visual style for empty state presentation
public enum EmptyStateStyle: Sendable {
    /// Standard centered presentation
    case standard

    /// Compact inline presentation
    case compact

    /// Card-style with background
    case card
}

// MARK: - EmptyStateView

/// A component for displaying empty states with optional animations
public struct EmptyStateView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        icon: String,
        isSystemIcon: Bool = true,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: EmptyStateStyle = .standard,
        iconColor: Color? = nil,
        animated: Bool = true
    ) {
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
        self.iconColor = iconColor
        self.animated = animated
    }

    // MARK: Public

    // MARK: - Body

    public var body: some View {
        Group {
            switch self.style {
            case .standard:
                self.standardContent
            case .compact:
                self.compactContent
            case .card:
                self.cardContent
            }
        }
        .onAppear {
            guard self.animated else {
                self.hasAppeared = true
                self.iconScale = 1.0
                self.iconOpacity = 1.0
                self.textOpacity = 1.0
                self.buttonOpacity = 1.0
                return
            }

            self.animateAppearance()
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var hasAppeared = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private let icon: String
    private let isSystemIcon: Bool
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    private let style: EmptyStateStyle
    private let iconColor: Color?
    private let animated: Bool

    private var effectiveIconColor: Color {
        self.iconColor ?? self.theme.colors.textTertiary
    }

    // MARK: - Standard Style

    private var standardContent: some View {
        VStack(spacing: self.theme.spacing.lg) {
            self.iconView
            self.textContent
            self.actionButton
        }
        .padding(self.theme.spacing.xl)
        .frame(maxWidth: 400)
    }

    // MARK: - Compact Style

    private var compactContent: some View {
        HStack(spacing: self.theme.spacing.md) {
            AppIconView(name: self.icon, isSystemIcon: self.isSystemIcon)
                .font(.system(size: 32, weight: .light))
                .frame(width: 32, height: 32)
                .foregroundStyle(self.effectiveIconColor)
                .opacity(self.iconOpacity)
                .scaleEffect(self.iconScale)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: self.theme.spacing.xxs) {
                Text(self.title)
                    .font(self.theme.typography.headline)
                    .foregroundStyle(self.theme.colors.textPrimary)

                Text(self.message)
                    .font(self.theme.typography.subheadline)
                    .foregroundStyle(self.theme.colors.textSecondary)
                    .lineLimit(2)
            }
            .opacity(self.textOpacity)

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(self.theme.typography.subheadline.weight(.semibold))
                        .foregroundStyle(self.theme.colors.primary)
                }
                .opacity(self.buttonOpacity)
            }
        }
        .padding(self.theme.spacing.md)
    }

    // MARK: - Card Style

    private var cardContent: some View {
        VStack(spacing: self.theme.spacing.md) {
            self.iconView
            self.textContent
            self.actionButton
        }
        .padding(self.theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: - Shared Components

    private var iconView: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(self.effectiveIconColor.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(self.iconOpacity)

            // Icon
            if self.isSystemIcon {
                Image(systemName: self.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(self.effectiveIconColor)
                    .symbolEffect(.pulse, options: .repeating, value: self.hasAppeared)
                    .accessibilityHidden(true)
            } else {
                Image(self.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .foregroundStyle(self.effectiveIconColor)
                    .accessibilityHidden(true)
            }
        }
        .opacity(self.iconOpacity)
        .scaleEffect(self.iconScale)
    }

    private var textContent: some View {
        VStack(spacing: self.theme.spacing.sm) {
            Text(self.title)
                .font(self.theme.typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(self.theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(self.message)
                .font(self.theme.typography.body)
                .foregroundStyle(self.theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(self.textOpacity)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionTitle, let action {
            SharedButton(
                actionTitle,
                style: .primary,
                size: .medium,
                action: action
            )
            .padding(.top, self.theme.spacing.xs)
            .opacity(self.buttonOpacity)
        }
    }

    // MARK: - Animation

    private func animateAppearance() {
        // Icon appears first with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            self.iconScale = 1.0
            self.iconOpacity = 1.0
        }

        // Text fades in with stagger
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
            self.textOpacity = 1.0
        }

        // Button appears last
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            self.buttonOpacity = 1.0
            self.hasAppeared = true
        }
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Empty search results
    public static func noResults(
        searchTerm: String = "",
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: searchTerm.isEmpty
                ? String(
                    localized: "empty.search.title.generic",
                    defaultValue: "No Results",
                    bundle: .module,
                    comment: "Empty state title when search has no results"
                )
                : String(
                    localized: "empty.search.title.withTerm",
                    defaultValue: "No results for \"\(searchTerm)\"",
                    bundle: .module,
                    comment: "Empty state title when search for specific term has no results"
                ),
            message: String(
                localized: "empty.search.message",
                defaultValue: "Try adjusting your search or filters to find what you're looking for.",
                bundle: .module,
                comment: "Empty state message for no search results"
            ),
            actionTitle: action != nil
                ? String(
                    localized: "empty.search.action.clear",
                    defaultValue: "Clear Search",
                    bundle: .module,
                    comment: "Button to clear search"
                )
                : nil,
            action: action
        )
    }

    /// No data available
    public static func noData(
        title: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: title ?? String(
                localized: "empty.noData.title",
                defaultValue: "No Data Yet",
                bundle: .module,
                comment: "Default empty state title for no data"
            ),
            message: message ?? String(
                localized: "empty.noData.message",
                defaultValue: "Start by adding your first item.",
                bundle: .module,
                comment: "Default empty state message for no data"
            ),
            actionTitle: actionTitle ?? (
                action != nil
                    ? String(
                        localized: "empty.noData.action",
                        defaultValue: "Get Started",
                        bundle: .module,
                        comment: "Default action button for empty state"
                    )
                    : nil
            ),
            action: action
        )
    }

    /// Network error
    public static func networkError(
        action: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: String(
                localized: "empty.network.title",
                defaultValue: "Connection Error",
                bundle: .module,
                comment: "Empty state title for network error"
            ),
            message: String(
                localized: "empty.network.message",
                defaultValue: "Check your internet connection and try again.",
                bundle: .module,
                comment: "Empty state message for network error"
            ),
            actionTitle: String(
                localized: "empty.network.action",
                defaultValue: "Retry",
                bundle: .module,
                comment: "Retry button for network error"
            ),
            action: action
        )
    }

    /// Generic error
    public static func error(
        message: String? = nil,
        action: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: String(
                localized: "empty.error.title",
                defaultValue: "Oops!",
                bundle: .module,
                comment: "Generic error title"
            ),
            message: message ?? String(
                localized: "empty.error.message",
                defaultValue: "Something went wrong. Please try again.",
                bundle: .module,
                comment: "Default generic error message"
            ),
            actionTitle: String(
                localized: "empty.error.action",
                defaultValue: "Try Again",
                bundle: .module,
                comment: "Try again button for error"
            ),
            action: action
        )
    }

    /// Coming soon
    public static func comingSoon(
        feature: String? = nil
    ) -> EmptyStateView {
        let resolvedFeature = feature ?? String(
            localized: "empty.comingSoon.defaultFeature",
            defaultValue: "This feature",
            bundle: .module,
            comment: "Default feature name for coming soon"
        )
        return EmptyStateView(
            icon: "sparkles",
            title: String(
                localized: "empty.comingSoon.title",
                defaultValue: "Coming Soon",
                bundle: .module,
                comment: "Coming soon title"
            ),
            message: String(
                localized: "empty.comingSoon.message",
                defaultValue: "\(resolvedFeature) is under development and will be available soon!",
                bundle: .module,
                comment: "Coming soon message with feature name"
            ),
            iconColor: ColorPalette.Brand.primary
        )
    }

    // MARK: - Nutrition Context

    /// No recipes
    public static func noRecipes(
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "book.closed",
            title: String(
                localized: "empty.recipes.title",
                defaultValue: "No Recipes Found",
                bundle: .module,
                comment: "Empty state title for no recipes"
            ),
            message: String(
                localized: "empty.recipes.message",
                defaultValue: "Discover healthy recipes that match your dietary preferences.",
                bundle: .module,
                comment: "Empty state message for no recipes"
            ),
            actionTitle: action != nil
                ? String(
                    localized: "empty.recipes.action",
                    defaultValue: "Browse Recipes",
                    bundle: .module,
                    comment: "Action to browse recipes"
                )
                : nil,
            action: action,
            iconColor: ColorPalette.NutritionCategories.protein
        )
    }

    // MARK: - Fasting Context

    /// No fasting history
    public static func noFastingHistory(
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "timer",
            title: String(
                localized: "empty.fasting.title",
                defaultValue: "No Fasting History",
                bundle: .module,
                comment: "Empty state title for no fasting history"
            ),
            message: String(
                localized: "empty.fasting.message",
                defaultValue: "Start intermittent fasting to see your fasting patterns over time.",
                bundle: .module,
                comment: "Empty state message for no fasting history"
            ),
            actionTitle: action != nil
                ? String(
                    localized: "empty.fasting.action",
                    defaultValue: "Start Fast",
                    bundle: .module,
                    comment: "Action to start a fast"
                )
                : nil,
            action: action,
            iconColor: ColorPalette.Brand.tertiary
        )
    }
}

// MARK: - EmptyStateView_Previews

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 40) {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Documents",
                    message: "Create your first document to get started.",
                    actionTitle: "Create Document"
                ) { }

                Divider()

                EmptyStateView.noResults(searchTerm: "workout")

                Divider()

                EmptyStateView.networkError {
                    print("Retry tapped")
                }

                Divider()

                EmptyStateView.comingSoon(feature: "Social features")
            }
            .padding()
        }
        .environment(\.theme, DefaultTheme())
    }
}
