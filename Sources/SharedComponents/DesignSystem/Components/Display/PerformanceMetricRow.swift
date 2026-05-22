import SwiftUI

// MARK: - PerformanceMetricRow

/// A refined, polished metric row with subtle visual hierarchy.
/// Shows title with muted icon, status text, score, and a subtle progress bar.
public struct PerformanceMetricRow: View {
    // MARK: Lifecycle

    public init(
        title: String,
        icon: String,
        isSystemIcon: Bool = true,
        iconColor: Color,
        status: Status,
        score: String,
        progress: Double,
        progressColor: Color
    ) {
        self.title = title
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.status = status
        self.score = score
        self.progress = max(0, min(progress, 1))
        self.progressColor = progressColor
    }

    // MARK: Public

    public struct Status {
        // MARK: Lifecycle

        public init(_ text: String, badge: Badge, color: Color) {
            self.text = text
            self.badge = badge
            self.color = color
        }

        // MARK: Public

        public enum Badge {
            case star // Excellent
            case checkmarkCircle // Good
            case arrowRight // Slightly above/below
            case checkmark // Fair
            case chevronDown // Poor

            // MARK: Internal

            var icon: String {
                switch self {
                case .star: "star"
                case .checkmarkCircle: "checkmark.circle.fill"
                case .arrowRight: "arrow.right.circle.fill"
                case .checkmark: "checkmark.circle"
                case .chevronDown: "chevron.down.circle.fill"
                }
            }

            var isSystemIcon: Bool {
                switch self {
                case .star: false
                default: true
                }
            }
        }

        public let text: String
        public let badge: Badge
        public let color: Color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Icon + Title on left, Score on right
            HStack(alignment: .center, spacing: 0) {
                // Left: Subtle icon + Title
                HStack(spacing: 10) {
                    // Muted icon with subtle background
                    ZStack {
                        Circle()
                            .fill(self.iconColor.opacity(0.12))
                            .frame(width: 28, height: 28)

                        AppIconView(name: self.icon, isSystemIcon: self.isSystemIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 16, height: 16)
                            .foregroundColor(self.iconColor.opacity(0.85))
                            .accessibilityHidden(true)
                    }

                    Text(self.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(self.theme.colors.textPrimary.opacity(0.9))
                }

                Spacer()

                // Right: Score prominently displayed
                Text(self.score)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(self.theme.colors.textPrimary)
            }

            // Progress bar with status indicator
            VStack(alignment: .leading, spacing: 6) {
                // Subtle progress bar
                GeometryReader { proxy in
                    let totalWidth = proxy.size.width
                    let fillWidth = totalWidth * self.progress

                    ZStack(alignment: .leading) {
                        // Track - very subtle
                        RoundedRectangle(cornerRadius: Self.barHeight / 2, style: .continuous)
                            .fill(self.theme.colors.textSecondary.opacity(0.1))
                            .frame(height: Self.barHeight)

                        // Fill - muted gradient
                        RoundedRectangle(cornerRadius: Self.barHeight / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        self.progressColor.opacity(0.7),
                                        self.progressColor.opacity(0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(fillWidth, Self.barHeight), height: Self.barHeight)
                    }
                }
                .frame(height: Self.barHeight)

                // Status text below progress bar - subtle and informative
                HStack(spacing: 5) {
                    AppIconView(name: self.status.badge.icon, isSystemIcon: self.status.badge.isSystemIcon)
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 12, height: 12)
                        .foregroundColor(self.status.color.opacity(0.85))
                        .accessibilityHidden(true)

                    Text(self.status.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(self.status.color.opacity(0.85))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.title), \(self.score), \(self.status.text)")
    }

    // MARK: Internal

    let title: String
    let icon: String
    let isSystemIcon: Bool
    let iconColor: Color
    let status: Status
    let score: String
    let progress: Double
    let progressColor: Color

    // MARK: Private

    private static let barHeight: CGFloat = 8

    @Environment(\.theme) private var theme
}

// MARK: - Convenience Status Constructors

extension PerformanceMetricRow.Status {
    /// Excellent status (green)
    public static func excellent(_ text: String = "Excellent") -> Self {
        .init(text, badge: .star, color: Color(red: 0.3, green: 0.75, blue: 0.45))
    }

    /// Good status (green)
    public static func good(_ text: String = "Good") -> Self {
        .init(text, badge: .checkmarkCircle, color: Color(red: 0.3, green: 0.7, blue: 0.4))
    }

    /// Fair status (muted yellow)
    public static func fair(_ text: String = "Fair") -> Self {
        .init(text, badge: .checkmark, color: Color(red: 0.75, green: 0.65, blue: 0.3))
    }

    /// Slightly above/longer status (muted orange)
    public static func slightlyAbove(_ text: String = "Slightly above") -> Self {
        .init(text, badge: .arrowRight, color: Color(red: 0.8, green: 0.6, blue: 0.35))
    }

    /// Poor status (muted red-orange)
    public static func poor(_ text: String = "Needs work") -> Self {
        .init(text, badge: .chevronDown, color: Color(red: 0.8, green: 0.5, blue: 0.35))
    }

    /// Needs work status (alias for poor)
    public static func needsWork(_ text: String = "Needs work") -> Self {
        .poor(text)
    }
}

// MARK: - Preview

#Preview("PerformanceMetricRow - Refined") {
    VStack(spacing: 24) {
        Text("Quality Metrics")
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 20) {
            PerformanceMetricRow(
                title: "Overall Quality",
                icon: "star",
                isSystemIcon: false,
                iconColor: .purple,
                status: .good(),
                score: "65/100",
                progress: 0.65,
                progressColor: .purple
            )

            PerformanceMetricRow(
                title: "Efficiency",
                icon: "gauge.with.dots.needle.67percent",
                iconColor: .blue,
                status: .excellent(),
                score: "91/100",
                progress: 0.91,
                progressColor: .blue
            )

            PerformanceMetricRow(
                title: "Zone Optimization",
                icon: "flame.fill",
                iconColor: .orange,
                status: .good(),
                score: "75/100",
                progress: 0.75,
                progressColor: .orange
            )

            PerformanceMetricRow(
                title: "Circadian Alignment",
                icon: AppIcon.night.rawValue,
                isSystemIcon: false,
                iconColor: .indigo,
                status: .poor(),
                score: "10/100",
                progress: 0.10,
                progressColor: .indigo
            )
        }
    }
    .padding(16)
    .background(Color(white: 0.12))
    .environment(\.theme, DefaultTheme())
}
