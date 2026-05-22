import SwiftUI

// MARK: - InsightCard

/// A generic card component for displaying insights with icon, title, value, and optional trend
/// Enhanced with progressive disclosure for detailed information
public struct InsightCard: View {
    // MARK: Lifecycle

    public init(
        icon: String,
        isSystemIcon: Bool = true,
        iconColor: Color,
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendIndicator? = nil,
        backgroundColor: Color? = nil,
        enableProgressive: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder detailContent: @escaping () -> any View = { EmptyView() }
    ) {
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.backgroundColor = backgroundColor
        self.enableProgressive = enableProgressive
        self.onTap = onTap
        self.detailContent = AnyView(detailContent())
    }

    // MARK: Public

    public enum TrendIndicator {
        case up(String)
        case down(String)
        case stable(String)

        // MARK: Internal

        var icon: String {
            switch self {
            case .up: "arrowupright"
            case .down: "arrowdownright"
            case .stable: "arrow.right"
            }
        }

        var isSystemIcon: Bool {
            switch self {
            case .up, .down: false
            case .stable: true
            }
        }

        var color: Color {
            switch self {
            case .up: .green
            case .down: .red
            case .stable: .orange
            }
        }

        var text: String {
            switch self {
            case let .up(text), let .down(text), let .stable(text):
                text
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            // Header with icon and title
            HStack(spacing: self.theme.spacing.sm) {
                AppIconView(name: self.icon, isSystemIcon: self.isSystemIcon)
                    .font(.system(size: 17))
                    .frame(width: 20, height: 20)
                    .foregroundColor(self.iconColor)
                    .accessibilityHidden(true)

                Text(self.title)
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.theme.colors.textSecondary)

                Spacer()

                // Optional trend indicator
                if let trend {
                    HStack(spacing: self.theme.spacing.xxs) {
                        AppIconView(name: trend.icon, isSystemIcon: trend.isSystemIcon)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(trend.text)
                            .font(self.theme.typography.caption2.weight(.medium))
                    }
                    .foregroundColor(trend.color)
                }

                // Progressive disclosure indicator
                if self.enableProgressive {
                    Image(systemName: "chevron.down")
                        .font(self.theme.typography.caption2.weight(.medium))
                        .foregroundColor(self.theme.colors.textTertiary)
                        .rotationEffect(.degrees(self.isExpanded ? 180 : 0))
                        .animation(AnimationConstants.Spring.quick, value: self.isExpanded)
                        .accessibilityHidden(true)
                }
            }

            // Value
            Text(self.value)
                .font(self.theme.typography.title2.weight(.bold))
                .foregroundColor(self.theme.colors.textPrimary)

            // Optional subtitle
            if let subtitle {
                Text(subtitle)
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.theme.colors.textSecondary)
            }

            // Progressive disclosure content
            if self.enableProgressive && self.isExpanded {
                self.detailContent?
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(AnimationConstants.Spring.smooth, value: self.isExpanded)
            }
        }
        .padding(self.theme.spacing.md)
        .scaleEffect(self.scale)
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                .fill(self.backgroundColor ?? self.theme.colors.surface2)
                .shadow(
                    color: self.isExpanded ? self.theme.colors.shadow.opacity(0.3) : Color.clear,
                    radius: self.isExpanded ? 8 : 0,
                    x: 0,
                    y: self.isExpanded ? 4 : 0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            self.handleTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.3,
            perform: {
                if self.enableProgressive {
                    self.handleLongPress()
                }
            },
            onPressingChanged: { pressing in
                withAnimation(AnimationConstants.Spring.quick) {
                    self.scale = pressing ? AnimationConstants.Scale.cardPress : 1.0
                }
            }
        )
        .hapticOnTap(self.enableProgressive ? .light : .selection)
        .accessibilityElement(children: .combine)
        .accessibilityValue(self.enableProgressive ? (self.isExpanded ? "Expanded" : "Collapsed") : "")
        .accessibilityHint(self.enableProgressive ? "Double tap to toggle details" : "")
    }

    // MARK: Internal

    let icon: String
    let isSystemIcon: Bool
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    let trend: TrendIndicator?
    let backgroundColor: Color?
    let detailContent: AnyView?
    let enableProgressive: Bool
    let onTap: (() -> Void)?

    // MARK: Private

    @State private var isExpanded = false
    @State private var scale: CGFloat = 1.0

    @Environment(\.theme) private var theme

    // MARK: - Helper Methods

    private func handleTap() {
        if self.enableProgressive {
            withAnimation(AnimationConstants.Spring.smooth) {
                self.isExpanded.toggle()
            }
            HapticManager.shared.trigger(.selection)
        } else {
            // Scale animation for regular tap
            withAnimation(AnimationConstants.Spring.bouncy) {
                self.scale = 1.05
            }
            withAnimation(AnimationConstants.Spring.quick.delay(0.1)) {
                self.scale = 1.0
            }
            HapticManager.shared.trigger(.light)
        }

        self.onTap?()
    }

    private func handleLongPress() {
        HapticManager.shared.trigger(.medium)

        // Contextual menu could be implemented here
        // For now, just provide additional haptic feedback
        withAnimation(AnimationConstants.Spring.bouncy) {
            self.scale = 1.02
        }
        withAnimation(AnimationConstants.Spring.smooth.delay(0.2)) {
            self.scale = 1.0
        }
    }
}

// MARK: - Preview

#if DEBUG
    struct InsightCard_Previews: PreviewProvider {
        static var previews: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Enhanced InsightCard Preview")
                        .font(.title2.bold())
                        .padding()

                    // Example 1: Calories with upward trend
                    InsightCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Total Calories",
                        value: "2,458",
                        subtitle: "this week",
                        trend: .up("+12%")
                    )

                    // Example 2: Workouts completed with progressive disclosure
                    InsightCard(
                        icon: "liftWeight",
                        iconColor: .green,
                        title: "Workouts",
                        value: "5",
                        subtitle: "completed",
                        trend: .stable("on track"),
                        enableProgressive: true
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            Text("Workout Breakdown")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Strength Training")
                                        .font(.caption2)
                                    Text("3 sessions")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.primary)
                                }

                                Spacer()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cardio")
                                        .font(.caption2)
                                    Text("2 sessions")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.primary)
                                }

                                Spacer()
                            }

                            HStack {
                                Text("Next Goal:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("7 workouts/week")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    // Example 3: Average rating with down trend and details
                    InsightCard(
                        icon: "star",
                        isSystemIcon: false,
                        iconColor: .yellow,
                        title: "Avg Rating",
                        value: "4.2",
                        subtitle: "out of 5",
                        trend: .down("-0.3"),
                        enableProgressive: true
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            Text("Rating Distribution")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image("star")
                                        .resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(star <= 4 ? .yellow : .gray.opacity(0.3))
                                }

                                Spacer()

                                Text("Based on 12 workouts")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text("💡 Tip: Add post-workout notes to track what affects your rating")
                                .font(.caption2)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(6)
                        }
                    }

                    // Example 4: Heart rate with chart preview
                    InsightCard(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Avg Heart Rate",
                        value: "142 bpm",
                        subtitle: "during workouts",
                        enableProgressive: true
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            Text("Heart Rate Zones")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("Zone 2 (65%)")
                                        .font(.caption2)
                                    Spacer()
                                    Text("45 min")
                                        .font(.caption2.weight(.medium))
                                }

                                HStack {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Zone 3 (25%)")
                                        .font(.caption2)
                                    Spacer()
                                    Text("15 min")
                                        .font(.caption2.weight(.medium))
                                }

                                HStack {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text("Zone 4 (10%)")
                                        .font(.caption2)
                                    Spacer()
                                    Text("5 min")
                                        .font(.caption2.weight(.medium))
                                }
                            }
                        }
                    }

                    // Example 5: Achievements with list
                    InsightCard(
                        icon: "trophy.fill",
                        iconColor: .purple,
                        title: "Achievements",
                        value: "3",
                        subtitle: "this month",
                        backgroundColor: Color.purple.opacity(0.1),
                        enableProgressive: true
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            Text("Recent Achievements")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 8) {
                                HStack {
                                    Image("fire").resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                    Text("7-Day Streak")
                                        .font(.caption2.weight(.medium))
                                    Spacer()
                                    Text("2 days ago")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Text(verbatim: "💪")
                                    Text("Personal Record")
                                        .font(.caption2.weight(.medium))
                                    Spacer()
                                    Text("5 days ago")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Image("star").resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                    Text("Perfect Week")
                                        .font(.caption2.weight(.medium))
                                    Spacer()
                                    Text("1 week ago")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Text("Tap cards with arrows to expand details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .environment(\.theme, DefaultTheme())
        }
    }
#endif
