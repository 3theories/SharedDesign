import Charts
import SwiftUI

// MARK: - SimpleTrendChart

/// A simple trend chart using Swift Charts for showing progress over time.
/// Single purpose: Show trend data with optional comparison to targets.
public struct SimpleTrendChart: View {
    // MARK: Lifecycle

    public init(
        data: [DataPoint],
        target: Double? = nil,
        color: Color = .blue,
        height: CGFloat = 40,
        showAxis: Bool = false,
        fillGradient: Bool = true
    ) {
        self.data = data
        self.target = target
        self.color = color
        self.height = height
        self.showAxis = showAxis
        self.fillGradient = fillGradient
    }

    // MARK: Public

    public struct DataPoint: Identifiable {
        // MARK: Lifecycle

        public init(day: Int, value: Double) {
            self.day = day
            self.value = value
            self.label = "Day \(day)"
        }

        // MARK: Public

        public let id = UUID()
        public let day: Int
        public let value: Double
        public let label: String
    }

    public let data: [DataPoint]
    public let target: Double?
    public let color: Color
    public let height: CGFloat
    public let showAxis: Bool
    public let fillGradient: Bool

    public var body: some View {
        Chart {
            // Area/gradient fill
            if self.fillGradient {
                ForEach(self.data) { point in
                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [self.color.opacity(0.3), self.color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            // Line
            ForEach(self.data) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(self.color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }

            // Points
            ForEach(self.data) { point in
                PointMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(self.color)
                .symbolSize(20)
            }

            // Target line if provided
            if let target {
                RuleMark(
                    y: .value("Target", target)
                )
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        .frame(height: self.height)
        .chartXAxis(self.showAxis ? .automatic : .hidden)
        .chartYAxis(self.showAxis ? .automatic : .hidden)
        .accessibilityLabel(String(
            localized: "chart.trend",
            defaultValue: "Trend Chart",
            bundle: .module,
            comment: "Accessibility label for trend chart"
        ))
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Convenience Initializers

extension SimpleTrendChart {
    /// Create from array of values (assumes daily data)
    public static func fromValues(
        _ values: [Double],
        target: Double? = nil,
        color: Color = .blue,
        height: CGFloat = 40
    ) -> SimpleTrendChart {
        let data = values.enumerated().map { index, value in
            DataPoint(day: index + 1, value: value)
        }
        return SimpleTrendChart(
            data: data,
            target: target,
            color: color,
            height: height
        )
    }

    /// Mini sparkline version
    public static func sparkline(
        _ values: [Double],
        color: Color = .blue
    ) -> SimpleTrendChart {
        self.fromValues(values, color: color, height: 20)
    }
}

// MARK: - Preview

#Preview("Simple Trend Charts") {
    VStack(spacing: 24) {
        // Standard trend
        SimpleTrendChart.fromValues(
            [65, 72, 68, 75, 82, 78, 85],
            target: 80,
            color: .blue,
            height: 60
        )

        // Sparkline
        SimpleTrendChart.sparkline(
            [10, 15, 12, 18, 22, 20, 25],
            color: .green
        )

        // With axis
        SimpleTrendChart(
            data: [
                SimpleTrendChart.DataPoint(day: 1, value: 150),
                SimpleTrendChart.DataPoint(day: 2, value: 180),
                SimpleTrendChart.DataPoint(day: 3, value: 165),
                SimpleTrendChart.DataPoint(day: 4, value: 190),
                SimpleTrendChart.DataPoint(day: 5, value: 210),
                SimpleTrendChart.DataPoint(day: 6, value: 195),
                SimpleTrendChart.DataPoint(day: 7, value: 220)
            ],
            target: 200,
            color: .orange,
            height: 100,
            showAxis: true
        )
    }
    .padding()
}
