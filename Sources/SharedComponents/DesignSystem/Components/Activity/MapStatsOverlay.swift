import SwiftUI

// MARK: - MapStatsOverlay

/// Floating stats panel for map overlay using SubtleSurfaceCard
/// Displays heart rate and pace with intensity-based colors
public struct MapStatsOverlay: View {
    // MARK: Lifecycle

    /// Creates a map stats overlay
    /// - Parameters:
    ///   - heartRate: Current heart rate in BPM (optional)
    ///   - currentPace: Current pace in seconds per km (optional)
    public init(heartRate: Int? = nil, currentPace: TimeInterval? = nil) {
        self.heartRate = heartRate
        self.currentPace = currentPace
    }

    // MARK: Public

    public var body: some View {
        SubtleSurfaceCard(elevation: .floating, cornerRadius: 24) {
            HStack(spacing: self.theme.spacing.lg) {
                if let hr = self.heartRate {
                    LargeMetricDisplay(
                        value: "\(hr)",
                        label: String(
                            localized: "map.stats.bpm.label",
                            defaultValue: "BPM",
                            bundle: .module,
                            comment: "Map stats overlay heart rate label"
                        ),
                        size: .tertiary,
                        accentColor: self.heartRateColor(hr)
                    )
                }

                if let pace = self.currentPace {
                    LargeMetricDisplay(
                        value: self.formatPace(pace),
                        label: String(
                            localized: "map.stats.pace.label",
                            defaultValue: "PACE",
                            bundle: .module,
                            comment: "Map stats overlay pace label"
                        ),
                        unit: String(
                            localized: "map.stats.pace.unit",
                            defaultValue: "/km",
                            bundle: .module,
                            comment: "Map stats overlay pace unit per kilometer"
                        ),
                        size: .tertiary,
                        accentColor: self.paceColor(pace)
                    )
                }
            }
            .padding(.horizontal, self.theme.spacing.lg)
            .padding(.vertical, self.theme.spacing.md)
        }
    }

    // MARK: Internal

    let heartRate: Int?
    let currentPace: TimeInterval?

    // MARK: Private

    @Environment(\.theme) private var theme

    // MARK: - Private Methods

    private func heartRateColor(_ hr: Int) -> Color {
        switch hr {
        case ..<120:
            ColorPalette.IntensityZones.zone1
        case 120..<140:
            ColorPalette.IntensityZones.zone2
        case 140..<160:
            ColorPalette.IntensityZones.zone3
        case 160..<175:
            ColorPalette.IntensityZones.zone4
        default:
            ColorPalette.IntensityZones.zone5
        }
    }

    private func paceColor(_ pace: TimeInterval) -> Color {
        let minutesPerKm = pace / 60
        switch minutesPerKm {
        case ..<5:
            return ColorPalette.IntensityZones.zone5
        case 5..<6:
            return ColorPalette.IntensityZones.zone4
        case 6..<7:
            return ColorPalette.IntensityZones.zone3
        case 7..<8:
            return ColorPalette.IntensityZones.zone2
        default:
            return ColorPalette.IntensityZones.zone1
        }
    }

    private func formatPace(_ secondsPerKm: TimeInterval) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - MapBottomStatsBar

/// Bottom bar with key metrics for outdoor activity map
public struct MapBottomStatsBar: View {
    // MARK: Lifecycle

    /// Creates a bottom stats bar
    /// - Parameters:
    ///   - duration: Elapsed time in seconds
    ///   - distance: Total distance in meters
    ///   - elevation: Total elevation gain in meters
    ///   - elevationProfile: Array of altitude samples for sparkline
    public init(
        duration: TimeInterval,
        distance: Double,
        elevation: Double,
        elevationProfile: [Double] = []
    ) {
        self.duration = duration
        self.distance = distance
        self.elevation = elevation
        self.elevationProfile = elevationProfile
    }

    // MARK: Public

    public var body: some View {
        SubtleSurfaceCard(elevation: .high, cornerRadius: 0) {
            VStack(spacing: self.theme.spacing.md) {
                HStack {
                    LargeTimeDisplay(
                        elapsedTime: self.duration,
                        size: .secondary,
                        label: String(
                            localized: "map.stats.duration.label",
                            defaultValue: "DURATION",
                            bundle: .module,
                            comment: "Map bottom stats bar duration label"
                        )
                    )

                    Spacer()

                    LargeMetricDisplay(
                        value: self.formatDistance(self.distance),
                        label: String(
                            localized: "map.stats.distance.label",
                            defaultValue: "DISTANCE",
                            bundle: .module,
                            comment: "Map bottom stats bar distance label"
                        ),
                        unit: String(
                            localized: "map.stats.distance.unit",
                            defaultValue: "km",
                            bundle: .module,
                            comment: "Map bottom stats bar distance unit kilometers"
                        ),
                        size: .secondary,
                        accentColor: ColorPalette.Fitness.distance
                    )

                    Spacer()

                    LargeMetricDisplay(
                        value: "\(Int(self.elevation))",
                        label: String(
                            localized: "map.stats.elevation.label",
                            defaultValue: "ELEVATION",
                            bundle: .module,
                            comment: "Map bottom stats bar elevation label"
                        ),
                        unit: String(
                            localized: "map.stats.elevation.unit",
                            defaultValue: "m ↑",
                            bundle: .module,
                            comment: "Map bottom stats bar elevation unit meters with up arrow"
                        ),
                        size: .secondary,
                        accentColor: ColorPalette.Fitness.steps
                    )
                }

                if !self.elevationProfile.isEmpty {
                    ElevationSparkline(data: self.elevationProfile)
                        .frame(height: 32)
                }
            }
            .padding(.horizontal, self.theme.spacing.xl)
            .padding(.vertical, self.theme.spacing.lg)
        }
    }

    // MARK: Internal

    let duration: TimeInterval
    let distance: Double
    let elevation: Double
    let elevationProfile: [Double]

    // MARK: Private

    /// Locale-aware number formatter for distance values (2 fraction digits).
    private static let distanceNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    @Environment(\.theme) private var theme

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return Self.distanceNumberFormatter.string(from: NSNumber(value: km)) ?? "\(km)"
    }
}

// MARK: - Preview

#Preview("Map Stats Overlay") {
    VStack(spacing: 24) {
        MapStatsOverlay(heartRate: 156, currentPace: 342)

        MapStatsOverlay(heartRate: 142, currentPace: 420)

        MapStatsOverlay(heartRate: 175, currentPace: 280)
    }
    .padding()
    .background(Color.black)
}

#Preview("Map Bottom Stats Bar") {
    VStack {
        Spacer()
        MapBottomStatsBar(
            duration: 2785,
            distance: 5240,
            elevation: 156,
            elevationProfile: [100, 120, 115, 140, 160, 155, 180, 170, 190, 185]
        )
    }
    .background(Color.gray.opacity(0.3))
}
