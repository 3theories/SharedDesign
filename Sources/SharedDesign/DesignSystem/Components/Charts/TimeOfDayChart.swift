import Charts
import SwiftUI

// MARK: - TimeOfDayChart

/// A clean bar chart showing activity by hour of day using Swift Charts.
/// Single purpose: Show when things happen throughout the day.
public struct TimeOfDayChart: View {
    // MARK: Lifecycle

    public init(
        data: [HourData],
        title: String? = nil,
        color: Color = .blue,
        showAllLabels: Bool = false
    ) {
        self.data = data
        self.title = title
        self.color = color
        self.showAllLabels = showAllLabels
    }

    // MARK: Public

    public struct HourData: Identifiable {
        // MARK: Lifecycle

        public init(hour: Int, value: Double) {
            self.hour = hour
            self.value = value

            // Format hour label
            switch hour {
            case 0: self.label = "12a"
            case 1...11: self.label = "\(hour)a"
            case 12: self.label = "12p"
            default: self.label = "\(hour - 12)p"
            }
        }

        // MARK: Public

        public let id = UUID()
        public let hour: Int
        public let value: Double
        public let label: String
    }

    public let data: [HourData]
    public let title: String?
    public let color: Color
    public let showAllLabels: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(self.theme.colors.textPrimary)
            }

            Chart(self.completeData) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    item.value > 0 ? self.color : self.color.opacity(0.15)
                )
                .cornerRadius(3)
            }
            .frame(height: 80)
            .chartXAxis {
                AxisMarks(values: self.showAllLabels ? .automatic : .stride(by: 6)) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            switch hour {
                            case 0: Text(L10n.string("chart.time_of_day.axis.midnight_short"))
                            case 6: Text(L10n.string("chart.time_of_day.axis.six_am_short"))
                            case 12: Text(L10n.string("chart.time_of_day.axis.noon_short"))
                            case 18: Text(L10n.string("chart.time_of_day.axis.six_pm_short"))
                            default: Text(verbatim: "")
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(self.theme.colors.textTertiary)
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartXScale(domain: 0...23)
            .accessibilityLabel(self.title ?? String(
                localized: "chart.time.of.day",
                defaultValue: "Time of Day Chart",
                bundle: .module
            ))
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    /// Fill in missing hours with zero values
    private var completeData: [HourData] {
        var hourMap = [Int: Double]()
        for item in self.data {
            hourMap[item.hour] = item.value
        }

        return (0..<24).map { hour in
            HourData(hour: hour, value: hourMap[hour] ?? 0)
        }
    }
}

// MARK: - Convenience Initializers

extension TimeOfDayChart {
    /// Create chart from hour:value dictionary
    public static func fromDictionary(
        _ hourValues: [Int: Double],
        title: String? = nil,
        color: Color = .blue
    ) -> TimeOfDayChart {
        let data = hourValues.map { hour, value in
            HourData(hour: hour, value: value)
        }
        return TimeOfDayChart(
            data: data,
            title: title,
            color: color
        )
    }

    /// Preset for workout activity
    public static func workoutActivity(_ hourValues: [Int: Double]) -> TimeOfDayChart {
        self.fromDictionary(hourValues, title: "Workout Activity", color: .red)
    }

    /// Preset for heart rate
    public static func heartRate(_ hourValues: [Int: Double]) -> TimeOfDayChart {
        self.fromDictionary(hourValues, title: "Heart Rate Pattern", color: .pink)
    }

    /// Preset for steps
    public static func steps(_ hourValues: [Int: Double]) -> TimeOfDayChart {
        self.fromDictionary(hourValues, title: "Hourly Steps", color: .blue)
    }
}

// MARK: - Preview

#Preview("Time of Day Charts") {
    ScrollView {
        VStack(spacing: 24) {
            // Workout activity
            TimeOfDayChart.workoutActivity([
                6: 15, 7: 25, 8: 10,
                12: 8,
                17: 12, 18: 20, 19: 15, 20: 5
            ])

            // Heart rate throughout day
            TimeOfDayChart.heartRate([
                0: 55, 1: 52, 2: 50, 3: 49, 4: 51, 5: 53,
                6: 58, 7: 75, 8: 68, 9: 62, 10: 65, 11: 67,
                12: 72, 13: 68, 14: 64, 15: 66, 16: 69, 17: 74,
                18: 82, 19: 78, 20: 72, 21: 68, 22: 62, 23: 58
            ])

            // Steps with cumulative values
            TimeOfDayChart.steps([
                6: 150, 7: 420, 8: 890, 9: 1200, 10: 1450, 11: 1680,
                12: 2100, 13: 2380, 14: 2650, 15: 2890, 16: 3120, 17: 3450,
                18: 3800, 19: 4150, 20: 4320, 21: 4450, 22: 4520, 23: 4580
            ])
        }
        .padding()
    }
}
