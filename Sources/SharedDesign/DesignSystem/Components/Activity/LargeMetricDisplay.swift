import SwiftUI

// MARK: - LargeMetricDisplay

/// A large, glanceable metric display optimized for during-activity use.
/// Uses 48-72pt rounded bold numbers with smooth numeric transitions.
///
/// Design principles:
/// - Large numbers for at-a-glance reading (48-72pt)
/// - Rounded design font for activity context
/// - Numeric content transitions for smooth updates
/// - Monospaced digits for stable layout
public struct LargeMetricDisplay: View {
    // MARK: Lifecycle

    /// Creates a large metric display
    /// - Parameters:
    ///   - value: The primary value to display (e.g., "145", "30:45")
    ///   - label: Optional ALL CAPS label above the value (e.g., "BPM", "TIME")
    ///   - unit: Optional unit after the value (e.g., "cal", "mi")
    ///   - size: The display size (.primary for 72pt, .secondary for 48pt, .tertiary for 32pt)
    ///   - accentColor: Optional color for the value (uses theme primary if nil)
    public init(
        value: String,
        label: String? = nil,
        unit: String? = nil,
        size: MetricSize = .primary,
        accentColor: Color? = nil
    ) {
        self.value = value
        self.label = label
        self.unit = unit
        self.size = size
        self.accentColor = accentColor
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: self.labelSpacing) {
            // Label (optional)
            if let label = self.label {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }

            // Value with optional unit
            HStack(alignment: .lastTextBaseline, spacing: self.unitSpacing) {
                Text(self.value)
                    .font(.system(size: self.fontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(self.valueColor)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: self.value)

                if let unit = self.unit {
                    Text(unit)
                        .font(.system(size: self.unitFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(self.theme.colors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([self.label, self.value, self.unit].compactMap { $0 }.joined(separator: " "))
    }

    // MARK: Internal

    let value: String
    let label: String?
    let unit: String?
    let size: MetricSize
    let accentColor: Color?

    // MARK: Private

    @Environment(\.theme) private var theme

    // MARK: - Private Properties

    private var fontSize: CGFloat {
        switch self.size {
        case .hero:
            72
        case .primary:
            48
        case .secondary:
            32
        case .tertiary:
            24
        }
    }

    private var unitFontSize: CGFloat {
        switch self.size {
        case .hero:
            24
        case .primary:
            18
        case .secondary:
            14
        case .tertiary:
            12
        }
    }

    private var labelSpacing: CGFloat {
        switch self.size {
        case .hero:
            8
        case .primary:
            6
        case .secondary:
            4
        case .tertiary:
            2
        }
    }

    private var unitSpacing: CGFloat {
        switch self.size {
        case .hero:
            8
        case .primary:
            6
        case .secondary:
            4
        case .tertiary:
            2
        }
    }

    private var valueColor: Color {
        self.accentColor ?? self.theme.colors.textPrimary
    }
}

// MARK: LargeMetricDisplay.MetricSize

extension LargeMetricDisplay {
    /// Size variants for metric displays
    public enum MetricSize {
        /// 72pt - Primary timer, hero metric
        case hero
        /// 48pt - Primary scores, main metrics
        case primary
        /// 32pt - Secondary metrics
        case secondary
        /// 24pt - Tertiary metrics
        case tertiary
    }
}

// MARK: - LargeTimeDisplay

/// Specialized time display that formats TimeInterval into readable time
public struct LargeTimeDisplay: View {
    // MARK: Lifecycle

    /// Creates a large time display
    /// - Parameters:
    ///   - elapsedTime: The time interval to display
    ///   - size: The display size
    ///   - label: Optional label above the time
    ///   - showHours: Whether to always show hours (auto-shows if > 1 hour)
    public init(
        elapsedTime: TimeInterval,
        size: LargeMetricDisplay.MetricSize = .hero,
        label: String? = nil,
        showHours: Bool = false
    ) {
        self.elapsedTime = elapsedTime
        self.size = size
        self.label = label
        self.showHours = showHours
    }

    // MARK: Public

    public var body: some View {
        LargeMetricDisplay(
            value: self.formattedTime,
            label: self.label,
            size: self.size
        )
    }

    // MARK: Internal

    let elapsedTime: TimeInterval
    let size: LargeMetricDisplay.MetricSize
    let label: String?
    let showHours: Bool

    // MARK: Private

    @Environment(\.theme) private var theme

    private var formattedTime: String {
        let totalSeconds = Int(self.elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 || self.showHours {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - LargeScoreDisplay

/// Specialized score display for sports scoreboards
public struct LargeScoreDisplay: View {
    // MARK: Lifecycle

    /// Creates a score display with user vs opponent
    /// - Parameters:
    ///   - userScore: The user's score
    ///   - opponentScore: The opponent's score
    ///   - userLabel: Label for user (default: "YOU")
    ///   - opponentLabel: Label for opponent (default: "OPP")
    ///   - size: The display size
    public init(
        userScore: String,
        opponentScore: String,
        userLabel: String = "YOU",
        opponentLabel: String = "OPP",
        size: LargeMetricDisplay.MetricSize = .primary
    ) {
        self.userScore = userScore
        self.opponentScore = opponentScore
        self.userLabel = userLabel
        self.opponentLabel = opponentLabel
        self.size = size
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.dividerSpacing) {
            // User score
            LargeMetricDisplay(
                value: self.userScore,
                label: self.userLabel,
                size: self.size,
                accentColor: self.theme.colors.primary
            )

            // Divider
            Text(verbatim: "-")
                .font(.system(size: self.dividerFontSize, weight: .medium))
                .foregroundStyle(self.theme.colors.textSecondary.opacity(0.5))

            // Opponent score
            LargeMetricDisplay(
                value: self.opponentScore,
                label: self.opponentLabel,
                size: self.size
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.userLabel) \(self.userScore), \(self.opponentLabel) \(self.opponentScore)")
    }

    // MARK: Internal

    let userScore: String
    let opponentScore: String
    let userLabel: String
    let opponentLabel: String
    let size: LargeMetricDisplay.MetricSize

    // MARK: Private

    @Environment(\.theme) private var theme

    private var dividerSpacing: CGFloat {
        switch self.size {
        case .hero:
            32
        case .primary:
            24
        case .secondary:
            16
        case .tertiary:
            12
        }
    }

    private var dividerFontSize: CGFloat {
        switch self.size {
        case .hero:
            48
        case .primary:
            32
        case .secondary:
            24
        case .tertiary:
            18
        }
    }
}

// MARK: - Preview

#Preview("Large Metric Display") {
    VStack(spacing: 40) {
        LargeMetricDisplay(
            value: "145",
            label: "BPM",
            size: .primary,
            accentColor: .red
        )

        LargeTimeDisplay(
            elapsedTime: 2785,
            size: .hero,
            label: "ELAPSED"
        )

        LargeMetricDisplay(
            value: "324",
            label: "CALORIES",
            unit: "cal",
            size: .secondary
        )

        LargeScoreDisplay(
            userScore: "3",
            opponentScore: "2",
            size: .primary
        )
    }
    .padding()
    .background(Color.black)
}
