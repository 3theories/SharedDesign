import Charts
import SwiftUI

// MARK: - MetricCardStyle

/// Style variants for SharedMetricCard
public enum MetricCardStyle {
    /// Compact display with icon, title, and value only
    case compact

    /// Standard card with icon, title, value, and optional subtitle
    case standard

    /// Card with progress bar indicator
    case withProgress

    /// Card with mini sparkline chart
    case withChart

    /// Large hero metric display
    case hero
}

// MARK: - MetricCardSize

/// Size presets for SharedMetricCard
public enum MetricCardSize {
    case small
    case medium
    case large

    // MARK: Internal

    var titleFont: Font {
        switch self {
        case .small: .caption
        case .medium: .subheadline
        case .large: .headline
        }
    }

    var valueFont: Font {
        switch self {
        case .small: .title3.weight(.bold)
        case .medium: .title2.weight(.bold)
        case .large: .largeTitle.weight(.bold)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: 14
        case .medium: 18
        case .large: 24
        }
    }

    var iconBackgroundSize: CGFloat {
        switch self {
        case .small: 28
        case .medium: 36
        case .large: 48
        }
    }
}

// MARK: - MetricChartPoint

/// Data point for sparkline charts in metric cards
public struct MetricChartPoint: Identifiable, Sendable {
    // MARK: Lifecycle

    public init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }

    // MARK: Public

    public let id: UUID
    public let date: Date
    public let value: Double
}

// MARK: - MetricChange

/// Trend/change indicator configuration
public struct MetricChange: Sendable {
    // MARK: Lifecycle

    public init(text: String, value: Double? = nil, isPositiveGood: Bool = true) {
        self.text = text
        self.value = value
        self.isPositiveGood = isPositiveGood
    }

    // MARK: Public

    public let text: String
    public let value: Double?
    public let isPositiveGood: Bool

    /// Create from percentage change
    public static func percentage(_ percent: Double, isPositiveGood: Bool = true) -> MetricChange {
        let formatted = self.signedDecimalFormatter.string(from: NSNumber(value: percent)) ?? "\(percent)"
        return MetricChange(
            text: "\(formatted)%",
            value: percent,
            isPositiveGood: isPositiveGood
        )
    }

    /// Create from absolute change
    public static func absolute(_ change: Double, unit: String = "", isPositiveGood: Bool = true) -> MetricChange {
        let formatted = self.signedIntegerFormatter.string(from: NSNumber(value: change)) ?? "\(Int(change))"
        return MetricChange(
            text: "\(formatted)\(unit)",
            value: change,
            isPositiveGood: isPositiveGood
        )
    }

    // MARK: Private

    /// Locale-aware signed number formatter for metric changes (1 fraction digit).
    private static let signedDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Locale-aware signed number formatter for metric changes (0 fraction digits).
    private static let signedIntegerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - SharedMetricCard

/// Unified metric card component that consolidates multiple card variants
/// into a single, flexible component with consistent styling.
public struct SharedMetricCard: View {
    // MARK: Lifecycle

    public init(
        title: String,
        value: String,
        color: Color,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        subtitle: String? = nil,
        unit: String? = nil,
        style: MetricCardStyle = .standard,
        size: MetricCardSize = .medium,
        progress: Double? = nil,
        chartData: [MetricChartPoint] = [],
        chartMaxValue: Double? = nil,
        change: MetricChange? = nil,
        showQuickAdd: Bool = false,
        onQuickAdd: (() -> Void)? = nil,
        showChevron: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.subtitle = subtitle
        self.unit = unit
        self.style = style
        self.size = size
        self.progress = progress
        self.chartData = chartData
        self.chartMaxValue = chartMaxValue
        self.change = change
        self.showQuickAdd = showQuickAdd
        self.onQuickAdd = onQuickAdd
        self.showChevron = showChevron
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Group {
            switch self.style {
            case .compact:
                self.compactContent
            case .standard:
                self.standardContent
            case .withProgress:
                self.progressContent
            case .withChart:
                self.chartContent
            case .hero:
                self.heroContent
            }
        }
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
        .conditionalModifier(self.onTap != nil) { view in
            view.pressState(.card)
        }
        .onTapGesture {
            if let onTap {
                HapticManager.shared.trigger(.light)
                onTap()
            }
        }
        .onAppear {
            withAnimation(AnimationConstants.Spring.gentle.delay(0.1)) {
                self.hasAppeared = true
                self.iconScale = 1.0
                self.ringProgress = 1.0
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.title), \(self.value)\(self.unit != nil ? " \(self.unit!)" : "")")
        .accessibilityHint(self.onTap != nil ? "Double tap for details" : "")
    }

    // MARK: Internal

    // Required properties
    let title: String
    let value: String
    let color: Color

    // Optional properties
    let icon: String?
    let isSystemIcon: Bool
    let subtitle: String?
    let unit: String?
    let style: MetricCardStyle
    let size: MetricCardSize

    /// Progress (for .withProgress style)
    let progress: Double?

    // Chart data (for .withChart style)
    let chartData: [MetricChartPoint]
    let chartMaxValue: Double?

    /// Change indicator
    let change: MetricChange?

    // Actions
    let showQuickAdd: Bool
    let onQuickAdd: (() -> Void)?
    let showChevron: Bool
    let onTap: (() -> Void)?

    // MARK: Private

    // Animation states
    @State private var hasAppeared = false
    @State private var iconScale: CGFloat = 0.8
    @State private var ringProgress: CGFloat = 0

    @Environment(\.theme) private var theme

    // MARK: - Compact Style

    private var compactContent: some View {
        HStack(spacing: self.theme.spacing.sm) {
            self.iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(self.size.titleFont)
                    .foregroundStyle(self.theme.colors.textSecondary)
                self.valueView
            }
            Spacer()
            if self.showChevron {
                self.chevronView
            }
        }
        .padding(self.theme.spacing.sm)
    }

    // MARK: - Standard Style

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            self.headerRow
            self.valueView
            if let subtitle {
                Text(subtitle)
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
            if let change {
                self.changeIndicator(change)
            }
        }
        .padding(self.theme.spacing.md)
    }

    // MARK: - Progress Style

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            Text(self.title)
                .font(self.theme.typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(self.color)

            self.valueView
                .frame(maxWidth: .infinity, alignment: .leading)

            if let subtitle {
                Text(subtitle)
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }

            if let progress {
                self.progressBar(progress: progress)
            }
        }
        .padding(.vertical, self.theme.spacing.sm)
        .padding(.horizontal, self.theme.spacing.md)
        .background(self.color.opacity(0.1))
    }

    // MARK: - Chart Style

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            self.headerRow
            self.valueView
                .padding(.leading, 4)

            if !self.chartData.isEmpty {
                self.sparklineChart
                    .frame(height: 35)
                    .padding(.top, self.theme.spacing.md)
            }
        }
        .padding(self.theme.spacing.md)
    }

    // MARK: - Hero Style

    private var heroContent: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.md) {
            self.headerRow

            HStack(alignment: .firstTextBaseline, spacing: self.theme.spacing.xs) {
                Text(self.value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .contentTransition(.numericText())

                if let unit {
                    Text(unit)
                        .font(self.theme.typography.title3)
                        .foregroundStyle(self.theme.colors.textSecondary)
                }
            }

            if let change {
                self.changeIndicator(change)
            }

            if let subtitle {
                Text(subtitle)
                    .font(self.theme.typography.body)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
        .padding(self.theme.spacing.lg)
    }

    // MARK: - Shared Components

    private var headerRow: some View {
        HStack(spacing: self.theme.spacing.sm) {
            if self.icon != nil {
                self.iconView
            }

            Text(self.title)
                .font(self.size.titleFont)
                .foregroundStyle(self.theme.colors.textSecondary)

            Spacer()

            if self.showQuickAdd {
                Button {
                    HapticManager.shared.trigger(.light)
                    self.onQuickAdd?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(self.color)
                        .font(.title3)
                        .accessibilityLabel("Quick Add")
                }
            }

            if self.showChevron {
                self.chevronView
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            ZStack {
                Circle()
                    .fill(self.color.opacity(0.15))
                    .frame(width: self.size.iconBackgroundSize, height: self.size.iconBackgroundSize)

                // Animated ring
                Circle()
                    .trim(from: 0, to: self.ringProgress)
                    .stroke(
                        self.color.gradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: self.size.iconBackgroundSize, height: self.size.iconBackgroundSize)
                    .rotationEffect(.degrees(-90))

                AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                    .frame(width: self.size.iconSize, height: self.size.iconSize)
                    .foregroundColor(self.color)
                    .scaleEffect(self.iconScale)
                    .accessibilityHidden(true)
            }
        }
    }

    private var valueView: some View {
        HStack(alignment: .firstTextBaseline, spacing: self.theme.spacing.xxs) {
            Text(self.value)
                .font(self.size.valueFont)
                .foregroundStyle(self.theme.colors.textPrimary)
                .contentTransition(.numericText())
                .animation(AnimationConstants.Presets.numberCounter, value: self.value)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let unit, self.style != .hero {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
    }

    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(self.theme.colors.textTertiary)
            .accessibilityHidden(true)
    }

    private var sparklineChart: some View {
        let filteredData = self.chartData.filter { !Calendar.current.isDateInToday($0.date) }
        let actualMax = filteredData.map(\.value).max() ?? 0
        let chartMax = max(self.chartMaxValue ?? actualMax, actualMax) * 1.3

        return Chart(filteredData) { point in
            let clampedValue = min(point.value, chartMax)

            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", clampedValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(self.color.gradient)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            AreaMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", clampedValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [self.color.opacity(0.2), self.color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...chartMax)
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(self.theme.colors.surface3)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(self.color.gradient)
                    .frame(
                        width: self.hasAppeared ? geometry.size.width * min(progress, 1.0) : 0,
                        height: 4
                    )
                    .animation(self.theme.animations.spring, value: self.hasAppeared)
            }
        }
        .frame(height: 4)
    }

    private func changeIndicator(_ change: MetricChange) -> some View {
        HStack(spacing: 4) {
            if let value = change.value {
                let isPositive = value >= 0
                let isGood = change.isPositiveGood ? isPositive : !isPositive
                let indicatorColor: Color = isGood ? self.theme.colors.success : self.theme.colors.error

                Image(isPositive ? "arrowupright" : "arrowdownright").resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(indicatorColor)
                    .accessibilityHidden(true)

                Text(change.text)
                    .font(.caption.weight(.medium))
                    .foregroundColor(indicatorColor)
            } else {
                Text(change.text)
                    .font(.caption.weight(.medium))
                    .foregroundColor(self.theme.colors.textTertiary)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension SharedMetricCard {
    /// Create a fitness-themed metric card
    public static func fitness(
        title: String,
        value: String,
        icon: String = "liftWeight",
        isSystemIcon: Bool = false,
        subtitle: String? = nil,
        change: MetricChange? = nil,
        style: MetricCardStyle = .standard
    ) -> SharedMetricCard {
        SharedMetricCard(
            title: title,
            value: value,
            color: .red,
            icon: icon,
            isSystemIcon: isSystemIcon,
            subtitle: subtitle,
            style: style,
            change: change
        )
    }

    /// Create a nutrition-themed metric card
    public static func nutrition(
        title: String,
        value: String,
        icon: String = "leaf.fill",
        isSystemIcon: Bool = true,
        subtitle: String? = nil,
        change: MetricChange? = nil,
        style: MetricCardStyle = .standard
    ) -> SharedMetricCard {
        SharedMetricCard(
            title: title,
            value: value,
            color: .green,
            icon: icon,
            isSystemIcon: isSystemIcon,
            subtitle: subtitle,
            style: style,
            change: change
        )
    }

    /// Create a health-themed metric card
    public static func health(
        title: String,
        value: String,
        icon: String = "heart.fill",
        isSystemIcon: Bool = true,
        subtitle: String? = nil,
        change: MetricChange? = nil,
        style: MetricCardStyle = .standard
    ) -> SharedMetricCard {
        SharedMetricCard(
            title: title,
            value: value,
            color: .pink,
            icon: icon,
            isSystemIcon: isSystemIcon,
            subtitle: subtitle,
            style: style,
            change: change
        )
    }

    /// Create a stat card (similar to WorkoutCompletionStatCard)
    public static func stat(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String,
        isSystemIcon: Bool = true,
        color: Color
    ) -> SharedMetricCard {
        SharedMetricCard(
            title: title,
            value: value,
            color: color,
            icon: icon,
            isSystemIcon: isSystemIcon,
            unit: unit,
            style: .compact
        )
    }
}

// MARK: - Preview

#Preview("SharedMetricCard Styles") {
    let sampleChartData = (0..<7).map { dayOffset in
        MetricChartPoint(
            date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!,
            value: Double.random(in: 3000...8000)
        )
    }.reversed()

    ScrollView {
        VStack(spacing: 24) {
            Text("SharedMetricCard Styles")
                .font(.title2.bold())

            // Compact
            VStack(alignment: .leading, spacing: 8) {
                Text("Compact").font(.headline)
                SharedMetricCard.stat(
                    title: "Duration",
                    value: "45",
                    unit: "min",
                    icon: "duration",
                    isSystemIcon: false,
                    color: .purple
                )
            }

            // Standard
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard").font(.headline)
                SharedMetricCard.fitness(
                    title: "Workouts This Week",
                    value: "4",
                    change: .absolute(1, unit: " from last week")
                )
            }

            // With Progress
            VStack(alignment: .leading, spacing: 8) {
                Text("With Progress").font(.headline)
                SharedMetricCard(
                    title: "Daily Steps",
                    value: "7,234",
                    color: .blue,
                    subtitle: "Target: 10,000",
                    style: .withProgress,
                    progress: 0.72
                )
            }

            // With Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("With Chart").font(.headline)
                SharedMetricCard(
                    title: "Steps",
                    value: "8,234",
                    color: .blue,
                    icon: "figure.walk",
                    style: .withChart,
                    chartData: Array(sampleChartData),
                    chartMaxValue: 10000
                )
                .frame(width: 180)
            }

            // Hero
            VStack(alignment: .leading, spacing: 8) {
                Text("Hero").font(.headline)
                SharedMetricCard(
                    title: "Total Calories",
                    value: "1,847",
                    color: .orange,
                    icon: "flame.fill",
                    subtitle: "347 below daily target",
                    unit: "kcal",
                    style: .hero,
                    change: .percentage(-15.2, isPositiveGood: false)
                )
            }
        }
        .padding()
    }
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
    .environment(\.theme, DefaultTheme())
}
