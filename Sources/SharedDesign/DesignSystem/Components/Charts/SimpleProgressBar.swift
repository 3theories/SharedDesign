import SwiftUI

// MARK: - SimpleProgressBar

/// A clean, native-looking progress bar inspired by Apple's Health and Settings apps.
/// Replaces overdesigned glass morphism effects with simple, readable progress indicators.
public struct SimpleProgressBar: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        title: String? = nil,
        value: String? = nil,
        target: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        color: Color = .blue,
        backgroundColor: Color? = nil,
        height: CGFloat = 8,
        showPercentage: Bool = false,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.title = title
        self.value = value
        self.target = target
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.color = color
        self.backgroundColor = backgroundColor
        self.height = height
        self.showPercentage = showPercentage
        self.animated = animated
    }

    // MARK: Public

    public let progress: Double
    public let title: String?
    public let value: String?
    public let target: String?
    public let icon: String?
    public let isSystemIcon: Bool
    public let color: Color
    public let backgroundColor: Color?
    public let height: CGFloat
    public let showPercentage: Bool
    public let animated: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with title and value
            if self.title != nil || self.value != nil || self.showPercentage {
                self.headerView
            }

            // Progress bar
            self.progressBarView

            // Target information
            if self.target != nil {
                self.targetView
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.title ?? "Progress")
        .accessibilityValue("\(Int(self.progress * 100)) percent\(self.value != nil ? ", \(self.value!)" : "")")
    }

    // MARK: Private

    @State private var animatedProgress: Double = 0
    @Environment(\.theme) private var theme

    private var progressGradient: LinearGradient {
        // Subtle gradient for visual depth without overdesign
        LinearGradient(
            colors: [
                self.color,
                self.color.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var headerView: some View {
        HStack {
            // Icon and title
            HStack(spacing: 6) {
                if let icon {
                    AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                        .frame(width: 14, height: 14)
                        .foregroundColor(self.color)
                }

                if let title {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(self.theme.colors.textPrimary)
                }
            }

            Spacer()

            // Value and percentage
            HStack(spacing: 8) {
                if let value {
                    Text(value)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(self.theme.colors.textPrimary)
                }

                if self.showPercentage {
                    Text(verbatim: "\(Int(self.animatedProgress * 100))%")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(self.theme.colors.textSecondary)
                }
            }
        }
    }

    private var progressBarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: self.height / 2)
                    .fill(self.backgroundColor ?? self.theme.colors.surface2)
                    .frame(height: self.height)

                // Progress fill
                RoundedRectangle(cornerRadius: self.height / 2)
                    .fill(self.progressGradient)
                    .frame(
                        width: geometry.size.width * CGFloat(self.animatedProgress),
                        height: self.height
                    )
                    .animation(
                        self.animated ? .easeInOut(duration: 0.8) : .none,
                        value: self.animatedProgress
                    )
            }
        }
        .frame(height: self.height)
        .onAppear {
            if self.animated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.animatedProgress = self.progress
                }
            } else {
                self.animatedProgress = self.progress
            }
        }
        .onChange(of: self.progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.animatedProgress = newValue
            }
        }
    }

    private var targetView: some View {
        HStack {
            Image("target")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 11, height: 11)
                .foregroundColor(self.theme.colors.textTertiary)

            Text(L10n.format("chart.simple_progress.target_format", self.target!))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(self.theme.colors.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Convenience Initializers

extension SimpleProgressBar {
    /// Creates a progress bar for calorie tracking
    public static func calories(current: Double, target: Double, color: Color = .orange) -> SimpleProgressBar {
        SimpleProgressBar(
            progress: target > 0 ? current / target : 0,
            title: "Calories",
            value: "\(Int(current))",
            target: "\(Int(target)) cal",
            icon: "flame.fill",
            isSystemIcon: true,
            color: color,
            height: 8,
            showPercentage: false
        )
    }

    /// Creates a progress bar for macro tracking (protein, carbs, fat)
    public static func macro(
        name: String,
        current: Double,
        target: Double,
        icon: String,
        isSystemIcon: Bool = true,
        color: Color
    ) -> SimpleProgressBar {
        SimpleProgressBar(
            progress: target > 0 ? current / target : 0,
            title: name,
            value: "\(Int(current))g",
            target: "\(Int(target))g",
            icon: icon,
            isSystemIcon: isSystemIcon,
            color: color,
            backgroundColor: color.opacity(0.15),
            height: 6
        )
    }

    /// Creates a progress bar for steps tracking
    public static func steps(current: Int, target: Int, color: Color = .blue) -> SimpleProgressBar {
        SimpleProgressBar(
            progress: target > 0 ? Double(current) / Double(target) : 0,
            title: "Steps",
            value: "\(current.formatted())",
            target: "\(target.formatted()) steps",
            icon: "figure.walk",
            isSystemIcon: true,
            color: color,
            height: 8
        )
    }

    /// Locale-aware volume formatter for hydration values.
    private static let hydrationFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.minimumFractionDigits = 1
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Creates a progress bar for hydration tracking
    public static func hydration(current: Double, target: Double, color: Color = .cyan) -> SimpleProgressBar {
        let currentMeasurement = Measurement(value: current, unit: UnitVolume.liters)
        let targetMeasurement = Measurement(value: target, unit: UnitVolume.liters)
        return SimpleProgressBar(
            progress: target > 0 ? current / target : 0,
            title: "Water",
            value: self.hydrationFormatter.string(from: currentMeasurement),
            target: self.hydrationFormatter.string(from: targetMeasurement),
            icon: "drop.fill",
            isSystemIcon: true,
            color: color,
            height: 8
        )
    }

    /// Creates a progress bar for workout streak
    public static func streak(current: Int, target: Int, color: Color = .orange) -> SimpleProgressBar {
        SimpleProgressBar(
            progress: target > 0 ? Double(current) / Double(target) : 0,
            title: "Workout Streak",
            value: "\(current) days",
            target: "\(target) days",
            icon: "flame.fill",
            isSystemIcon: true,
            color: color,
            height: 8,
            showPercentage: true
        )
    }

    /// Creates a simple percentage progress bar
    public static func percentage(
        title: String,
        progress: Double,
        color: Color = .blue,
        icon: String? = nil,
        isSystemIcon: Bool = true
    ) -> SimpleProgressBar {
        SimpleProgressBar(
            progress: progress,
            title: title,
            icon: icon,
            isSystemIcon: isSystemIcon,
            color: color,
            height: 8,
            showPercentage: true
        )
    }
}

// MARK: - SimpleProgressGroup

public struct SimpleProgressGroup: View {
    // MARK: Lifecycle

    public init(progressBars: [SimpleProgressBar], spacing: CGFloat = 16) {
        self.progressBars = progressBars
        self.spacing = spacing
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: self.spacing) {
            ForEach(Array(self.progressBars.enumerated()), id: \.offset) { _, progressBar in
                progressBar
            }
        }
    }

    // MARK: Private

    private let progressBars: [SimpleProgressBar]
    private let spacing: CGFloat
}

// MARK: - Preview

#Preview("Simple Progress Bar") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Simple Progress Bars")
                .font(.title2.bold())
                .padding()

            VStack(spacing: 20) {
                // Individual examples
                SimpleProgressBar.calories(current: 1850, target: 2200)

                SimpleProgressBar.steps(current: 8543, target: 10000)

                SimpleProgressBar.hydration(current: 1.8, target: 2.5)

                SimpleProgressBar.streak(current: 12, target: 30)

                // Macro examples
                VStack(spacing: 12) {
                    Text("Daily Macros")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SimpleProgressBar.macro(
                        name: "Protein",
                        current: 85,
                        target: 120,
                        icon: "flame.fill",
                        color: .red
                    )

                    SimpleProgressBar.macro(
                        name: "Carbs",
                        current: 180,
                        target: 200,
                        icon: "bolt.fill",
                        color: .blue
                    )

                    SimpleProgressBar.macro(
                        name: "Fat",
                        current: 45,
                        target: 60,
                        icon: "drop.fill",
                        color: .yellow
                    )
                }

                // Grouped example
                SimpleProgressGroup(progressBars: [
                    .percentage(
                        title: "Workout Completion",
                        progress: 0.75,
                        color: .green,
                        icon: "liftWeight",
                        isSystemIcon: false
                    ),
                    .percentage(
                        title: "Sleep Quality",
                        progress: 0.88,
                        color: .purple,
                        icon: "sleep",
                        isSystemIcon: false
                    ),
                    .percentage(title: "Recovery Score", progress: 0.62, color: .orange, icon: "heart.fill")
                ])
            }
            .padding(.horizontal)
        }
    }
}

#Preview("Progress States") {
    VStack(spacing: 16) {
        Text("Progress States")
            .font(.headline)

        SimpleProgressBar.percentage(title: "Empty", progress: 0.0, color: .gray)

        SimpleProgressBar.percentage(title: "Low", progress: 0.15, color: .red)

        SimpleProgressBar.percentage(title: "Half", progress: 0.5, color: .orange)

        SimpleProgressBar.percentage(title: "High", progress: 0.85, color: .green)

        SimpleProgressBar.percentage(title: "Complete", progress: 1.0, color: .blue)

        SimpleProgressBar.percentage(title: "Over Target", progress: 1.2, color: .purple)
    }
    .padding()
}
