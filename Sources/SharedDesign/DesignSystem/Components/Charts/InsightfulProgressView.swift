import SwiftUI

/// A simple progress view with basic insights.
/// Shows progress toward goal with one key insight.
/// Clean, focused, and not overwhelming.
public struct InsightfulProgressView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        title: String,
        data: ProgressData,
        style: Style = .standard
    ) {
        self.title = title
        self.data = data
        self.style = style
    }

    // MARK: Public

    // MARK: - Data Structure

    public struct ProgressData {
        // MARK: Lifecycle

        public init(
            current: Double,
            target: Double,
            previousValue: Double? = nil,
            unit: String,
            category: Category = .general
        ) {
            self.current = current
            self.target = target
            self.previousValue = previousValue
            self.unit = unit
            self.category = category
        }

        // MARK: Public

        public let current: Double // Current progress value
        public let target: Double // Target value
        public let previousValue: Double? // Previous day/week value for comparison
        public let unit: String // e.g., "steps", "calories", "minutes"
        public let category: Category // Type of progress for styling

        /// Progress percentage (0.0 to 1.0+)
        public var progressPercentage: Double {
            self.target > 0 ? self.current / self.target : 0
        }

        /// Change from previous value
        public var change: Double? {
            guard let previousValue else {
                return nil
            }
            return self.current - previousValue
        }

        /// One key insight about the progress
        public var insight: String {
            let progress = self.progressPercentage

            if progress >= 1.0 {
                return "Goal achieved!"
            } else if progress >= 0.8 {
                return "Almost there!"
            } else if let change, change > 0 {
                return "Making progress!"
            } else if progress >= 0.5 {
                return "Halfway there"
            } else if progress >= 0.25 {
                return "Good start"
            } else {
                return "Keep going"
            }
        }

        /// Color based on performance vs target
        public var performanceColor: Color {
            switch self.progressPercentage {
            case 0.8...:
                .green
            case 0.5..<0.8:
                .blue
            case 0.25..<0.5:
                .orange
            default:
                .red
            }
        }
    }

    public enum Category {
        case general
        case fitness
        case nutrition
        case health
        case productivity

        // MARK: Internal

        var primaryColor: Color {
            switch self {
            case .general: .blue
            case .fitness: .red
            case .nutrition: .green
            case .health: .purple
            case .productivity: .orange
            }
        }

        var secondaryColor: Color {
            switch self {
            case .general: .cyan
            case .fitness: .pink
            case .nutrition: .mint
            case .health: .indigo
            case .productivity: .yellow
            }
        }
    }

    public enum Style {
        case compact // Single line version
        case standard // Full card version
        case minimal // Just progress ring
    }

    // MARK: - Body

    public var body: some View {
        switch self.style {
        case .compact:
            self.compactView
        case .standard:
            self.standardView
        case .minimal:
            self.minimalView
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let data: ProgressData
    private let title: String
    private let style: Style

    private var progressPercentage: Int {
        Int(self.data.progressPercentage * 100)
    }

    // MARK: - View Components

    private var compactView: some View {
        HStack(spacing: SpacingScale.sm) {
            // Use reusable circular progress component
            CircularProgressRing(
                progress: self.data.progressPercentage,
                primaryColor: self.data.category.primaryColor,
                secondaryColor: nil,
                size: ComponentSizing.Progress.medium.rawValue,
                lineWidth: ComponentSizing.Progress.strokeWidth.rawValue,
                showValue: true
            ) { "\(Int($0 * 100))" }

            // Content
            VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                Text(self.title)
                    .font(self.theme.typography.subheadline)
                    .foregroundColor(self.theme.colors.textPrimary)

                Text(verbatim: "\(Int(self.data.current)) / \(Int(self.data.target)) \(self.data.unit)")
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.theme.colors.textSecondary)
            }

            Spacer()

            // Insight
            if !self.data.insight.isEmpty {
                Text(self.data.insight)
                    .font(self.theme.typography.caption1)
                    .foregroundColor(self.data.performanceColor)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, SpacingScale.md)
        .padding(.vertical, SpacingScale.sm)
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                .fill(self.theme.colors.surface1)
        )
    }

    private var standardView: some View {
        VStack(alignment: .leading, spacing: SpacingScale.md) {
            // Header with title and completion status
            HStack {
                Text(self.title)
                    .font(self.theme.typography.headline)
                    .foregroundColor(self.theme.colors.textPrimary)

                Spacer()

                if self.data.progressPercentage >= 1.0 {
                    HStack(spacing: SpacingScale.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(self.theme.typography.caption1)
                            .foregroundColor(self.theme.colors.success)
                            .accessibilityHidden(true)
                        Text(L10n.string("chart.insightful_progress.complete", defaultValue: "Complete"))
                            .font(self.theme.typography.caption1)
                            .foregroundColor(self.theme.colors.success)
                    }
                }
            }

            // Current value and target
            HStack(alignment: .bottom, spacing: SpacingScale.xxs) {
                Text(verbatim: "\(Int(self.data.current))")
                    .font(self.theme.typography.title2)
                    .foregroundColor(self.theme.colors.textPrimary)

                Text(verbatim: "/ \(Int(self.data.target)) \(self.data.unit)")
                    .font(self.theme.typography.subheadline)
                    .foregroundColor(self.theme.colors.textSecondary)

                Spacer()

                Text(verbatim: "\(self.progressPercentage)%")
                    .font(self.theme.typography.title3)
                    .foregroundColor(self.data.category.primaryColor)
            }

            // Use reusable linear progress component
            ChartLinearProgressBar(
                progress: self.data.progressPercentage,
                primaryColor: self.data.category.primaryColor,
                secondaryColor: self.data.category.secondaryColor,
                height: SpacingScale.sm.value,
                showPercentage: false,
                useGradient: true
            )

            // Use reusable insight card component
            if !self.data.insight.isEmpty {
                ChartInsightCard(
                    icon: "lightbulb.fill",
                    message: self.data.insight,
                    type: .warning
                )
            }

            // Change indicator if available
            if let change = data.change {
                HStack(spacing: SpacingScale.xxs) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(self.theme.typography.caption2)
                        .foregroundColor(change >= 0 ? self.theme.colors.success : self.theme.colors.error)
                        .accessibilityHidden(true)

                    Text("\(change >= 0 ? "+" : "")\(Int(change)) from yesterday")
                        .font(self.theme.typography.caption1)
                        .foregroundColor(change >= 0 ? self.theme.colors.success : self.theme.colors.error)
                }
            }
        }
        .padding(SpacingScale.md)
        .background(
            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                .fill(self.theme.colors.surface1)
        )
    }

    private var minimalView: some View {
        VStack(spacing: SpacingScale.xs) {
            // Use reusable circular progress component
            CircularProgressRing(
                progress: self.data.progressPercentage,
                primaryColor: self.data.category.primaryColor,
                secondaryColor: self.data.category.secondaryColor,
                size: ComponentSizing.Progress.large.rawValue,
                lineWidth: ComponentSizing.Progress.strokeWidth.rawValue,
                showValue: true
            ) { _ in "\(Int(self.data.current))" }

            Text(self.title)
                .font(self.theme.typography.caption1)
                .foregroundColor(self.theme.colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Simple Progress Views") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Simple Progress Views")
                .font(.title2.bold())
                .padding()

            // Standard style
            InsightfulProgressView(
                title: "Daily Steps",
                data: InsightfulProgressView.ProgressData(
                    current: 8420,
                    target: 10000,
                    previousValue: 7800,
                    unit: "steps",
                    category: .fitness
                )
            )

            // Compact style
            InsightfulProgressView(
                title: "Calories Burned",
                data: InsightfulProgressView.ProgressData(
                    current: 1850,
                    target: 2000,
                    previousValue: 1920,
                    unit: "cal",
                    category: .nutrition
                ),
                style: .compact
            )

            // Goal achieved
            InsightfulProgressView(
                title: "Weekly Workouts",
                data: InsightfulProgressView.ProgressData(
                    current: 5,
                    target: 4,
                    previousValue: 4,
                    unit: "workouts",
                    category: .fitness
                ),
                style: .standard
            )

            // Minimal style
            HStack(spacing: 16) {
                InsightfulProgressView(
                    title: "Water",
                    data: InsightfulProgressView.ProgressData(
                        current: 6,
                        target: 8,
                        previousValue: 7,
                        unit: "glasses",
                        category: .health
                    ),
                    style: .minimal
                )

                InsightfulProgressView(
                    title: "Sleep",
                    data: InsightfulProgressView.ProgressData(
                        current: 7.5,
                        target: 8.0,
                        previousValue: 7.2,
                        unit: "hours",
                        category: .health
                    ),
                    style: .minimal
                )

                InsightfulProgressView(
                    title: "Tasks",
                    data: InsightfulProgressView.ProgressData(
                        current: 12,
                        target: 15,
                        previousValue: 10,
                        unit: "done",
                        category: .productivity
                    ),
                    style: .minimal
                )
            }
        }
        .padding()
    }
}
