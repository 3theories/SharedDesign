import SwiftUI

/// A reusable row that shows a label, optional status, trailing value and a wide progress bar
/// Designed to mimic the Apple Health/Fitness metric rows.
public struct LabeledProgressRow: View {
    // MARK: Lifecycle

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        iconColor: Color = .accentColor,
        status: Status? = nil,
        trailingText: String? = nil,
        progress: Double,
        gradient: [Color],
        barHeight: CGFloat = 12,
        showEndCap: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.iconColor = iconColor
        self.status = status
        self.trailingText = trailingText
        self.progress = max(0, min(progress, 1))
        self.gradient = gradient
        self.barHeight = barHeight
        self.showEndCap = showEndCap
    }

    // MARK: Public

    public struct Status {
        // MARK: Lifecycle

        public init(_ text: String, color: Color) {
            self.text = text
            self.color = color
        }

        // MARK: Public

        public let text: String
        public let color: Color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
            HStack(spacing: self.theme.spacing.sm) {
                if let icon {
                    ZStack {
                        Circle()
                            .fill(self.iconColor.opacity(0.15))
                            .frame(width: 26, height: 26)
                        AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                            .foregroundColor(self.iconColor)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 13, height: 13)
                            .accessibilityHidden(true)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(self.theme.typography.title3.weight(.semibold))
                        .foregroundColor(self.theme.colors.textPrimary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(self.theme.typography.footnote)
                            .foregroundColor(self.theme.colors.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if let status {
                        Text(status.text)
                            .font(self.theme.typography.caption1.weight(.semibold))
                            .foregroundColor(status.color)
                    }
                    if let trailingText {
                        Text(trailingText)
                            .font(self.theme.typography.subheadline.weight(.semibold))
                            .foregroundColor(self.theme.colors.textSecondary)
                    }
                }
            }

            ZStack {
                LinearProgressBar(
                    progress: self.progress,
                    height: self.barHeight,
                    showPercentage: false,
                    gradientColors: self.gradient
                )
                // Gloss highlight
                LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                    .mask(Capsule().frame(height: self.barHeight))

                // End-cap indicator (centered on track)
                if self.showEndCap {
                    GeometryReader { proxy in
                        let dot = self.barHeight * 0.72
                        let x = max(min(proxy.size.width * self.progress, proxy.size.width - dot / 2), dot / 2)
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: dot, height: dot)
                            .shadow(color: .black.opacity(0.15), radius: 1.75, x: 0, y: 1)
                            .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 0.6))
                            .position(x: x, y: self.barHeight / 2)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let title: String
    let subtitle: String?
    let icon: String?
    let isSystemIcon: Bool
    let iconColor: Color
    let status: Status?
    let trailingText: String?
    let progress: Double
    let gradient: [Color]
    let barHeight: CGFloat
    let showEndCap: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

#Preview("LabeledProgressRow") {
    VStack(spacing: 16) {
        LabeledProgressRow(
            title: "Average Rating",
            icon: "star",
            isSystemIcon: false,
            iconColor: .yellow,
            status: .init("Excellent", color: .blue),
            trailingText: "4.7/5",
            progress: 0.94,
            gradient: [.yellow, .orange]
        )
        LabeledProgressRow(
            title: "Zone 2",
            subtitle: "134–147 bpm",
            icon: nil,
            iconColor: .blue,
            status: nil,
            trailingText: "18 min",
            progress: 0.45,
            gradient: [.blue, .blue.opacity(0.8)],
            barHeight: 14
        )
    }
    .padding()
}
