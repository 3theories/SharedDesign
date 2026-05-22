import SwiftUI

// MARK: - NumberAnimationStyle

/// Animation style for number transitions
public enum NumberAnimationStyle: Sendable {
    /// Smooth counting animation
    case counting

    /// Spring bounce animation
    case spring

    /// Quick snap animation
    case snap

    /// Eased transition
    case eased

    // MARK: Internal

    var animation: Animation {
        switch self {
        case .counting:
            .easeOut(duration: 0.8)
        case .spring:
            .spring(response: 0.5, dampingFraction: 0.7)
        case .snap:
            .easeOut(duration: 0.2)
        case .eased:
            .easeInOut(duration: 0.5)
        }
    }
}

// MARK: - NumberFormat

/// Format options for displaying numbers
public enum NumberFormat: Sendable {
    /// No formatting (raw number)
    case raw

    /// Add thousand separators (1,234)
    case decimal

    /// Compact format (1.2k, 1.5M)
    case compact

    /// Percentage (75%)
    case percentage

    /// Currency ($1,234)
    case currency(symbol: String)

    /// Custom format string
    case custom(format: String)
}

// MARK: - AnimatedNumber

/// A component that animates number value changes with smooth transitions
public struct AnimatedNumber: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        value: Double,
        format: NumberFormat = .decimal,
        animationStyle: NumberAnimationStyle = .counting,
        font: Font = .title2.bold(),
        color: Color? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        decimalPlaces: Int = 0,
        showSign: Bool = false
    ) {
        self.value = value
        self.format = format
        self.animationStyle = animationStyle
        self.font = font
        self.color = color
        self.prefix = prefix
        self.suffix = suffix
        self.decimalPlaces = decimalPlaces
        self.showSign = showSign
    }

    // MARK: Public

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            if let prefix {
                Text(prefix)
                    .font(self.font)
                    .foregroundStyle(self.color ?? self.theme.colors.textPrimary)
            }

            Text(self.formattedValue)
                .font(self.font)
                .foregroundStyle(self.color ?? self.theme.colors.textPrimary)
                .contentTransition(.numericText(value: self.displayValue))
                .monospacedDigit()

            if let suffix {
                Text(suffix)
                    .font(self.font)
                    .foregroundStyle(self.color ?? self.theme.colors.textSecondary)
            }
        }
        .onChange(of: self.value) { _, newValue in
            withAnimation(self.animationStyle.animation) {
                self.displayValue = newValue
            }
        }
        .onAppear {
            guard !self.hasAppeared else {
                return
            }
            self.hasAppeared = true

            // Animate from 0 to value on first appear
            withAnimation(self.animationStyle.animation.delay(0.1)) {
                self.displayValue = self.value
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var displayValue: Double = 0
    @State private var previousValue: Double = 0
    @State private var hasAppeared = false

    private let value: Double
    private let format: NumberFormat
    private let animationStyle: NumberAnimationStyle
    private let font: Font
    private let color: Color?
    private let prefix: String?
    private let suffix: String?
    private let decimalPlaces: Int
    private let showSign: Bool

    // MARK: - Formatted Value

    private var formattedValue: String {
        var result = ""

        // Add sign if needed
        if self.showSign && self.displayValue > 0 {
            result += "+"
        }

        // Format the number
        switch self.format {
        case .raw:
            if self.decimalPlaces == 0 {
                result += String(Int(self.displayValue))
            } else {
                result += String(format: "%.\(self.decimalPlaces)f", self.displayValue)
            }

        case .decimal:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = self.decimalPlaces
            formatter.minimumFractionDigits = self.decimalPlaces
            result += formatter.string(from: NSNumber(value: self.displayValue)) ?? "\(self.displayValue)"

        case .compact:
            result += self.compactFormat(self.displayValue)

        case .percentage:
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = self.decimalPlaces
            formatter.multiplier = 1
            result += formatter.string(from: NSNumber(value: self.displayValue)) ?? "\(self.displayValue)%"

        case let .currency(symbol):
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            result += symbol + (formatter.string(from: NSNumber(value: self.displayValue)) ?? "\(self.displayValue)")

        case let .custom(format):
            result += String(format: format, self.displayValue)
        }

        return result
    }

    private func compactFormat(_ number: Double) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""

        switch absNumber {
        case 0..<1000:
            if self.decimalPlaces == 0 {
                return sign + String(Int(absNumber))
            }
            return sign + String(format: "%.\(self.decimalPlaces)f", absNumber)

        case 1000..<1_000_000:
            let value = absNumber / 1000
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return sign + String(Int(value)) + "k"
            }
            return sign + String(format: "%.1f", value) + "k"

        case 1_000_000..<1_000_000_000:
            let value = absNumber / 1_000_000
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return sign + String(Int(value)) + "M"
            }
            return sign + String(format: "%.1f", value) + "M"

        default:
            let value = absNumber / 1_000_000_000
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return sign + String(Int(value)) + "B"
            }
            return sign + String(format: "%.1f", value) + "B"
        }
    }
}

// MARK: - Convenience Initializers

extension AnimatedNumber {
    /// Create an animated calories display
    public static func calories(
        _ value: Double,
        target: Double? = nil,
        style: NumberAnimationStyle = .counting
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .decimal,
            animationStyle: style,
            suffix: target != nil ? " / \(Int(target!)) kcal" : " kcal"
        )
    }

    /// Create an animated steps display
    public static func steps(
        _ value: Double,
        style: NumberAnimationStyle = .counting
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .decimal,
            animationStyle: style,
            suffix: " steps"
        )
    }

    /// Create an animated percentage display
    public static func percentage(
        _ value: Double,
        style: NumberAnimationStyle = .spring
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .percentage,
            animationStyle: style
        )
    }

    /// Create an animated weight display
    public static func weight(
        _ value: Double,
        unit: String = "kg",
        style: NumberAnimationStyle = .eased
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .decimal,
            animationStyle: style,
            suffix: " \(unit)",
            decimalPlaces: 1
        )
    }

    /// Create an animated duration display (minutes)
    public static func duration(
        minutes: Double,
        style: NumberAnimationStyle = .counting
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: minutes,
            format: .raw,
            animationStyle: style,
            suffix: " min"
        )
    }

    /// Create an animated compact number (1.2k, 1.5M)
    public static func compact(
        _ value: Double,
        style: NumberAnimationStyle = .spring
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .compact,
            animationStyle: style
        )
    }

    /// Create an animated change indicator with +/- sign
    public static func change(
        _ value: Double,
        suffix: String? = nil,
        style: NumberAnimationStyle = .spring
    ) -> some View {
        AnimatedNumber(
            value: value,
            format: .decimal,
            animationStyle: style,
            color: value > 0 ? ColorPalette.Semantic.success : (value < 0 ? ColorPalette.Semantic.error : nil),
            suffix: suffix,
            decimalPlaces: 1,
            showSign: true
        )
    }
}

// MARK: - Preview

#Preview("AnimatedNumber") {
    struct PreviewContent: View {
        @State private var calories: Double = 0
        @State private var steps: Double = 0
        @State private var percentage: Double = 0
        @State private var change: Double = 0

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Text("AnimatedNumber")
                        .font(.title2.bold())

                    // Calories
                    VStack(spacing: 8) {
                        Text("Calories").font(.headline)
                        AnimatedNumber.calories(self.calories, target: 2000)
                            .font(.title.bold())
                    }

                    // Steps
                    VStack(spacing: 8) {
                        Text("Steps").font(.headline)
                        AnimatedNumber.steps(self.steps)
                            .font(.title.bold())
                    }

                    // Percentage
                    VStack(spacing: 8) {
                        Text("Progress").font(.headline)
                        AnimatedNumber.percentage(self.percentage)
                            .font(.title.bold())
                    }

                    // Compact
                    VStack(spacing: 8) {
                        Text("Compact").font(.headline)
                        HStack(spacing: 16) {
                            AnimatedNumber.compact(1234)
                            AnimatedNumber.compact(12345)
                            AnimatedNumber.compact(1_234_567)
                        }
                    }

                    // Change indicator
                    VStack(spacing: 8) {
                        Text("Change").font(.headline)
                        AnimatedNumber.change(self.change, suffix: " kg")
                            .font(.title3.bold())
                    }

                    Button("Animate") {
                        self.calories = Double.random(in: 500...2500)
                        self.steps = Double.random(in: 1000...15000)
                        self.percentage = Double.random(in: 0...100)
                        self.change = Double.random(in: -5...5)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .environment(\.theme, DefaultTheme())
        }
    }

    return PreviewContent()
}
