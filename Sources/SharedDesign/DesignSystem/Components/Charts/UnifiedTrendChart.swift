import Charts
import SwiftUI

// MARK: - UnifiedTrendChart

/// Rich, visually appealing trend chart with smooth gradients and thick lines
/// Inspired by modern financial and analytics dashboards
public struct UnifiedTrendChart: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        data: [DataPoint],
        title: String? = nil,
        subtitle: String? = nil,
        primaryColor: Color = .blue,
        secondaryColor: Color? = nil,
        configuration: ChartConfiguration = .standard
    ) {
        self.data = data.sorted { $0.date < $1.date }
        self.title = title
        self.subtitle = subtitle
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor ?? primaryColor.opacity(0.5)
        self.configuration = configuration
    }

    // MARK: Public

    // MARK: - Data Types

    public struct DataPoint: Identifiable, Hashable {
        // MARK: Lifecycle

        public init(date: Date, value: Double, previousPeriodValue: Double? = nil, label: String? = nil) {
            self.date = date
            self.value = value
            self.previousPeriodValue = previousPeriodValue
            self.label = label
        }

        // MARK: Public

        public let id = UUID()
        public let date: Date
        public let value: Double
        public let previousPeriodValue: Double?
        public let label: String?
    }

    public struct ChartConfiguration {
        // MARK: Lifecycle

        public init(
            showComparison: Bool = false, // Disabled by default for performance
            showGoalLine: Bool = false,
            goalValue: Double? = nil,
            showDataPoints: Bool = false, // Disabled by default for performance
            showGrid: Bool = true,
            enableInteraction: Bool = false, // Disabled by default for performance
            animateOnAppear: Bool = false, // Disabled by default for performance
            lineWidth: CGFloat = 3, // Moderate thickness for performance
            pointSize: CGFloat = 8, // Smaller points
            height: CGFloat = 200,
            showTrendIndicator: Bool = true
        ) {
            self.showComparison = showComparison
            self.showGoalLine = showGoalLine
            self.goalValue = goalValue
            self.showDataPoints = showDataPoints
            self.showGrid = showGrid
            self.enableInteraction = enableInteraction
            self.animateOnAppear = animateOnAppear
            self.lineWidth = lineWidth
            self.pointSize = pointSize
            self.height = height
            self.showTrendIndicator = showTrendIndicator
        }

        // MARK: Public

        public static let minimal = ChartConfiguration(
            showComparison: false,
            showGoalLine: false,
            showDataPoints: false,
            showGrid: false,
            enableInteraction: false,
            lineWidth: 3,
            pointSize: 0,
            height: 40
        )

        public static let standard = ChartConfiguration()

        public static let detailed = ChartConfiguration(
            showComparison: true,
            showGoalLine: true,
            showDataPoints: true,
            showGrid: true,
            enableInteraction: true,
            lineWidth: 4, // Reduced from 5
            pointSize: 10, // Reduced from 14
            height: 250
        )

        public let showComparison: Bool
        public let showGoalLine: Bool
        public let goalValue: Double?
        public let showDataPoints: Bool
        public let showGrid: Bool
        public let enableInteraction: Bool
        public let animateOnAppear: Bool
        public let lineWidth: CGFloat
        public let pointSize: CGFloat
        public let height: CGFloat
        public let showTrendIndicator: Bool
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
        VStack(alignment: .leading, spacing: 12) {
            // Header if title is provided
            if self.title != nil || self.subtitle != nil {
                self.headerView
            }

            // Main chart with overlay for interaction
            self.chartView
                .frame(height: self.effectiveConfiguration.height)
                .padding(.trailing, 8) // Add padding to prevent clipping
                .overlay(alignment: .topLeading) {
                    if self.showingCallout, let point = selectedPoint {
                        self.calloutView(for: point)
                            .offset(x: self.dragLocation.x - 40, y: self.dragLocation.y - 60)
                    }
                }

            // Trend indicator
            if self.effectiveConfiguration.showTrendIndicator, self.effectiveConfiguration.height >= 100 {
                self.trendIndicatorBar
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var selectedPoint: DataPoint?
    @State private var showingCallout = false
    @State private var dragLocation: CGPoint = .zero

    private let data: [DataPoint]
    private let title: String?
    private let subtitle: String?
    private let primaryColor: Color
    private let secondaryColor: Color?
    private let configuration: ChartConfiguration

    private var trend: TrendDirection {
        guard self.data.count >= 2 else {
            return .stable
        }
        let recentAvg = self.data.suffix(3).map(\.value).reduce(0, +) / Double(min(3, self.data.count))
        let previousAvg = self.data.prefix(3).map(\.value).reduce(0, +) / Double(min(3, self.data.count))
        let changePercent = previousAvg > 0 ? ((recentAvg - previousAvg) / previousAvg) * 100 : 0

        if changePercent > 2 {
            return .increasing
        } else if changePercent < -2 {
            return .decreasing
        } else {
            return .stable
        }
    }

    private var currentValue: Double {
        self.data.last?.value ?? 0
    }

    private var changeAmount: Double {
        guard self.data.count >= 2 else {
            return 0
        }
        return self.data.last!.value - self.data[self.data.count - 2].value
    }

    private var changePercent: Double {
        guard self.data.count >= 2 else {
            return 0
        }
        let previous = self.data[self.data.count - 2].value
        return previous > 0 ? (self.changeAmount / previous) * 100 : 0
    }

    // MARK: - Performance Optimization

    /// Automatically adjusted configuration based on data size
    private var effectiveConfiguration: ChartConfiguration {
        // For large datasets, override some settings for performance
        if self.data.count > 100 {
            return ChartConfiguration(
                showComparison: false,
                showGoalLine: self.configuration.showGoalLine,
                goalValue: self.configuration.goalValue,
                showDataPoints: false, // Never show points for large datasets
                showGrid: self.configuration.showGrid,
                enableInteraction: false, // Disable interaction for large datasets
                animateOnAppear: false,
                lineWidth: min(self.configuration.lineWidth, 2), // Thinner lines
                pointSize: 0,
                height: self.configuration.height,
                showTrendIndicator: self.configuration.showTrendIndicator
            )
        } else if self.data.count > 50 {
            return ChartConfiguration(
                showComparison: self.configuration.showComparison,
                showGoalLine: self.configuration.showGoalLine,
                goalValue: self.configuration.goalValue,
                showDataPoints: false, // No points for medium datasets
                showGrid: self.configuration.showGrid,
                enableInteraction: self.configuration.enableInteraction,
                animateOnAppear: false,
                lineWidth: min(self.configuration.lineWidth, 3),
                pointSize: self.configuration.pointSize,
                height: self.configuration.height,
                showTrendIndicator: self.configuration.showTrendIndicator
            )
        }
        return self.configuration
    }

    @ChartContentBuilder
    private var comparisonLine: some ChartContent {
        if self.effectiveConfiguration.showComparison {
            ForEach(self.data.filter { $0.previousPeriodValue != nil }) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Previous", point.previousPeriodValue!)
                )
                .foregroundStyle(self.theme.colors.textTertiary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .interpolationMethod(self.interpolationMethod)
            }
        }
    }

    @ChartContentBuilder
    private var gradientArea: some ChartContent {
        ForEach(self.data) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(self.areaGradient)
            .interpolationMethod(self.interpolationMethod)
        }
    }

    private var areaGradient: LinearGradient {
        // Premium gradient with smoother fade
        LinearGradient(
            colors: [
                self.primaryColor.opacity(0.35),
                self.primaryColor.opacity(0.15),
                self.primaryColor.opacity(0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Use adaptive interpolation based on data size
    private var interpolationMethod: Charts.InterpolationMethod {
        // Always use catmullRom for smoother curves
        // Performance impact is minimal for typical data sizes (< 100 points)
        .catmullRom
    }

    private var lineGradient: LinearGradient {
        // Premium gradient with color variation
        LinearGradient(
            colors: [
                self.primaryColor.opacity(0.85),
                self.primaryColor,
                self.primaryColor.opacity(0.9)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ChartContentBuilder
    private var mainLine: some ChartContent {
        ForEach(self.data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(self.lineGradient)
            .lineStyle(StrokeStyle(
                lineWidth: self.effectiveConfiguration.lineWidth,
                lineCap: .round,
                lineJoin: .round
            ))
            .interpolationMethod(self.interpolationMethod)
            // Shadow removed for performance
        }
    }

    @ChartContentBuilder
    private var dataPoints: some ChartContent {
        if self.effectiveConfiguration.showDataPoints {
            ForEach(self.data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(self.primaryColor)
                .symbolSize(
                    self.selectedPoint?.id == point.id
                        ? self.effectiveConfiguration.pointSize * 1.5
                        : self.effectiveConfiguration.pointSize
                )
                .annotation(position: .overlay) {
                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                }
            }
        }
    }

    @ChartContentBuilder
    private var goalLine: some ChartContent {
        if self.effectiveConfiguration.showGoalLine, let goalValue = effectiveConfiguration.goalValue {
            // Goal line - clean dashed line without label to avoid overlap
            RuleMark(y: .value("Goal", goalValue))
                .foregroundStyle(Color.green.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
    }

    /// Calculate appropriate x-axis stride based on data count
    private var xAxisStride: Calendar.Component {
        if self.data.count <= 7 {
            .day
        } else if self.data.count <= 14 {
            .day // Will show every other day via desiredCount
        } else {
            .day // Will show ~5 labels via desiredCount
        }
    }

    /// Calculate desired count of x-axis labels
    private var xAxisLabelCount: Int {
        if self.data.count <= 7 {
            self.data.count
        } else if self.data.count <= 14 {
            7
        } else if self.data.count <= 30 {
            5
        } else {
            6
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(self.theme.colors.textPrimary)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(self.theme.colors.textTertiary)
                }
            }

            Spacer()

            // Trend badge
            HStack(spacing: 4) {
                AppIconView(name: self.trend.icon, isSystemIcon: self.trend.isSystemIcon)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(self.trend == .increasing ? "Up" : self.trend == .decreasing ? "Down" : "Stable")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(self.trend.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(self.trend.color.opacity(0.12))
            )
        }
    }

    private var chartView: some View {
        Chart {
            self.comparisonLine
            self.gradientArea
            self.mainLine
            self.dataPoints
            self.goalLine
        }
        .chartXAxis {
            if self.effectiveConfiguration.showGrid {
                AxisMarks(values: .automatic(desiredCount: self.xAxisLabelCount)) { value in
                    // `centered: true` keeps the rightmost label inside
                    // the plot area instead of letting it extend past the
                    // chart's right edge (which clipped to "Ap..." for
                    // ~30-day "Apr 26" labels).
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(self.formatAxisDate(date))
                                .font(.caption2)
                                .foregroundColor(self.theme.colors.textTertiary)
                        }
                    }
                    AxisGridLine()
                        .foregroundStyle(self.theme.colors.borderSecondary.opacity(0.2))
                }
            } else {
                AxisMarks { _ in }
            }
        }
        .chartYAxis {
            if self.effectiveConfiguration.showGrid {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text(self.formatAxisValue(intValue))
                                .font(.caption2)
                                .foregroundColor(self.theme.colors.textTertiary)
                        }
                    }
                    AxisGridLine()
                        .foregroundStyle(self.theme.colors.borderSecondary.opacity(0.2))
                }
            } else {
                AxisMarks { _ in }
            }
        }
        .chartBackground { _ in
            if self.configuration.showGrid {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                self.theme.colors.surface1.opacity(0.5),
                                self.theme.colors.surface2.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .chartOverlay { proxy in
            if self.effectiveConfiguration.enableInteraction {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .modifier(ChartInteractionModifier(
                            showingCallout: self.$showingCallout,
                            selectedPoint: self.$selectedPoint,
                            data: self.data,
                            geometry: geometry,
                            proxy: proxy,
                            handleHover: self.handleHover
                        ))
                }
            }
        }
    }

    private var trendIndicatorBar: some View {
        HStack(spacing: 16) {
            // Current value with premium styling
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("chart.unified_trend.latest", defaultValue: "Latest"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(self.theme.colors.textTertiary)

                Text(self.formatValue(self.currentValue))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(self.theme.colors.textPrimary)
                    .contentTransition(.numericText())
            }

            // Vertical divider
            Rectangle()
                .fill(self.theme.colors.borderSecondary.opacity(0.3))
                .frame(width: 1, height: 36)

            // Change indicator with premium badge
            HStack(spacing: 6) {
                // Trend icon in circle
                ZStack {
                    Circle()
                        .fill(self.trend.color.opacity(0.15))
                        .frame(width: 28, height: 28)

                    AppIconView(name: self.trend.icon, isSystemIcon: self.trend.isSystemIcon)
                        .frame(width: 12, height: 12)
                        .foregroundColor(self.trend.color)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "\(self.changeAmount > 0 ? "+" : "")\(self.formatValue(self.changeAmount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(self.trend.color)

                    Text("\(self.changePercent > 0 ? "+" : "")\(self.changePercent, specifier: "%.1f")% vs prev")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(self.theme.colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    private func calloutView(for point: DataPoint) -> some View {
        VStack(spacing: 2) {
            Text(self.formatValue(point.value))
                .font(.caption.weight(.bold))
                .foregroundColor(.white)

            Text(self.formatCalloutDate(point.date))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
        .overlay(
            // Arrow pointing down
            Triangle()
                .fill(Color.black.opacity(0.8))
                .frame(width: 10, height: 6)
                .rotationEffect(.degrees(180))
                .offset(y: 15),
            alignment: .bottom
        )
    }

    // MARK: - Helper Methods

    private func handleHover(at location: CGPoint, in geometry: GeometryProxy, proxy: ChartProxy) {
        if let date = proxy.value(atX: location.x, as: Date.self) {
            // Find closest data point
            let closest = self.data.min { point1, point2 in
                abs(point1.date.timeIntervalSince(date)) < abs(point2.date.timeIntervalSince(date))
            }

            if let point = closest {
                withAnimation(.easeOut(duration: 0.15)) {
                    self.selectedPoint = point
                    self.showingCallout = true
                    self.dragLocation = location
                }
            }
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            "Today"
        } else if self.data.count <= 7 {
            // Show weekday for weekly view
            date.formatted(.dateTime.weekday(.abbreviated))
        } else if self.data.count <= 14 {
            // Show short weekday for 2-week view
            date.formatted(.dateTime.weekday(.narrow))
        } else if self.data.count <= 31 {
            // Show month/day for monthly view
            date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            // Show month/day for longer periods
            date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    private func formatCalloutDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 10000 {
            String(format: "%.0fK", value / 1000)
        } else if value >= 1000 {
            String(format: "%.1fK", value / 1000)
        } else {
            String(format: "%.0f", value)
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 10000 {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 0
            return numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        } else if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value < 10 && value != value.rounded() {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Triangle

/// Triangle shape for callout arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - ChartInteractionModifier

private struct ChartInteractionModifier: ViewModifier {
    // MARK: Lifecycle

    func body(content: Content) -> some View {
        #if os(iOS) || os(macOS)
            content
                .onContinuousHover { phase in
                    switch phase {
                    case let .active(location):
                        self.handleHover(location, self.geometry, self.proxy)
                    case .ended:
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showingCallout = false
                            self.selectedPoint = nil
                        }
                    }
                }
        #else
            // For watchOS, use tap gesture instead
            content
                .onTapGesture { location in
                    self.handleHover(location, self.geometry, self.proxy)
                }
        #endif
    }

    // MARK: Internal

    @Binding var showingCallout: Bool
    @Binding var selectedPoint: UnifiedTrendChart.DataPoint?

    let data: [UnifiedTrendChart.DataPoint]
    let geometry: GeometryProxy
    let proxy: ChartProxy
    let handleHover: (CGPoint, GeometryProxy, ChartProxy) -> Void
}

// MARK: - Convenience Initializers

extension UnifiedTrendChart {
    /// Create from simple array of values
    public static func fromValues(
        _ values: [Double],
        title: String? = nil,
        color: Color = .blue,
        configuration: ChartConfiguration = .standard
    ) -> UnifiedTrendChart {
        let calendar = Calendar.current
        let today = Date()
        let data = values.enumerated().map { index, value in
            let date = calendar.date(byAdding: .day, value: -values.count + index + 1, to: today)!
            return DataPoint(date: date, value: value)
        }

        return UnifiedTrendChart(
            data: data,
            title: title,
            primaryColor: color,
            configuration: configuration
        )
    }

    /// Create a sparkline (minimal chart)
    public static func sparkline(
        _ values: [Double],
        color: Color = .blue
    ) -> UnifiedTrendChart {
        self.fromValues(values, color: color, configuration: .minimal)
    }

    /// Create weekly comparison chart
    public static func weeklyComparison(
        currentWeek: [(Date, Double)],
        previousWeek: [(Date, Double)]? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        color: Color = .blue,
        goalValue: Double? = nil
    ) -> UnifiedTrendChart {
        let data = currentWeek.map { date, value in
            let previousValue = previousWeek?.first { prev in
                Calendar.current.component(.weekday, from: prev.0) ==
                    Calendar.current.component(.weekday, from: date)
            }?.1

            return DataPoint(date: date, value: value, previousPeriodValue: previousValue)
        }

        let config = ChartConfiguration(
            showComparison: previousWeek != nil,
            showGoalLine: goalValue != nil,
            goalValue: goalValue,
            showDataPoints: false, // Disabled for performance
            showGrid: true,
            enableInteraction: false, // Disabled for performance
            animateOnAppear: false,
            lineWidth: 3, // Moderate thickness
            pointSize: 8,
            height: 200
        )

        return UnifiedTrendChart(
            data: data,
            title: title,
            subtitle: subtitle,
            primaryColor: color,
            configuration: config
        )
    }
}

// MARK: - Preview

#Preview("Unified Trend Charts") {
    ScrollView {
        VStack(spacing: 24) {
            // Rich gradient chart
            UnifiedTrendChart.fromValues(
                [8234, 7521, 9102, 6834, 8921, 10234, 9521],
                title: "Daily Steps",
                color: .blue,
                configuration: .init(
                    showGoalLine: true,
                    goalValue: 10000,
                    animateOnAppear: false,
                    lineWidth: 4,
                    pointSize: 12
                )
            )
            .padding(.horizontal)

            // Minimal sparklines with gradients
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    UnifiedTrendChart.sparkline(
                        [65, 72, 68, 75, 82, 78, 85],
                        color: .red
                    )
                }

                VStack(alignment: .leading) {
                    Text("Sleep Hours")
                        .font(.caption)
                        .foregroundColor(.gray)
                    UnifiedTrendChart.sparkline(
                        [6.5, 7.2, 6.8, 7.5, 8.2, 7.8, 8.5],
                        color: .purple
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
