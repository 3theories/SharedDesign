import SwiftUI

// MARK: - PulsingIndicator

/// A live activity indicator with pulsing animation.
/// Used to indicate active/live states in activity tracking.
///
/// Design principles:
/// - Clear status indication
/// - Subtle, non-distracting animation
/// - Color-coded for different states
/// - Small footprint
public struct PulsingIndicator: View {
    // MARK: Lifecycle

    /// Creates a pulsing indicator
    /// - Parameters:
    ///   - status: The current status
    ///   - size: The indicator size
    ///   - showLabel: Whether to show a text label
    public init(
        status: IndicatorStatus = .live,
        size: IndicatorSize = .medium,
        showLabel: Bool = false
    ) {
        self.status = status
        self.size = size
        self.showLabel = showLabel
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.labelSpacing) {
            // Pulsing dot
            ZStack {
                // Outer pulse ring (animated)
                if self.status.shouldPulse {
                    Circle()
                        .fill(self.status.color.opacity(0.4))
                        .frame(width: self.dotSize * 2, height: self.dotSize * 2)
                        .scaleEffect(self.isPulsing ? 1.0 : 0.5)
                        .opacity(self.isPulsing ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: self.isPulsing
                        )
                }

                // Core dot with shadow glow
                Circle()
                    .fill(self.status.color)
                    .frame(width: self.dotSize, height: self.dotSize)
                    .shadow(color: self.status.color.opacity(0.5), radius: self.dotSize / 2)
            }
            .frame(width: self.dotSize * 2.5, height: self.dotSize * 2.5)

            // Optional label
            if self.showLabel {
                Text(self.status.label)
                    .font(.system(size: self.labelFontSize, weight: .semibold))
                    .foregroundStyle(self.status.color)
            }
        }
        .onAppear {
            if self.status.shouldPulse {
                self.isPulsing = true
            }
        }
        .onChange(of: self.status) { _, newStatus in
            self.isPulsing = newStatus.shouldPulse
        }
    }

    // MARK: Internal

    let status: IndicatorStatus
    let size: IndicatorSize
    let showLabel: Bool

    // MARK: Private

    @State private var isPulsing = false

    // MARK: - Private Properties

    private var dotSize: CGFloat {
        switch self.size {
        case .small:
            6
        case .medium:
            8
        case .large:
            10
        }
    }

    private var labelFontSize: CGFloat {
        switch self.size {
        case .small:
            10
        case .medium:
            12
        case .large:
            14
        }
    }

    private var labelSpacing: CGFloat {
        switch self.size {
        case .small:
            4
        case .medium:
            6
        case .large:
            8
        }
    }
}

// MARK: PulsingIndicator.IndicatorStatus

extension PulsingIndicator {
    /// Status variants for the pulsing indicator
    public enum IndicatorStatus: Equatable {
        case live
        case paused
        case recording
        case syncing
        case offline
        case completed

        // MARK: Internal

        var color: Color {
            switch self {
            case .live:
                .green
            case .paused:
                .orange
            case .recording:
                .red
            case .syncing:
                .blue
            case .offline:
                .gray
            case .completed:
                .green
            }
        }

        var label: String {
            switch self {
            case .live:
                "LIVE"
            case .paused:
                "PAUSED"
            case .recording:
                "REC"
            case .syncing:
                "SYNCING"
            case .offline:
                "OFFLINE"
            case .completed:
                "DONE"
            }
        }

        var shouldPulse: Bool {
            switch self {
            case .live, .recording, .syncing:
                true
            case .paused, .offline, .completed:
                false
            }
        }
    }
}

// MARK: PulsingIndicator.IndicatorSize

extension PulsingIndicator {
    /// Size variants for the pulsing indicator
    public enum IndicatorSize {
        case small
        case medium
        case large
    }
}

// MARK: - LiveBadge

/// A pill-shaped live badge with pulsing indicator
public struct LiveBadge: View {
    // MARK: Lifecycle

    /// Creates a live badge
    /// - Parameters:
    ///   - status: The current status
    ///   - style: The badge visual style
    public init(
        status: PulsingIndicator.IndicatorStatus = .live,
        style: BadgeStyle = .filled
    ) {
        self.status = status
        self.style = style
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: 6) {
            PulsingIndicator(status: self.status, size: .small)

            Text(self.status.label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(self.backgroundStyle)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.status.label)
    }

    // MARK: Internal

    let status: PulsingIndicator.IndicatorStatus
    let style: BadgeStyle

    // MARK: Private

    @Environment(\.theme) private var theme

    @ViewBuilder
    private var backgroundStyle: some View {
        switch self.style {
        case .filled:
            self.status.color.opacity(0.15)
        case .outlined:
            Capsule()
                .strokeBorder(self.status.color.opacity(0.5), lineWidth: 1)
        case .surface:
            self.theme.colors.surface2
        }
    }
}

// MARK: LiveBadge.BadgeStyle

extension LiveBadge {
    /// Visual styles for the live badge
    public enum BadgeStyle {
        case filled
        case outlined
        case surface
    }
}

// MARK: - ActivityStatusRow

/// A row displaying activity status with time
public struct ActivityStatusRow: View {
    // MARK: Lifecycle

    /// Creates an activity status row
    /// - Parameters:
    ///   - activityName: Name of the activity
    ///   - status: Current status
    ///   - elapsedTime: Optional elapsed time
    public init(
        activityName: String,
        status: PulsingIndicator.IndicatorStatus,
        elapsedTime: TimeInterval? = nil
    ) {
        self.activityName = activityName
        self.status = status
        self.elapsedTime = elapsedTime
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.md) {
            PulsingIndicator(status: self.status, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.activityName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(self.theme.colors.textPrimary)

                HStack(spacing: 4) {
                    Text(self.status.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(self.status.color)

                    if let time = self.elapsedTime {
                        Text(verbatim: "•")
                            .foregroundStyle(self.theme.colors.textSecondary)
                        Text(self.formatTime(time))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(self.theme.colors.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(self.activityName), \(self.status.label)\(self.elapsedTime != nil ? ", \(self.formatTime(self.elapsedTime!))" : "")"
        )
    }

    // MARK: Internal

    let activityName: String
    let status: PulsingIndicator.IndicatorStatus
    let elapsedTime: TimeInterval?

    // MARK: Private

    @Environment(\.theme) private var theme

    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Pulsing Indicators") {
    VStack(spacing: 32) {
        // Status variants
        HStack(spacing: 24) {
            PulsingIndicator(status: .live, showLabel: true)
            PulsingIndicator(status: .paused, showLabel: true)
            PulsingIndicator(status: .recording, showLabel: true)
        }

        HStack(spacing: 24) {
            PulsingIndicator(status: .syncing, showLabel: true)
            PulsingIndicator(status: .offline, showLabel: true)
            PulsingIndicator(status: .completed, showLabel: true)
        }

        Divider()

        // Live badges
        HStack(spacing: 16) {
            LiveBadge(status: .live, style: .filled)
            LiveBadge(status: .recording, style: .outlined)
            LiveBadge(status: .paused, style: .surface)
        }

        Divider()

        // Status row
        ActivityStatusRow(
            activityName: "Tennis Match",
            status: .live,
            elapsedTime: 2785
        )
        .padding()
        #if os(watchOS)
            .background(Color.black)
        #else
            .background(Color(.systemBackground))
        #endif
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
