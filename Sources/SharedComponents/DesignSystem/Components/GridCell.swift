import SwiftUI

// MARK: - GridCell

/// A simple, reusable grid cell component for displaying items in grid layouts
public struct GridCell: View {
    // MARK: Lifecycle

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        iconColor: Color? = nil,
        image: Image? = nil,
        stats: [(icon: String, value: String)]? = nil,
        action: (() -> Void)? = nil,
        menuAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.image = image
        self.stats = stats?.map { (icon: $0.icon, isSystemIcon: true, value: $0.value) }
        self.action = action
        self.menuAction = menuAction
    }

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        iconColor: Color? = nil,
        image: Image? = nil,
        richStats: [(icon: String, isSystemIcon: Bool, value: String)],
        action: (() -> Void)? = nil,
        menuAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.image = image
        self.stats = richStats
        self.action = action
        self.menuAction = menuAction
    }

    // MARK: Public

    public var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    self.cellContent
                }
                .buttonStyle(GridCellButtonStyle(isPressed: self.$isPressed))
            } else {
                self.cellContent
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false

    // Content
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let isSystemIcon: Bool
    private let iconColor: Color?
    private let image: Image?
    private let stats: [(icon: String, isSystemIcon: Bool, value: String)]?

    // Actions
    private let action: (() -> Void)?
    private let menuAction: (() -> Void)?

    @ViewBuilder
    private var cellContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
            // Top section with icon/image and menu
            HStack(alignment: .top) {
                if let image {
                    // Custom image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
                } else if let icon {
                    // Icon with background
                    ZStack {
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .fill((self.iconColor ?? self.theme.colors.primary).opacity(0.12))
                            .frame(width: 36, height: 36)

                        AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 16, height: 16)
                            .foregroundColor(self.iconColor ?? self.theme.colors.primary)
                    }
                }

                Spacer()

                // Menu button
                if let menuAction {
                    Button(action: menuAction) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(self.theme.colors.primary.opacity(0.8))
                    }
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                }
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: self.theme.spacing.xxs) {
                Text(self.title)
                    .font(self.theme.typography.headline)
                    .foregroundColor(self.theme.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to expand vertically

                if let subtitle {
                    Text(subtitle)
                        .font(self.theme.typography.caption1)
                        .foregroundColor(self.theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // Stats at bottom
            if let stats {
                HStack(spacing: self.theme.spacing.sm) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                        HStack(spacing: self.theme.spacing.xxs) {
                            AppIconView(name: stat.icon, isSystemIcon: stat.isSystemIcon)
                                .font(self.theme.typography.caption1)
                                .frame(width: 14, height: 14)
                            Text(stat.value)
                                .font(self.theme.typography.caption1.weight(.medium))
                        }
                        .foregroundColor(self.theme.colors.textSecondary)
                    }
                }
            }
        }
        .padding(self.theme.spacing.sm)
        .frame(maxWidth: .infinity)
        .frame(height: 155) // Fixed height for consistent grid
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large)
                .fill(self.theme.colors.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large)
                .stroke(self.theme.colors.primary.opacity(self.isPressed ? 0.3 : 0), lineWidth: 2)
        )
        .scaleEffect(self.isPressed ? AnimationConstants.Scale.cardPress : 1)
        .animation(AnimationConstants.Easing.quickOut, value: self.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
    struct GridCell_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 16) {
                // Recipe example
                GridCell(
                    title: "Mediterranean Quinoa Salad",
                    subtitle: "Healthy & Delicious",
                    icon: "fork.knife",
                    isSystemIcon: true,
                    iconColor: .orange,
                    richStats: [
                        (icon: "flame.fill", isSystemIcon: true, value: "350"),
                        (icon: "leaf.fill", isSystemIcon: true, value: "25g")
                    ],
                    action: { print("Cell tapped") },
                    menuAction: { print("Menu tapped") }
                )

                // Workout example
                GridCell(
                    title: "Morning Run",
                    subtitle: "Cardio",
                    icon: "figure.run",
                    iconColor: .blue,
                    richStats: [
                        (icon: "timer", isSystemIcon: true, value: "30 min"),
                        (icon: "location.fill", isSystemIcon: true, value: "5 km")
                    ]
                ) { print("Workout tapped") }

                // Simple example
                GridCell(
                    title: "Protein Shake",
                    icon: "cup.and.saucer.fill",
                    richStats: [
                        (icon: "bolt.fill", isSystemIcon: true, value: "Quick")
                    ]
                )
            }
            .padding()
        }
    }
#endif

// MARK: - GridCellButtonStyle

private struct GridCellButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(AnimationConstants.Easing.quickOut) {
                    self.isPressed = newValue
                }
            }
    }
}
