import SwiftUI

// MARK: - SimpleProgressView

/// A simple, clean progress view showing current value, target, and optional trend.
/// Single purpose: Display progress toward a goal with one key insight.
public struct SimpleProgressView: View {
    // MARK: Lifecycle

    public init(
        title: String,
        current: Double,
        target: Double,
        unit: String,
        insight: String? = nil,
        color: Color = .blue
    ) {
        self.title = title
        self.current = current
        self.target = target
        self.unit = unit
        self.insight = insight
        self.color = color
    }

    // MARK: Public

    public let title: String
    public let current: Double
    public let target: Double
    public let unit: String
    public let insight: String?
    public let color: Color

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(self.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(self.theme.colors.textSecondary)

                Spacer()

                if self.progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(self.color.opacity(0.15))

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(self.color)
                        .frame(width: geometry.size.width * self.animatedProgress)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: self.animatedProgress)
                }
            }
            .frame(height: 12)

            // Values
            HStack {
                Text(verbatim: "\(Int(self.current)) / \(Int(self.target)) \(self.unit)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(self.theme.colors.textPrimary)

                Spacer()

                Text(verbatim: "\(self.progressPercentage)%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(self.color)
            }

            // Optional insight
            if let insight {
                HStack(spacing: 4) {
                    Image("tips")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)

                    Text(insight)
                        .font(.caption)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.theme.colors.surface1)
        )
        .onAppear {
            self.animatedProgress = self.progress
        }
        .onChange(of: self.current) {
            self.animatedProgress = self.progress
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        self.target > 0 ? min(self.current / self.target, 1.0) : 0
    }

    private var progressPercentage: Int {
        Int(self.progress * 100)
    }
}

// MARK: - Convenience Initializers

extension SimpleProgressView {
    /// Create a fitness progress view
    public static func fitness(
        title: String,
        current: Double,
        target: Double,
        unit: String
    ) -> SimpleProgressView {
        let insight: String? = {
            let percentage = current / target
            if percentage >= 1.0 {
                return "Goal achieved!"
            } else if percentage >= 0.8 {
                return "Almost there! Keep going!"
            } else if percentage >= 0.5 {
                return "Halfway to your goal"
            } else {
                return "Stay consistent"
            }
        }()

        return SimpleProgressView(
            title: title,
            current: current,
            target: target,
            unit: unit,
            insight: insight,
            color: .red
        )
    }

    /// Create a nutrition progress view
    public static func nutrition(
        title: String,
        current: Double,
        target: Double,
        unit: String
    ) -> SimpleProgressView {
        SimpleProgressView(
            title: title,
            current: current,
            target: target,
            unit: unit,
            color: .green
        )
    }
}

// MARK: - Preview

#Preview("Simple Progress Views") {
    VStack(spacing: 16) {
        // Steps with trend
        SimpleProgressView(
            title: "Daily Steps",
            current: 8420,
            target: 10000,
            unit: "steps",
            insight: "On track to hit goal by 3pm",
            color: .blue
        )

        // Calories - goal achieved
        SimpleProgressView.fitness(
            title: "Calories Burned",
            current: 2150,
            target: 2000,
            unit: "cal"
        )

        // Protein - simple
        SimpleProgressView.nutrition(
            title: "Protein",
            current: 95,
            target: 120,
            unit: "g"
        )

        // Water - minimal
        SimpleProgressView(
            title: "Water Intake",
            current: 6,
            target: 8,
            unit: "glasses",
            color: .cyan
        )
    }
    .padding()
}
