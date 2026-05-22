import SwiftUI

// MARK: - ActivityTile

/// A reusable tile for activity quick launch grids.
/// Displays an icon and label with subtle surface styling.
///
/// Design principles:
/// - Square aspect ratio for grid layouts
/// - Large touch targets for quick launch
/// - Icon-centric design with minimal text
/// - Subtle surface elevation
public struct ActivityTile: View {
    // MARK: Lifecycle

    /// Creates an activity tile with SF Symbol
    /// - Parameters:
    ///   - title: The activity name
    ///   - systemImage: SF Symbol name
    ///   - iconColor: Optional tint color (uses theme primary if nil)
    ///   - action: Action when tapped
    public init(
        title: String,
        systemImage: String,
        iconColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = systemImage
        self.iconColor = iconColor
        self.isSystemIcon = true
        self.action = action
    }

    /// Creates an activity tile with custom image
    /// - Parameters:
    ///   - title: The activity name
    ///   - imageName: Asset image name
    ///   - action: Action when tapped
    public init(
        title: String,
        imageName: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = imageName
        self.iconColor = nil
        self.isSystemIcon = false
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: self.action) {
            VStack(spacing: self.theme.spacing.md) {
                // Icon
                self.iconView
                    .frame(width: 44, height: 44)

                // Title
                Text(self.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, self.theme.spacing.lg)
            .padding(.horizontal, self.theme.spacing.md)
            .background(self.theme.colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 6,
                x: 0,
                y: 3
            )
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.2), value: self.isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in self.isPressed = true }
                .onEnded { _ in self.isPressed = false }
        )
    }

    // MARK: Internal

    let title: String
    let icon: String
    let iconColor: Color?
    let isSystemIcon: Bool
    let action: () -> Void

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    @ViewBuilder
    private var iconView: some View {
        if self.isSystemIcon {
            Image(systemName: self.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(self.iconColor ?? self.theme.colors.primary)
                .accessibilityHidden(true)
        } else {
            Image(self.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

// MARK: - ActivityTileGrid

/// A grid layout for activity tiles optimized for quick launch
public struct ActivityTileGrid<Content: View>: View {
    // MARK: Lifecycle

    /// Creates an activity tile grid
    /// - Parameters:
    ///   - columns: Number of columns (default: 3)
    ///   - spacing: Spacing between tiles (default: 12)
    ///   - content: The tiles to display
    public init(
        columns: Int = 3,
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: self.spacing),
                count: self.columns
            ),
            spacing: self.spacing
        ) {
            self.content
        }
    }

    // MARK: Internal

    let columns: Int
    let spacing: CGFloat
    let content: Content

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ActivityCategoryTile

/// A tile variant for activity categories with gradient background
public struct ActivityCategoryTile: View {
    // MARK: Lifecycle

    /// Creates an activity category tile with SF Symbol
    /// - Parameters:
    ///   - title: Category name
    ///   - subtitle: Optional subtitle
    ///   - systemImage: SF Symbol name
    ///   - gradient: Gradient colors for background
    ///   - action: Action when tapped
    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = systemImage
        self.isSystemIcon = true
        self.gradient = gradient
        self.action = action
    }

    /// Creates an activity category tile with custom image
    /// - Parameters:
    ///   - title: Category name
    ///   - subtitle: Optional subtitle
    ///   - imageName: Asset image name
    ///   - gradient: Gradient colors for background
    ///   - action: Action when tapped
    public init(
        title: String,
        subtitle: String? = nil,
        imageName: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = imageName
        self.isSystemIcon = false
        self.gradient = gradient
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: self.action) {
            HStack(spacing: self.theme.spacing.md) {
                // Icon
                AppIconView(name: self.icon, isSystemIcon: self.isSystemIcon)
                    .font(.system(size: 28, weight: .medium))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: self.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(self.theme.colors.textPrimary)

                    if let subtitle = self.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(self.theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.theme.colors.textSecondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(self.theme.spacing.md)
            .background(self.theme.colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 6,
                x: 0,
                y: 3
            )
            .scaleEffect(self.isPressed ? 0.98 : 1.0)
            .animation(.spring(duration: 0.2), value: self.isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in self.isPressed = true }
                .onEnded { _ in self.isPressed = false }
        )
    }

    // MARK: Internal

    let title: String
    let subtitle: String?
    let icon: String
    let isSystemIcon: Bool
    let gradient: [Color]
    let action: () -> Void

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false
}

// MARK: - Preview

#Preview("Activity Tiles") {
    ScrollView {
        VStack(spacing: 24) {
            // Quick launch grid
            Text("QUICK START")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ActivityTileGrid {
                ActivityTile(title: "Tennis", systemImage: "figure.tennis") { }
                ActivityTile(title: "Running", systemImage: "figure.run") { }
                ActivityTile(title: "Yoga", systemImage: "figure.yoga") { }
                ActivityTile(title: "Workout", imageName: "dumbell") { }
                ActivityTile(title: "Cricket", systemImage: "figure.cricket") { }
                ActivityTile(title: "More", systemImage: "ellipsis.circle.fill", iconColor: .gray) { }
            }

            Divider()

            // Category tiles
            Text("CATEGORIES")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ActivityCategoryTile(
                title: "Sports",
                subtitle: "Tennis, Cricket, Soccer",
                systemImage: "sportscourt.fill",
                gradient: [.blue, .cyan]
            ) { }

            ActivityCategoryTile(
                title: "Workouts",
                subtitle: "Strength, HIIT, Custom",
                imageName: "dumbell",
                gradient: [.orange, .red]
            ) { }

            ActivityCategoryTile(
                title: "Cardio",
                subtitle: "Running, Cycling, Swimming",
                systemImage: "figure.run",
                gradient: [.green, .mint]
            ) { }
        }
        .padding()
    }
}
