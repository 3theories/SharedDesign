import SwiftUI

// MARK: - HeartRateZoneRow

/// Refined heart rate zone row with clean visual hierarchy.
/// Shows zone info on top row, progress bar below with time displayed inside optimally.
public struct HeartRateZoneRow: View {
    // MARK: Lifecycle

    public init(
        zoneNumber: Int,
        zoneName: String,
        bpmRange: String,
        timeText: String,
        progress: Double,
        zoneColor: Color
    ) {
        self.zoneNumber = zoneNumber
        self.zoneName = zoneName
        self.bpmRange = bpmRange
        self.timeText = timeText
        self.progress = max(0, min(progress, 1))
        self.zoneColor = zoneColor
    }

    /// Convenience initializer using zone number to auto-select color
    public init(
        zoneNumber: Int,
        bpmRange: String,
        timeText: String,
        progress: Double
    ) {
        self.zoneNumber = zoneNumber
        self.zoneName = Self.defaultZoneName(for: zoneNumber)
        self.bpmRange = bpmRange
        self.timeText = timeText
        self.progress = max(0, min(progress, 1))
        self.zoneColor = Self.defaultColor(for: zoneNumber)
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Zone badge + Zone name on left, BPM range on right
            HStack(alignment: .center, spacing: 0) {
                // Left: Zone badge + Zone name
                HStack(spacing: 10) {
                    // Zone number badge with subtle background
                    ZStack {
                        Circle()
                            .fill(self.zoneColor.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Text(verbatim: "\(self.zoneNumber)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(self.zoneColor.opacity(0.9))
                    }

                    Text(self.zoneName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(self.theme.colors.textPrimary.opacity(0.9))
                }

                Spacer()

                // Right: BPM range
                Text(self.bpmRange)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(self.theme.colors.textSecondary)
            }

            // Progress bar with time text inside
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let rawFillWidth = totalWidth * self.progress
                let fillWidth = self.progress > 0 ? max(rawFillWidth, 8) : 0
                let unfilledWidth = totalWidth - fillWidth
                let textFitsInUnfilled = unfilledWidth >= (Self.textWidth + Self.textPadding * 2)

                ZStack(alignment: .leading) {
                    // Track - subtle
                    RoundedRectangle(cornerRadius: Self.barHeight / 2, style: .continuous)
                        .fill(self.zoneColor.opacity(0.2))
                        .frame(height: Self.barHeight)

                    // Fill with gradient
                    if fillWidth > 0 {
                        RoundedRectangle(cornerRadius: Self.barHeight / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        self.zoneColor,
                                        self.zoneColor.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(fillWidth, totalWidth), height: Self.barHeight)
                    }

                    // Time text - position based on available space
                    if textFitsInUnfilled {
                        // Text in unfilled area, colored to match zone
                        Text(self.timeText)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(self.zoneColor)
                            .position(x: fillWidth + Self.textPadding + Self.textWidth / 2, y: Self.barHeight / 2)
                    } else {
                        // Text at trailing edge of fill, white
                        HStack {
                            Spacer(minLength: 0)
                            Text(self.timeText)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.trailing, Self.textPadding)
                        }
                        .frame(height: Self.barHeight)
                    }
                }
            }
            .frame(height: Self.barHeight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.zoneName), \(self.bpmRange), \(self.timeText)")
    }

    // MARK: Internal

    let zoneNumber: Int
    let zoneName: String
    let bpmRange: String
    let timeText: String
    let progress: Double
    let zoneColor: Color

    // MARK: Private

    private static let barHeight: CGFloat = 32
    private static let textWidth: CGFloat = 50
    private static let textPadding: CGFloat = 10

    @Environment(\.theme) private var theme

    // MARK: - Default Values

    private static func defaultZoneName(for zone: Int) -> String {
        switch zone {
        case 1: String(
                localized: "heartRate.zone.recovery",
                defaultValue: "Recovery",
                bundle: .module,
                comment: "Heart rate zone 1 name"
            )
        case 2: String(
                localized: "heartRate.zone.light",
                defaultValue: "Light",
                bundle: .module,
                comment: "Heart rate zone 2 name"
            )
        case 3: String(
                localized: "heartRate.zone.moderate",
                defaultValue: "Moderate",
                bundle: .module,
                comment: "Heart rate zone 3 name"
            )
        case 4: String(
                localized: "heartRate.zone.hard",
                defaultValue: "Hard",
                bundle: .module,
                comment: "Heart rate zone 4 name"
            )
        case 5: String(
                localized: "heartRate.zone.maximum",
                defaultValue: "Maximum",
                bundle: .module,
                comment: "Heart rate zone 5 name"
            )
        default: String(
                localized: "heartRate.zone.default",
                defaultValue: "Zone \(zone)",
                bundle: .module,
                comment: "Default heart rate zone name with number"
            )
        }
    }

    private static func defaultColor(for zone: Int) -> Color {
        switch zone {
        case 1: Color(red: 0.4, green: 0.65, blue: 0.95) // Blue
        case 2: Color(red: 0.35, green: 0.75, blue: 0.7) // Teal
        case 3: Color(red: 0.4, green: 0.72, blue: 0.45) // Green
        case 4: Color(red: 0.85, green: 0.65, blue: 0.3) // Orange
        case 5: Color(red: 0.85, green: 0.35, blue: 0.35) // Red
        default: .gray
        }
    }
}

// MARK: - HeartRateZonesCard

/// A container view that displays multiple heart rate zones with refined styling
public struct HeartRateZonesCard: View {
    // MARK: Lifecycle

    public init(
        zones: [ZoneData],
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.zones = zones
        self.title = title ?? String(
            localized: "heartRate.zones.title",
            defaultValue: "Heart Rate Zones",
            bundle: .module,
            comment: "Heart rate zones card title"
        )
        self.subtitle = subtitle
    }

    // MARK: Public

    public struct ZoneData: Identifiable {
        // MARK: Lifecycle

        public init(zoneNumber: Int, bpmRange: String, minutes: Int, seconds: Int = 0, totalMinutes: Int) {
            self.id = zoneNumber
            self.bpmRange = bpmRange
            self.minutes = minutes
            self.seconds = seconds
            self.totalMinutes = totalMinutes
        }

        // MARK: Public

        public let id: Int
        public let bpmRange: String
        public let minutes: Int
        public let seconds: Int
        public let totalMinutes: Int

        // MARK: Internal

        var timeText: String {
            String(format: "%d:%02d", self.minutes, self.seconds)
        }

        var progress: Double {
            guard self.totalMinutes > 0 else {
                return 0
            }
            let totalSeconds = Double(self.minutes * 60 + self.seconds)
            let maxSeconds = Double(self.totalMinutes * 60)
            return totalSeconds / maxSeconds
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(self.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(self.theme.colors.textPrimary)

            // Zone rows
            VStack(spacing: 16) {
                ForEach(self.zones.sorted { $0.id < $1.id }) { zone in
                    HeartRateZoneRow(
                        zoneNumber: zone.id,
                        bpmRange: zone.bpmRange,
                        timeText: zone.timeText,
                        progress: zone.progress
                    )
                }
            }

            // Footer
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(self.theme.colors.textTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(self.theme.colors.surface1)
        )
    }

    // MARK: Internal

    let zones: [ZoneData]
    let title: String
    let subtitle: String?

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Previews

#Preview("HeartRateZoneRow - Refined") {
    VStack(spacing: 20) {
        Text("Heart Rate Zones")
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 16) {
            HeartRateZoneRow(
                zoneNumber: 1,
                bpmRange: "<134 bpm",
                timeText: "32:56",
                progress: 0.78
            )

            HeartRateZoneRow(
                zoneNumber: 2,
                bpmRange: "134-147 bpm",
                timeText: "9:03",
                progress: 0.21
            )

            HeartRateZoneRow(
                zoneNumber: 3,
                bpmRange: "147-159 bpm",
                timeText: "0:46",
                progress: 0.02
            )

            HeartRateZoneRow(
                zoneNumber: 4,
                bpmRange: "159-171 bpm",
                timeText: "0:00",
                progress: 0.0
            )

            HeartRateZoneRow(
                zoneNumber: 5,
                bpmRange: "171+ bpm",
                timeText: "0:00",
                progress: 0.0
            )
        }
    }
    .padding(16)
    .background(Color(white: 0.12))
    .environment(\.theme, DefaultTheme())
}

#Preview("HeartRateZonesCard - Refined") {
    HeartRateZonesCard(
        zones: [
            .init(zoneNumber: 1, bpmRange: "<134 bpm", minutes: 32, seconds: 56, totalMinutes: 42),
            .init(zoneNumber: 2, bpmRange: "134-147 bpm", minutes: 9, seconds: 3, totalMinutes: 42),
            .init(zoneNumber: 3, bpmRange: "147-159 bpm", minutes: 0, seconds: 46, totalMinutes: 42),
            .init(zoneNumber: 4, bpmRange: "159-171 bpm", minutes: 0, seconds: 0, totalMinutes: 42),
            .init(zoneNumber: 5, bpmRange: "171+ bpm", minutes: 0, seconds: 0, totalMinutes: 42)
        ]
    )
    .padding()
    .background(Color(white: 0.1))
    .environment(\.theme, DefaultTheme())
}
