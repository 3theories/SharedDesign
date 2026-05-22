import SwiftUI

// MARK: - MetricCard

/// A simple card to display a single metric with optional trend indicator.
/// Single purpose: Show one metric with optional change/trend info.
/// Clean, minimal design that works everywhere.
public struct MetricCard: View {
    // MARK: Lifecycle

    public init(
        title: String,
        value: String,
        change: String? = nil,
        changeValue: Double? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        color: Color = .blue,
        size: CardSize = .medium
    ) {
        self.title = title
        self.value = value
        self.change = change
        self.changeValue = changeValue
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.color = color
        self.size = size
    }

    // MARK: Public

    public enum CardSize {
        case small // Compact for grids
        case medium // Standard size
        case large // Hero metric

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
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: 12
            case .medium: 16
            case .large: 20
            }
        }
    }

    public let title: String
    public let value: String
    public let change: String?
    public let changeValue: Double?
    public let icon: String?
    public let isSystemIcon: Bool
    public let color: Color
    public let size: CardSize

    public var body: some View {
        VStack(alignment: .leading, spacing: self.size == .small ? 4 : 8) {
            // Header with icon and title
            HStack(spacing: 6) {
                if let icon {
                    AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                        .frame(width: self.size.iconSize - 2, height: self.size.iconSize - 2)
                        .foregroundColor(self.color)
                }

                Text(self.title)
                    .font(self.size.titleFont.weight(.medium))
                    .foregroundColor(self.theme.colors.textSecondary)

                Spacer()
            }

            // Main value
            Text(self.value)
                .font(self.size.valueFont)
                .foregroundColor(self.theme.colors.textPrimary)

            // Change indicator
            if let change {
                self.changeIndicator(text: change)
            }
        }
        .padding(self.size.padding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.theme.colors.surface1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel([self.title, self.value, self.change].compactMap { $0 }.joined(separator: ", "))
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private func changeIndicator(text: String) -> some View {
        HStack(spacing: 4) {
            if let changeValue {
                Image(systemName: changeValue >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(changeValue >= 0 ? .green : .red)
            }

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(
                    changeValue == nil
                        ? self.theme.colors.textTertiary
                        : (changeValue! >= 0 ? .green : .red)
                )
        }
    }
}

// MARK: - Convenience Initializers

extension MetricCard {
    /// Locale-aware signed number formatter (1 fraction digit) for percentage changes.
    private static let signedDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Locale-aware signed number formatter (0 fraction digits) for absolute changes.
    private static let signedIntegerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Create a metric card with percentage change
    public static func withPercentageChange(
        title: String,
        value: String,
        changePercent: Double,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        color: Color = .blue,
        size: CardSize = .medium
    ) -> MetricCard {
        let formatted = self.signedDecimalFormatter.string(from: NSNumber(value: changePercent)) ?? "\(changePercent)"
        let changeText = "\(formatted)%"
        return MetricCard(
            title: title,
            value: value,
            change: changeText,
            changeValue: changePercent,
            icon: icon,
            isSystemIcon: isSystemIcon,
            color: color,
            size: size
        )
    }

    /// Create a metric card with absolute change
    public static func withAbsoluteChange(
        title: String,
        value: String,
        change: Double,
        unit: String = "",
        icon: String? = nil,
        isSystemIcon: Bool = true,
        color: Color = .blue,
        size: CardSize = .medium
    ) -> MetricCard {
        let formatted = self.signedIntegerFormatter.string(from: NSNumber(value: change)) ?? "\(Int(change))"
        let changeText = "\(formatted)\(unit)"
        return MetricCard(
            title: title,
            value: value,
            change: changeText,
            changeValue: change,
            icon: icon,
            isSystemIcon: isSystemIcon,
            color: color,
            size: size
        )
    }

    /// Create a fitness metric card
    public static func fitness(
        title: String,
        value: String,
        change: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = false
    ) -> MetricCard {
        MetricCard(
            title: title,
            value: value,
            change: change,
            icon: icon ?? "liftWeight",
            isSystemIcon: isSystemIcon,
            color: .red
        )
    }

    /// Create a nutrition metric card
    public static func nutrition(
        title: String,
        value: String,
        change: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true
    ) -> MetricCard {
        MetricCard(
            title: title,
            value: value,
            change: change,
            icon: icon ?? "leaf.fill",
            isSystemIcon: isSystemIcon,
            color: .green
        )
    }

    /// Create a health metric card
    public static func health(
        title: String,
        value: String,
        change: String? = nil,
        icon: String? = nil,
        isSystemIcon: Bool = true
    ) -> MetricCard {
        MetricCard(
            title: title,
            value: value,
            change: change,
            icon: icon ?? "heart.fill",
            isSystemIcon: isSystemIcon,
            color: .pink
        )
    }
}

// MARK: - MetricGrid

public struct MetricGrid: View {
    // MARK: Lifecycle

    public init(cards: [MetricCard], columns: Int = 2, spacing: CGFloat = 12) {
        self.cards = cards
        self.columns = columns
        self.spacing = spacing
    }

    // MARK: Public

    public var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

        LazyVGrid(columns: gridColumns, spacing: self.spacing) {
            ForEach(Array(self.cards.enumerated()), id: \.offset) { _, card in
                card
            }
        }
    }

    // MARK: Private

    private let cards: [MetricCard]
    private let columns: Int
    private let spacing: CGFloat
}

// MARK: - Preview

#Preview("Metric Cards") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Metric Cards")
                .font(.title2.bold())
                .padding()

            // Individual examples
            VStack(spacing: 16) {
                MetricCard.fitness(
                    title: "Workouts This Week",
                    value: "4",
                    change: "+1 from last week"
                )

                MetricCard.withPercentageChange(
                    title: "Average Heart Rate",
                    value: "142 bpm",
                    changePercent: 3.2,
                    icon: "heart.fill",
                    color: .red
                )

                MetricCard.nutrition(
                    title: "Calories Today",
                    value: "1,847",
                    change: "347 below target"
                )
            }

            // Size variations
            VStack(spacing: 16) {
                Text("Size Variations")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MetricCard(
                    title: "Large Hero Metric",
                    value: "10,428",
                    change: "+2,104 steps",
                    changeValue: 2104,
                    icon: "figure.walk",
                    color: .blue,
                    size: .large
                )

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Medium",
                        value: "67%",
                        change: "+5%",
                        changeValue: 5,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        size: .medium
                    )

                    MetricCard(
                        title: "Small",
                        value: "8.2",
                        change: "Excellent",
                        icon: "sleep",
                        isSystemIcon: false,
                        color: .purple,
                        size: .small
                    )
                }
            }

            // Grid example
            VStack(spacing: 16) {
                Text("Metric Grid")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MetricGrid(cards: [
                    .fitness(title: "Workouts", value: "23", change: "+4"),
                    .nutrition(title: "Protein", value: "87g", change: "On track"),
                    .health(title: "Sleep", value: "7.5h", change: "+0.5h"),
                    .withAbsoluteChange(
                        title: "Weight",
                        value: "165 lb",
                        change: -2.1,
                        unit: " lb",
                        icon: "scalemass.fill",
                        color: .orange
                    )
                ])
            }
        }
        .padding()
    }
}
