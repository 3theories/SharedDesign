import Charts
import SwiftUI

// MARK: - TrendComparisonChart

/// Advanced trend comparison chart with period-over-period analysis
/// Inspired by Apple Health's trend visualizations with Niora's unique styling
public struct TrendComparisonChart: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        data: [DataPoint],
        metrics: ComparisonMetrics? = nil,
        title: String,
        subtitle: String? = nil,
        primaryColor: Color = .blue,
        showComparison: Bool = true,
        showGoalLine: Bool = false,
        goalValue: Double? = nil,
        height: CGFloat = 200
    ) {
        self.data = data.sorted { $0.date < $1.date }
        self.metrics = metrics
        self.title = title
        self.subtitle = subtitle
        self.primaryColor = primaryColor
        self.showComparison = showComparison
        self.showGoalLine = showGoalLine
        self.goalValue = goalValue
        self.height = height
    }

    // MARK: Public

    // MARK: - Data Types

    public struct DataPoint: Identifiable, Hashable {
        // MARK: Lifecycle

        public init(date: Date, value: Double, previousPeriodValue: Double? = nil, category: String? = nil) {
            self.date = date
            self.value = value
            self.previousPeriodValue = previousPeriodValue
            self.category = category
        }

        // MARK: Public

        public let id = UUID()
        public let date: Date
        public let value: Double
        public let previousPeriodValue: Double?
        public let category: String?
    }

    public struct ComparisonMetrics {
        // MARK: Lifecycle

        public init(currentPeriodAverage: Double, previousPeriodAverage: Double) {
            self.currentPeriodAverage = currentPeriodAverage
            self.previousPeriodAverage = previousPeriodAverage
            self.changePercent = previousPeriodAverage > 0
                ? ((currentPeriodAverage - previousPeriodAverage) / previousPeriodAverage) * 100
                : 0
            self.trend = self.changePercent > 2
                ? .increasing
                : self.changePercent < -2 ? .decreasing : .stable
        }

        // MARK: Public

        public let currentPeriodAverage: Double
        public let previousPeriodAverage: Double
        public let changePercent: Double
        public let trend: TrendDirection
    }

    public enum TrendDirection {
        case increasing, decreasing, stable

        // MARK: Internal

        var icon: String {
            switch self {
            case .increasing: "arrowupright"
            case .decreasing: "arrowdownright"
            case .stable: "arrow.right"
            }
        }

        var isSystemIcon: Bool {
            switch self {
            case .increasing, .decreasing: false
            case .stable: true
            }
        }

        var color: Color {
            switch self {
            case .increasing: .green
            case .decreasing: .red
            case .stable: .orange
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with trend information
            self.headerView

            // Main chart
            self.chartView

            // Comparison summary if available
            if let metrics, showComparison {
                self.comparisonView(metrics)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                self.animationProgress = 1.0
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoint: DataPoint?

    private let data: [DataPoint]
    private let metrics: ComparisonMetrics?
    private let title: String
    private let subtitle: String?
    private let primaryColor: Color
    private let showComparison: Bool
    private let showGoalLine: Bool
    private let goalValue: Double?
    private let height: CGFloat

    // MARK: - View Components

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(self.theme.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
            }

            Spacer()

            // Trend indicator
            if let metrics {
                self.trendIndicator(metrics.trend, changePercent: metrics.changePercent)
            }
        }
    }

    private var chartView: some View {
        Chart {
            // Previous period data (if available)
            if self.showComparison {
                ForEach(self.data.filter { $0.previousPeriodValue != nil }) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Previous", point.previousPeriodValue!)
                    )
                    .foregroundStyle(self.theme.colors.textSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                }
            }

            // Current period area fill
            ForEach(self.data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value * Double(self.animationProgress))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [self.primaryColor.opacity(0.3), self.primaryColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Current period line
            ForEach(self.data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value * Double(self.animationProgress))
                )
                .foregroundStyle(self.primaryColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            // Data points
            ForEach(self.data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value * Double(self.animationProgress))
                )
                .foregroundStyle(self.primaryColor)
                .symbolSize(self.selectedPoint?.id == point.id ? 60 : 25)
            }

            // Goal line
            if self.showGoalLine, let goalValue {
                RuleMark(y: .value("Goal", goalValue))
                    .foregroundStyle(self.theme.colors.accent.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 3]))
                    .annotation(position: .topTrailing) {
                        Text(L10n.string("chart.trend_comparison.goal_label"))
                            .font(.caption2)
                            .foregroundColor(self.theme.colors.textSecondary)
                            .padding(.horizontal, 4)
                            .background(self.theme.colors.surface)
                    }
            }

            // Today indicator
            if let today = data.first(where: { Calendar.current.isDateInToday($0.date) }) {
                RuleMark(x: .value("Today", today.date))
                    .foregroundStyle(self.theme.colors.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(self.formatAxisDate(date))
                            .font(.caption2)
                    }
                    AxisGridLine()
                        .foregroundStyle(self.theme.colors.textTertiary.opacity(0.3))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Double.self) {
                        Text(self.formatAxisValue(intValue))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(self.theme.colors.textTertiary.opacity(0.3))
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(self.theme.colors.surface3.opacity(0.3))
                .cornerRadius(12)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                self.updateSelection(at: value.location, in: geometry, proxy: proxy)
                            }
                            .onEnded { _ in
                                self.selectedPoint = nil
                            }
                    )
            }
        }
        .frame(height: self.height)
    }

    private func trendIndicator(_ trend: TrendDirection, changePercent: Double) -> some View {
        HStack(spacing: 4) {
            AppIconView(name: trend.icon, isSystemIcon: trend.isSystemIcon)
                .frame(width: 12, height: 12)
                .foregroundColor(trend.color)
                .accessibilityHidden(true)

            Text(verbatim: self.formatChangePercent(changePercent))
                .font(.caption.weight(.semibold))
                .foregroundColor(trend.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(trend.color.opacity(0.1))
        )
    }

    private func comparisonView(_ metrics: ComparisonMetrics) -> some View {
        HStack(spacing: 20) {
            // Current period
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("chart.trend_comparison.current_label"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(self.theme.colors.textSecondary)

                Text(self.formatValue(metrics.currentPeriodAverage))
                    .font(.title3.weight(.bold))
                    .foregroundColor(self.theme.colors.textPrimary)
            }

            // Comparison arrow
            AppIconView(name: metrics.trend.icon, isSystemIcon: metrics.trend.isSystemIcon)
                .frame(width: 20, height: 20)
                .foregroundColor(metrics.trend.color)
                .accessibilityHidden(true)

            // Previous period
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("chart.trend_comparison.previous_label"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(self.theme.colors.textSecondary)

                Text(self.formatValue(metrics.previousPeriodAverage))
                    .font(.title3.weight(.bold))
                    .foregroundColor(self.theme.colors.textSecondary)
            }

            Spacer()

            // Change amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(L10n.string("chart.trend_comparison.change_label", defaultValue: "Change"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(self.theme.colors.textSecondary)

                Text(verbatim: self.formatChangePercent(metrics.changePercent))
                    .font(.title3.weight(.bold))
                    .foregroundColor(metrics.trend.color)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.theme.colors.surface1.opacity(0.3))
        )
    }

    // MARK: - Helper Methods

    private func updateSelection(at location: CGPoint, in geometry: GeometryProxy, proxy: ChartProxy) {
        if let date = proxy.value(atX: location.x, as: Date.self) {
            // Find the closest data point
            let closest = self.data.min { point1, point2 in
                abs(point1.date.timeIntervalSince(date)) < abs(point2.date.timeIntervalSince(date))
            }

            self.selectedPoint = closest
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "'Today'" : "EEE"
        return formatter.string(from: date)
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1000 {
            String(format: "%.1fK", value / 1000)
        } else {
            String(format: "%.0f", value)
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            String(format: "%.1fK", value / 1000)
        } else {
            String(format: "%.0f", value)
        }
    }

    private func formatChangePercent(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f%%", value))"
    }
}

// MARK: - Convenience Initializers

extension TrendComparisonChart {
    /// Create a weekly steps trend chart
    public static func weeklySteps(
        currentWeekData: [(Date, Double)],
        previousWeekData: [(Date, Double)]? = nil,
        goalValue: Double? = 10000
    ) -> TrendComparisonChart {
        let combinedData = currentWeekData.map { date, value in
            let previousValue = previousWeekData?.first { prev in
                Calendar.current.component(.weekday, from: prev.0) == Calendar.current.component(.weekday, from: date)
            }?.1

            return DataPoint(date: date, value: value, previousPeriodValue: previousValue)
        }

        let currentAvg = currentWeekData.map(\.1).reduce(0, +) / Double(currentWeekData.count)
        let previousAvg: Double? = previousWeekData.map { data in
            data.map(\.1).reduce(0, +) / Double(data.count)
        }

        let metrics = previousAvg.map { ComparisonMetrics(currentPeriodAverage: currentAvg, previousPeriodAverage: $0) }

        return TrendComparisonChart(
            data: combinedData,
            metrics: metrics,
            title: "Daily Steps",
            subtitle: "Compared to last week",
            primaryColor: .blue,
            showGoalLine: goalValue != nil,
            goalValue: goalValue
        )
    }

    /// Create a workout calories trend chart
    public static func workoutCalories(
        data: [(Date, Double)],
        previousPeriodData: [(Date, Double)]? = nil,
        targetCalories: Double? = nil
    ) -> TrendComparisonChart {
        let chartData = data.map { date, value in
            DataPoint(date: date, value: value)
        }

        let currentAvg = data.map(\.1).reduce(0, +) / Double(data.count)
        let previousAvg: Double? = previousPeriodData.map { data in
            data.map(\.1).reduce(0, +) / Double(data.count)
        }

        let metrics = previousAvg.map { ComparisonMetrics(currentPeriodAverage: currentAvg, previousPeriodAverage: $0) }

        return TrendComparisonChart(
            data: chartData,
            metrics: metrics,
            title: "Workout Calories",
            subtitle: "Daily burn rate",
            primaryColor: .red,
            showGoalLine: targetCalories != nil,
            goalValue: targetCalories
        )
    }
}

// MARK: - Preview

#Preview("Trend Comparison Charts") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Trend Comparison Charts")
                .font(.title2.bold())
                .padding()

            // Steps trend with comparison
            let calendar = Calendar.current
            let today = Date()
            let weekData = (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: -offset, to: today)!
                return (date, Double.random(in: 6000...12000))
            }.reversed()

            let previousWeekData = (7..<14).map { offset in
                let date = calendar.date(byAdding: .day, value: -offset, to: today)!
                return (date, Double.random(in: 5000...11000))
            }.reversed()

            TrendComparisonChart.weeklySteps(
                currentWeekData: Array(weekData),
                previousWeekData: Array(previousWeekData)
            )

            // Workout calories trend
            let workoutData = (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: -offset, to: today)!
                return (date, Double.random(in: 200...500))
            }.reversed()

            TrendComparisonChart.workoutCalories(
                data: Array(workoutData),
                targetCalories: 350
            )
        }
        .padding()
    }
}
