import SwiftUI

// MARK: - TrendIndicator

/// A simple trend indicator showing direction and change amount.
/// Single purpose: Show if something is up/down and by how much.
/// Just an arrow and change amount - nothing fancy.
public struct TrendIndicator: View {
    // MARK: Lifecycle

    public init(
        current: Double,
        previous: Double,
        format: Format = .percentage,
        size: Size = .medium,
        showNeutral: Bool = true
    ) {
        self.current = current
        self.previous = previous
        self.format = format
        self.size = size
        self.showNeutral = showNeutral
    }

    // MARK: Public

    public enum Format {
        case percentage // Show as percentage change
        case number // Show as absolute change
        case custom(String) // Show with custom unit

        // MARK: Internal

        func formatChange(_ change: Double, _ percentChange: Double) -> String {
            switch self {
            case .percentage:
                let formatted = Self.changeFormatter.string(from: NSNumber(value: percentChange)) ?? "\(percentChange)"
                return "\(formatted)%"
            case .number:
                return Self.changeFormatter.string(from: NSNumber(value: change)) ?? "\(change)"
            case let .custom(unit):
                let formatted = Self.changeFormatter.string(from: NSNumber(value: change)) ?? "\(change)"
                return "\(formatted)\(unit)"
            }
        }

        // MARK: Private

        /// Locale-aware number formatter for trend change values (1 fraction digit).
        private static let changeFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            return formatter
        }()
    }

    public enum Size {
        case small
        case medium
        case large

        // MARK: Internal

        var iconFont: Font {
            switch self {
            case .small: .caption2.weight(.semibold)
            case .medium: .caption.weight(.semibold)
            case .large: .footnote.weight(.semibold)
            }
        }

        var textFont: Font {
            switch self {
            case .small: .caption2.weight(.medium)
            case .medium: .caption.weight(.medium)
            case .large: .footnote.weight(.medium)
            }
        }
    }

    public let current: Double
    public let previous: Double
    public let format: Format
    public let size: Size
    public let showNeutral: Bool

    public var body: some View {
        HStack(spacing: 4) {
            if self.isNeutral && self.showNeutral {
                self.neutralIndicator
            } else {
                self.trendIcon
                self.trendText
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private var change: Double {
        self.current - self.previous
    }

    private var percentChange: Double {
        guard self.previous != 0 else {
            return self.current > 0 ? 100 : 0
        }
        return (self.change / abs(self.previous)) * 100
    }

    private var isPositive: Bool {
        self.change > 0
    }

    private var isNeutral: Bool {
        abs(self.change) < 0.01
    }

    private var neutralIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "minus")
                .font(self.size.iconFont)
                .foregroundColor(self.theme.colors.textTertiary)
                .accessibilityHidden(true)

            Text(String(
                localized: "trend.noChange.label",
                defaultValue: "No change",
                bundle: .module,
                comment: "Trend indicator label when there is no change"
            ))
            .font(self.size.textFont)
            .foregroundColor(self.theme.colors.textTertiary)
        }
    }

    private var trendIcon: some View {
        Image(systemName: self.isPositive ? "arrow.up" : "arrow.down")
            .font(self.size.iconFont)
            .foregroundColor(self.isPositive ? .green : .red)
            .accessibilityHidden(true)
    }

    private var trendText: some View {
        Text(self.format.formatChange(abs(self.change), abs(self.percentChange)))
            .font(self.size.textFont)
            .foregroundColor(self.isPositive ? .green : .red)
    }
}

// MARK: - Convenience Initializers

extension TrendIndicator {
    /// Show percentage change
    public static func percentage(
        current: Double,
        previous: Double,
        size: Size = .medium
    ) -> TrendIndicator {
        TrendIndicator(
            current: current,
            previous: previous,
            format: .percentage,
            size: size
        )
    }

    /// Show absolute number change
    public static func absolute(
        current: Double,
        previous: Double,
        size: Size = .medium
    ) -> TrendIndicator {
        TrendIndicator(
            current: current,
            previous: previous,
            format: .number,
            size: size
        )
    }

    /// Show change with custom unit
    public static func withUnit(
        current: Double,
        previous: Double,
        unit: String,
        size: Size = .medium
    ) -> TrendIndicator {
        TrendIndicator(
            current: current,
            previous: previous,
            format: .custom(unit),
            size: size
        )
    }

    /// Fitness trend indicator
    public static func fitness(
        current: Double,
        previous: Double,
        unit: String = "",
        size: Size = .medium
    ) -> TrendIndicator {
        TrendIndicator(
            current: current,
            previous: previous,
            format: unit.isEmpty ? .percentage : .custom(unit),
            size: size
        )
    }
}

// MARK: - TrendBadge

public struct TrendBadge: View {
    // MARK: Lifecycle

    public init(
        current: Double,
        previous: Double,
        format: TrendIndicator.Format = .percentage,
        size: TrendIndicator.Size = .medium,
        style: BadgeStyle = .pill
    ) {
        self.indicator = TrendIndicator(
            current: current,
            previous: previous,
            format: format,
            size: size
        )
        self.style = style
    }

    // MARK: Public

    public enum BadgeStyle {
        case pill // Rounded pill background
        case rounded // Rounded rectangle
        case minimal // No background
    }

    public var body: some View {
        self.indicator
            .padding(.horizontal, self.style == .minimal ? 0 : 8)
            .padding(.vertical, self.style == .minimal ? 0 : 4)
            .background(
                self.backgroundView
            )
    }

    // MARK: Private

    private let indicator: TrendIndicator
    private let style: BadgeStyle

    private var backgroundColors: Color {
        guard self.style != .minimal else {
            return .clear
        }

        let change = self.indicator.current - self.indicator.previous
        if abs(change) < 0.01 {
            return Color.gray.opacity(0.1)
        }
        return change > 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch self.style {
        case .pill:
            Capsule()
                .fill(self.backgroundColors)
        case .rounded:
            RoundedRectangle(cornerRadius: 6)
                .fill(self.backgroundColors)
        case .minimal:
            Rectangle()
                .fill(Color.clear)
        }
    }
}

// MARK: - Preview

#Preview("Trend Indicators") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Trend Indicators")
                .font(.title2.bold())
                .padding()

            // Basic examples
            VStack(alignment: .leading, spacing: 16) {
                Text("Basic Trends")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .font(.subheadline.weight(.medium))
                        Text("165.2 lb")
                            .font(.title3.weight(.bold))
                        TrendIndicator.withUnit(current: 165.2, previous: 167.8, unit: " lb")
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps")
                            .font(.subheadline.weight(.medium))
                        Text(verbatim: "12,437")
                            .font(.title3.weight(.bold))
                        TrendIndicator.percentage(current: 12437, previous: 10821)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sleep")
                            .font(.subheadline.weight(.medium))
                        Text("7.5 hrs")
                            .font(.title3.weight(.bold))
                        TrendIndicator.withUnit(current: 7.5, previous: 7.1, unit: "h")
                    }
                }
            }

            // Size variations
            VStack(alignment: .leading, spacing: 16) {
                Text("Size Variations")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Small")
                            .font(.caption)
                        TrendIndicator.percentage(current: 85, previous: 78, size: .small)
                    }

                    VStack(spacing: 8) {
                        Text("Medium")
                            .font(.caption)
                        TrendIndicator.percentage(current: 85, previous: 78, size: .medium)
                    }

                    VStack(spacing: 8) {
                        Text("Large")
                            .font(.caption)
                        TrendIndicator.percentage(current: 85, previous: 78, size: .large)
                    }

                    Spacer()
                }
            }

            // Trend badges
            VStack(alignment: .leading, spacing: 16) {
                Text("Trend Badges")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text("Pill")
                            .font(.caption)
                        TrendBadge(current: 2450, previous: 2200, style: .pill)
                    }

                    VStack(spacing: 8) {
                        Text("Rounded")
                            .font(.caption)
                        TrendBadge(current: 92, previous: 88, style: .rounded)
                    }

                    VStack(spacing: 8) {
                        Text("Minimal")
                            .font(.caption)
                        TrendBadge(current: 15.5, previous: 18.2, format: .custom("min"), style: .minimal)
                    }

                    Spacer()
                }
            }

            // Different scenarios
            VStack(alignment: .leading, spacing: 16) {
                Text("Different Scenarios")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    HStack {
                        Text("Positive change:")
                        Spacer()
                        TrendIndicator.percentage(current: 150, previous: 120)
                    }

                    HStack {
                        Text("Negative change:")
                        Spacer()
                        TrendIndicator.withUnit(current: 45, previous: 52, unit: " bpm")
                    }

                    HStack {
                        Text("No change:")
                        Spacer()
                        TrendIndicator.absolute(current: 100, previous: 100)
                    }

                    HStack {
                        Text("Large increase:")
                        Spacer()
                        TrendIndicator.percentage(current: 500, previous: 200)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding()
    }
}
