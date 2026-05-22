import SwiftUI

// MARK: - CircularProgressRing

/// A reusable circular progress ring
public struct CircularProgressRing: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        primaryColor: Color,
        secondaryColor: Color? = nil,
        size: CGFloat = 60,
        lineWidth: CGFloat = 4,
        showValue: Bool = true,
        valueFormatter: @escaping (Double) -> String = { "\(Int($0 * 100))%" }
    ) {
        self.progress = min(1.0, max(0, progress))
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.size = size
        self.lineWidth = lineWidth
        self.showValue = showValue
        self.valueFormatter = valueFormatter
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            // Background ring - adjusted to be inside the frame
            Circle()
                .stroke(self.primaryColor.opacity(0.15), lineWidth: self.lineWidth)
                .frame(width: self.size - self.lineWidth, height: self.size - self.lineWidth)

            // Progress ring
            if let secondaryColor {
                Circle()
                    .trim(from: 0, to: self.animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [self.primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
                    )
                    .frame(width: self.size - self.lineWidth, height: self.size - self.lineWidth)
                    .rotationEffect(.degrees(-90))
                    .animation(self.theme.animations.spring, value: self.animatedProgress)
            } else {
                Circle()
                    .trim(from: 0, to: self.animatedProgress)
                    .stroke(
                        self.primaryColor,
                        style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
                    )
                    .frame(width: self.size - self.lineWidth, height: self.size - self.lineWidth)
                    .rotationEffect(.degrees(-90))
                    .animation(self.theme.animations.spring, value: self.animatedProgress)
            }

            // Value display with better styling
            if self.showValue {
                Text(self.valueFormatter(self.animatedProgress))
                    .font(.system(size: min(self.size * 0.25, 14), weight: .medium, design: .rounded))
                    .foregroundColor(self.primaryColor)
            }
        }
        .frame(width: self.size, height: self.size)
        .onAppear {
            self.animatedProgress = self.progress
        }
        .onChange(of: self.progress) { _, newValue in
            self.animatedProgress = newValue
        }
    }

    // MARK: Internal

    let progress: Double
    let primaryColor: Color
    let secondaryColor: Color?
    let size: CGFloat
    let lineWidth: CGFloat
    let showValue: Bool
    let valueFormatter: (Double) -> String

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedProgress: Double = 0
}

// MARK: - ChartLinearProgressBar

/// A reusable linear progress bar for charts
public struct ChartLinearProgressBar: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        primaryColor: Color,
        secondaryColor: Color? = nil,
        height: CGFloat = 12,
        showPercentage: Bool = false,
        useGradient: Bool = true
    ) {
        self.progress = min(1.0, max(0, progress))
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.height = height
        self.showPercentage = showPercentage
        self.useGradient = useGradient
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                    .fill(self.primaryColor.opacity(0.15))

                // Progress with gradient or solid fill
                if self.useGradient {
                    if let secondaryColor {
                        // Use provided gradient colors
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .fill(
                                LinearGradient(
                                    colors: [self.primaryColor, secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * self.animatedProgress)
                            .animation(self.theme.animations.spring, value: self.animatedProgress)
                    } else {
                        // Create subtle gradient from primary color
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .fill(
                                LinearGradient(
                                    colors: [self.primaryColor, self.primaryColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width * self.animatedProgress)
                            .animation(self.theme.animations.spring, value: self.animatedProgress)
                    }
                } else {
                    // Solid fill without gradient
                    RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                        .fill(self.primaryColor)
                        .frame(width: geometry.size.width * self.animatedProgress)
                        .animation(self.theme.animations.spring, value: self.animatedProgress)
                }

                // Percentage overlay
                if self.showPercentage && self.animatedProgress > 0.1 {
                    Text(verbatim: "\(Int(self.animatedProgress * 100))%")
                        .font(self.theme.typography.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, SpacingScale.xxs)
                        .position(
                            x: (geometry.size.width * self.animatedProgress) / 2,
                            y: geometry.size.height / 2
                        )
                }
            }
        }
        .frame(height: self.height)
        .shadow(color: self.primaryColor.opacity(0.15), radius: 2, x: 0, y: 1)
        .onAppear {
            self.animatedProgress = self.progress
        }
        .onChange(of: self.progress) { _, newValue in
            self.animatedProgress = newValue
        }
    }

    // MARK: Internal

    let progress: Double
    let primaryColor: Color
    let secondaryColor: Color?
    let height: CGFloat
    let showPercentage: Bool
    let useGradient: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedProgress: Double = 0
}

// MARK: - ChartInsightCard

/// A reusable insight card component for charts
public struct ChartInsightCard: View {
    // MARK: Lifecycle

    public init(icon: String = "lightbulb.fill", message: String, type: InsightType = .info) {
        self.icon = icon
        self.message = message
        self.type = type
    }

    // MARK: Public

    public enum InsightType {
        case info
        case success
        case warning
        case error

        // MARK: Internal

        func backgroundColor(from theme: Theme) -> Color {
            switch self {
            case .info: theme.colors.infoBackground
            case .success: theme.colors.successBackground
            case .warning: theme.colors.warningBackground
            case .error: theme.colors.errorBackground
            }
        }

        func iconColor(from theme: Theme) -> Color {
            switch self {
            case .info: theme.colors.info
            case .success: theme.colors.success
            case .warning: theme.colors.warning
            case .error: theme.colors.error
            }
        }
    }

    public var body: some View {
        HStack(spacing: SpacingScale.xs) {
            Image(systemName: self.icon)
                .font(self.theme.typography.caption1)
                .foregroundColor(self.type.iconColor(from: self.theme))

            Text(self.message)
                .font(self.theme.typography.caption1)
                .foregroundColor(self.theme.colors.textSecondary)

            Spacer()
        }
        .padding(SpacingScale.xs)
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                .fill(self.type.backgroundColor(from: self.theme))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.type) insight: \(self.message)")
    }

    // MARK: Internal

    let icon: String
    let message: String
    let type: InsightType

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SegmentedRingChart

/// A circular segmented ring chart for showing proportions
public struct SegmentedRingChart: View {
    // MARK: Lifecycle

    public init(
        segments: [Segment],
        ringWidth: CGFloat = 20,
        size: CGFloat = 120,
        showCenterValue: Bool = true
    ) {
        self.segments = segments
        self.ringWidth = ringWidth
        self.size = size
        self.showCenterValue = showCenterValue
    }

    // MARK: Public

    public struct Segment {
        // MARK: Lifecycle

        public init(value: Double, color: Color, label: String) {
            self.value = value
            self.color = color
            self.label = label
        }

        // MARK: Public

        public let value: Double
        public let color: Color
        public let label: String
    }

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(self.theme.colors.surface3, lineWidth: self.ringWidth)
                .frame(width: self.size, height: self.size)

            // Segments
            ForEach(Array(self.segments.enumerated()), id: \.offset) { index, segment in
                let startAngle = self.calculateStartAngle(for: index)
                let endAngle = self.calculateEndAngle(for: index)

                Circle()
                    .trim(from: startAngle, to: endAngle)
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: self.ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: self.size, height: self.size)
                    .animation(self.theme.animations.spring.delay(Double(index) * 0.1), value: self.animatedSegments)
            }

            // Center value
            if self.showCenterValue {
                let total = self.segments.reduce(0) { $0 + $1.value }
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", total))
                        .font(self.theme.typography.title3)
                        .foregroundColor(self.theme.colors.textPrimary)

                    Text(L10n.string("chart.ring.total", defaultValue: "Total"))
                        .font(self.theme.typography.caption2)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
            }
        }
        .onAppear {
            self.animatedSegments = self.segments.map(\.value)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    let segments: [Segment]
    let ringWidth: CGFloat
    let size: CGFloat
    let showCenterValue: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedSegments: [Double] = []

    private func calculateStartAngle(for index: Int) -> CGFloat {
        let total = self.segments.reduce(0) { $0 + $1.value }
        let previousSum = self.segments.prefix(index).reduce(0) { $0 + $1.value }
        return total > 0 ? CGFloat(previousSum / total) : 0
    }

    private func calculateEndAngle(for index: Int) -> CGFloat {
        let total = self.segments.reduce(0) { $0 + $1.value }
        let currentSum = self.segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return total > 0 ? CGFloat(currentSum / total) : 0
    }
}
