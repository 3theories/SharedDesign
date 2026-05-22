import SwiftUI

// MARK: - AnimatedNumberText

/// Animated number text component with rolling counter effect
public struct AnimatedNumberText: View {
    // MARK: Lifecycle

    public init(
        value: Double,
        format: NumberFormat = .integer,
        font: Font = .body,
        color: Color? = nil
    ) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
    }

    // MARK: Public

    /// Number formatting options
    public enum NumberFormat {
        case integer
        case decimal(places: Int)
        case percentage
        case currency(symbol: String = "$")
        case compact // 1K, 1.2M, etc
        case custom(formatter: NumberFormatter)

        // MARK: Internal

        var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            switch self {
            case .integer:
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
            case let .decimal(places):
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = places
                formatter.maximumFractionDigits = places
            case .percentage:
                formatter.numberStyle = .percent
                formatter.maximumFractionDigits = 1
            case let .currency(symbol):
                formatter.numberStyle = .currency
                formatter.currencySymbol = symbol
            case .compact:
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 1
            // Will handle compact formatting in the view
            case let .custom(customFormatter):
                return customFormatter
            }
            return formatter
        }
    }

    public var body: some View {
        Text(self.formattedValue)
            .font(self.font)
            .foregroundColor(self.color ?? self.theme.colors.textPrimary)
            .contentTransition(.numericText())
            .animation(AnimationConstants.Presets.numberCounter, value: self.animatedValue)
            .onAppear {
                self.animatedValue = self.value
            }
            .onChange(of: self.value) { _, newValue in
                withAnimation(AnimationConstants.Presets.numberCounter) {
                    self.animatedValue = newValue
                }
            }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedValue: Double = 0

    private let value: Double
    private let format: NumberFormat
    private let font: Font
    private let color: Color?

    private var formattedValue: String {
        if case .compact = self.format {
            return self.formatCompact(self.animatedValue)
        }
        return self.format.formatter.string(from: NSNumber(value: self.animatedValue)) ?? ""
    }

    private func formatCompact(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        switch absValue {
        case 0..<1000:
            return self.format.formatter.string(from: NSNumber(value: value)) ?? ""
        case 1000..<1_000_000:
            let thousands = value / 1000
            return "\(sign)\(String(format: "%.1f", thousands))K"
        case 1_000_000..<1_000_000_000:
            let millions = value / 1_000_000
            return "\(sign)\(String(format: "%.1f", millions))M"
        default:
            let billions = value / 1_000_000_000
            return "\(sign)\(String(format: "%.1f", billions))B"
        }
    }
}

// MARK: - AnimatedCounter

/// Animated counter view with prefix and suffix support
public struct AnimatedCounter: View {
    // MARK: Lifecycle

    public init(
        value: Double,
        prefix: String? = nil,
        suffix: String? = nil,
        format: AnimatedNumberText.NumberFormat = .integer,
        font: Font = .body,
        color: Color? = nil
    ) {
        self.value = value
        self.prefix = prefix
        self.suffix = suffix
        self.format = format
        self.font = font
        self.color = color
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: 4) {
            if let prefix {
                Text(prefix)
                    .font(self.font)
                    .foregroundColor(self.color ?? self.theme.colors.textSecondary)
            }

            AnimatedNumberText(
                value: self.value,
                format: self.format,
                font: self.font,
                color: self.color
            )

            if let suffix {
                Text(suffix)
                    .font(self.font)
                    .foregroundColor(self.color ?? self.theme.colors.textSecondary)
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let value: Double
    private let prefix: String?
    private let suffix: String?
    private let format: AnimatedNumberText.NumberFormat
    private let font: Font
    private let color: Color?
}

// MARK: - AnimatedNumberText_Previews

struct AnimatedNumberText_Previews: PreviewProvider {
    struct PreviewContent: View {
        // MARK: Internal

        var body: some View {
            VStack(spacing: 20) {
                AnimatedNumberText(value: self.value, format: .integer)
                AnimatedNumberText(value: self.percentage, format: .percentage)
                AnimatedNumberText(value: self.currency, format: .currency())
                AnimatedNumberText(value: self.compact, format: .compact)

                AnimatedCounter(
                    value: self.value,
                    prefix: "Score:",
                    suffix: "pts",
                    format: .integer
                )

                Button("Randomize") {
                    self.value = Double.random(in: 0...1000)
                    self.percentage = Double.random(in: 0...1)
                    self.currency = Double.random(in: 100...10000)
                    self.compact = Double.random(in: 1000...10_000_000)
                }
            }
            .padding()
        }

        // MARK: Private

        @State private var value = 0.0
        @State private var percentage = 0.75
        @State private var currency = 1234.56
        @State private var compact = 1_234_567.0
    }

    static var previews: some View {
        PreviewContent()
            .theme(DefaultTheme())
    }
}
