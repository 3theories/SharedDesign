import SwiftUI

// MARK: - DistributionBar

/// A simple stacked horizontal bar showing distribution of values.
/// Single purpose: Show how values are distributed (like macros, categories, etc.)
/// Simple stacked horizontal bar - no complexity.
public struct DistributionBar: View {
    // MARK: Lifecycle

    public init(
        segments: [Segment],
        height: CGFloat = 8,
        showLabels: Bool = false
    ) {
        self.segments = segments
        self.height = height
        self.showLabels = showLabels
    }

    // MARK: Public

    public struct Segment: Identifiable, Hashable {
        // MARK: Lifecycle

        public init(value: Double, color: Color, label: String? = nil, useGradient: Bool = true) {
            self.value = max(0, value) // Ensure non-negative
            self.color = color
            self.label = label
            self.useGradient = useGradient
        }

        // MARK: Public

        public let id = UUID()
        public let value: Double
        public let color: Color
        public let label: String?
        public let useGradient: Bool

        // MARK: Internal

        /// Create a premium gradient from the base color
        var gradient: LinearGradient {
            LinearGradient(
                colors: [
                    self.color,
                    self.color.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public let segments: [Segment]
    public let height: CGFloat
    public let showLabels: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingScale.xs.value) {
            // Distribution bar
            self.distributionBar

            // Labels if requested
            if self.showLabels {
                self.labelsView
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private var totalValue: Double {
        self.segments.reduce(0) { $0 + $1.value }
    }

    private var distributionBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(self.segments) { segment in
                    if segment.value > 0 && self.totalValue > 0 {
                        let width = (segment.value / self.totalValue) * geometry.size.width
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: width)
                    }
                }
            }
            .frame(height: self.height)
            .clipShape(RoundedRectangle(cornerRadius: self.height / 3))
        }
        .frame(height: self.height)
        .background(Color.gray.opacity(0.1))
    }

    private var labelsView: some View {
        VStack(alignment: .leading, spacing: SpacingScale.xxs.value) {
            ForEach(self.segments.filter { $0.label != nil }) { segment in
                HStack(spacing: SpacingScale.xxs.value) {
                    // Color dot
                    Circle()
                        .fill(segment.color)
                        .frame(width: SpacingScale.xs.value, height: SpacingScale.xs.value)

                    // Label
                    Text(segment.label!)
                        .font(self.theme.typography.caption1)
                        .foregroundColor(self.theme.colors.textSecondary)

                    Spacer()

                    // Value
                    Text(self.formatValue(segment.value))
                        .font(self.theme.typography.caption1)
                        .foregroundColor(self.theme.colors.textPrimary)

                    // Percentage
                    if self.totalValue > 0 {
                        Text(verbatim: "(\(Int((segment.value / self.totalValue) * 100))%)")
                            .font(self.theme.typography.caption2)
                            .foregroundColor(self.theme.colors.textTertiary)
                    }
                }
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            String(format: "%.0f", value)
        } else {
            String(format: "%.1f", value)
        }
    }
}

// MARK: - Convenience Initializers

extension DistributionBar {
    /// Create a macro distribution bar (protein, carbs, fat)
    public static func macros(
        protein: Double,
        carbs: Double,
        fat: Double,
        height: CGFloat = 8,
        showLabels: Bool = true
    ) -> DistributionBar {
        DistributionBar(
            segments: [
                Segment(value: protein * 4, color: .red, label: "Protein (\(Int(protein))g)", useGradient: true),
                Segment(value: carbs * 4, color: .orange, label: "Carbs (\(Int(carbs))g)", useGradient: true),
                Segment(value: fat * 9, color: .green, label: "Fat (\(Int(fat))g)", useGradient: true)
            ],
            height: height,
            showLabels: showLabels
        )
    }

    /// Create a workout type distribution
    public static func workoutTypes(
        strength: Double,
        cardio: Double,
        flexibility: Double,
        height: CGFloat = 8,
        showLabels: Bool = true
    ) -> DistributionBar {
        DistributionBar(
            segments: [
                Segment(value: strength, color: .red, label: "Strength", useGradient: true),
                Segment(value: cardio, color: .orange, label: "Cardio", useGradient: true),
                Segment(value: flexibility, color: .green, label: "Flexibility", useGradient: true)
            ],
            height: height,
            showLabels: showLabels
        )
    }

    /// Create a simple two-value distribution (completed vs remaining)
    public static func completion(
        completed: Double,
        total: Double,
        completedColor: Color = .green,
        remainingColor: Color = .gray,
        height: CGFloat = 8,
        showLabels: Bool = false
    ) -> DistributionBar {
        let remaining = max(0, total - completed)
        return DistributionBar(
            segments: [
                Segment(
                    value: completed,
                    color: completedColor,
                    label: showLabels ? "Completed" : nil,
                    useGradient: true
                ),
                Segment(
                    value: remaining,
                    color: remainingColor.opacity(0.3),
                    label: showLabels ? "Remaining" : nil,
                    useGradient: false
                )
            ],
            height: height,
            showLabels: showLabels
        )
    }

    /// Create a custom distribution from values and colors
    public static func custom(
        values: [(Double, Color, String?)],
        height: CGFloat = 8,
        showLabels: Bool = false
    ) -> DistributionBar {
        let segments = values.map { value, color, label in
            Segment(value: value, color: color, label: label, useGradient: true)
        }
        return DistributionBar(
            segments: segments,
            height: height,
            showLabels: showLabels
        )
    }
}

// MARK: - Array Extension for Safe Access

extension Array {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("Distribution Bars") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Distribution Bars")
                .font(.title2.bold())
                .padding()

            VStack(alignment: .leading, spacing: 20) {
                // Macro distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Macros (2,240 calories)")
                        .font(.headline)

                    DistributionBar.macros(
                        protein: 150, // 600 cal
                        carbs: 280, // 1120 cal
                        fat: 58, // 522 cal
                        height: 12,
                        showLabels: true
                    )
                }

                // Workout distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Workout Minutes")
                        .font(.headline)

                    DistributionBar.workoutTypes(
                        strength: 180,
                        cardio: 120,
                        flexibility: 45,
                        height: 10,
                        showLabels: true
                    )
                }

                // Simple completion bars
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Progress")
                        .font(.headline)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Daily Steps")
                            Spacer()
                            Text(verbatim: "8,543 / 10,000")
                                .font(.caption.weight(.medium))
                        }
                        DistributionBar.completion(completed: 8543, total: 10000, height: 6)
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("Water Intake")
                            Spacer()
                            Text("1.8L / 2.5L")
                                .font(.caption.weight(.medium))
                        }
                        DistributionBar.completion(
                            completed: 1.8,
                            total: 2.5,
                            completedColor: .cyan,
                            height: 6
                        )
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("Weekly Workouts")
                            Spacer()
                            Text(verbatim: "4 / 5")
                                .font(.caption.weight(.medium))
                        }
                        DistributionBar.completion(
                            completed: 4,
                            total: 5,
                            completedColor: .orange,
                            height: 6
                        )
                    }
                }

                // Custom distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Stages (7.5 hours)")
                        .font(.headline)

                    DistributionBar.custom(
                        values: [
                            (1.5, .purple, "Deep Sleep"),
                            (2.0, .blue, "Light Sleep"),
                            (3.2, .green, "REM Sleep"),
                            (0.8, .orange, "Awake")
                        ],
                        height: 12,
                        showLabels: true
                    )
                }

                // Size variations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Size Variations")
                        .font(.headline)

                    VStack(spacing: 8) {
                        Text("Thin (4pt)")
                            .font(.caption)
                        DistributionBar.custom(
                            values: [(60, .red, nil), (30, .blue, nil), (10, .green, nil)],
                            height: 4
                        )

                        Text("Medium (8pt)")
                            .font(.caption)
                        DistributionBar.custom(
                            values: [(60, .red, nil), (30, .blue, nil), (10, .green, nil)],
                            height: 8
                        )

                        Text("Thick (16pt)")
                            .font(.caption)
                        DistributionBar.custom(
                            values: [(60, .red, nil), (30, .blue, nil), (10, .green, nil)],
                            height: 16
                        )
                    }
                }
            }
        }
        .padding()
    }
}
