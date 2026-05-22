import Charts
import SwiftUI

// MARK: - Shared Formatters

/// Locale-aware elevation formatter (meters, 0 fraction digits).
/// Shared across `ElevationProfileChart` and `SplitTimeRow`.
private let sharedElevationFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 0
    return formatter
}()

// MARK: - SplitData

/// Data for a single split (km or mile)
public struct SplitData: Identifiable {
    // MARK: Lifecycle

    public init(
        id: Int,
        distance: Double,
        duration: TimeInterval,
        pace: TimeInterval,
        elevationChange: Double,
        paceCategory: PaceCategory,
        gradeAdjustedPace: TimeInterval? = nil,
        effortScore: Double? = nil
    ) {
        self.id = id
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.elevationChange = elevationChange
        self.paceCategory = paceCategory
        self.gradeAdjustedPace = gradeAdjustedPace
        self.effortScore = effortScore
    }

    // MARK: Public

    public let id: Int // Split number (1-based)
    public let distance: Double // Distance of this split in meters
    public let duration: TimeInterval // Duration in seconds
    public let pace: TimeInterval // Seconds per km/mile
    public let elevationChange: Double // Net elevation change in meters
    public let paceCategory: PaceCategory
    public let gradeAdjustedPace: TimeInterval? // GAP in seconds per km
    public let effortScore: Double? // 0-100 composite effort score
}

// MARK: - ElevationPoint

/// A single point on the elevation profile
public struct ElevationPoint: Identifiable {
    // MARK: Lifecycle

    public init(id: UUID = UUID(), distance: Double, altitude: Double) {
        self.id = id
        self.distance = distance
        self.altitude = altitude
    }

    // MARK: Public

    public let id: UUID
    public let distance: Double // Cumulative distance in meters
    public let altitude: Double // Altitude in meters
}

// MARK: - DistanceUnit

/// User's preferred distance unit
public enum DistanceUnit: String, CaseIterable {
    case kilometers
    case miles

    // MARK: Public

    /// Returns the preferred distance unit based on user's locale
    public static var preferredForLocale: DistanceUnit {
        let locale = Locale.current
        let imperialRegions: Set<String> = ["US", "GB", "MM", "LR"]

        if let regionCode = locale.region?.identifier,
           imperialRegions.contains(regionCode) {
            return .miles
        }
        return .kilometers
    }

    public var splitDistance: Double {
        switch self {
        case .kilometers: 1000
        case .miles: 1609.34
        }
    }

    public var abbreviation: String {
        switch self {
        case .kilometers: "km"
        case .miles: "mi"
        }
    }
}

// MARK: - PaceZoneLegend

/// Legend showing all pace zone colors with labels
public struct PaceZoneLegend: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            ForEach([PaceCategory.fast, .good, .moderate, .easy], id: \.self) { category in
                HStack(spacing: 4) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 6, height: 6)

                    Text(category.displayName)
                        .font(self.theme.typography.caption2)
                        .foregroundStyle(self.theme.colors.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - PaceZoneBar

/// Horizontal bar showing time spent in a pace zone with premium gradient fill
public struct PaceZoneBar: View {
    // MARK: Lifecycle

    public init(
        category: PaceCategory,
        duration: TimeInterval,
        percentage: Double,
        maxPercentage: Double,
        isPremiumStyle: Bool = false
    ) {
        self.category = category
        self.duration = duration
        self.percentage = percentage
        self.maxPercentage = maxPercentage
        self.isPremiumStyle = isPremiumStyle
    }

    // MARK: Public

    public let category: PaceCategory
    public let duration: TimeInterval
    public let percentage: Double
    public let maxPercentage: Double
    public let isPremiumStyle: Bool

    public var body: some View {
        HStack(spacing: self.theme.spacing.sm) {
            // Zone indicator
            HStack(spacing: self.theme.spacing.xs) {
                Circle()
                    .fill(self.category.color)
                    .frame(width: 10, height: 10)

                Text(self.category.displayName)
                    .font(self.theme.typography.caption1.weight(.medium))
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .frame(width: 60, alignment: .leading)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: self.isPremiumStyle ? 6 : 4)
                        .fill(self.theme.colors.surface3)

                    // Filled portion with gradient for premium style
                    if self.isPremiumStyle {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        self.category.color,
                                        self.category.color.opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (self.percentage / self.maxPercentage))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(self.category.color)
                            .frame(width: geometry.size.width * (self.percentage / self.maxPercentage))
                    }
                }
            }
            .frame(height: self.isPremiumStyle ? 16 : 12)

            // Duration and percentage
            VStack(alignment: .trailing, spacing: 0) {
                Text(self.formatDuration(self.duration))
                    .font(self.theme.typography.caption1.weight(.semibold).monospacedDigit())
                    .foregroundStyle(self.theme.colors.textPrimary)

                Text(
                    Self.percentFormatter
                        .string(from: NSNumber(value: self.percentage / 100)) ?? "\(Int(self.percentage))%"
                )
                .font(self.theme.typography.caption2.monospacedDigit())
                .foregroundStyle(self.theme.colors.textSecondary)
            }
            .frame(width: 50, alignment: .trailing)
        }
    }

    // MARK: Private

    /// Locale-aware percentage formatter (0 fraction digits, produces "42%").
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    @Environment(\.theme) private var theme

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - ElevationProfileChart

/// Chart showing elevation over distance with optional premium styling and crosshair
public struct ElevationProfileChart: View {
    // MARK: Lifecycle

    public init(
        elevationProfile: [ElevationPoint],
        distanceUnit: DistanceUnit,
        isPremiumStyle: Bool = false,
        selectedDistance: Binding<Double?> = .constant(nil)
    ) {
        self.elevationProfile = elevationProfile
        self.distanceUnit = distanceUnit
        self.isPremiumStyle = isPremiumStyle
        self._selectedDistance = selectedDistance
    }

    // MARK: Public

    @Binding public var selectedDistance: Double?

    public let elevationProfile: [ElevationPoint]
    public let distanceUnit: DistanceUnit
    public let isPremiumStyle: Bool

    public var body: some View {
        if self.elevationProfile.isEmpty {
            self.emptyState
        } else {
            self.chartContent
                .chartXAxisLabel {
                    Text(String(
                        localized: "chart.axis.distance.label",
                        defaultValue: "Distance (\(self.distanceUnit.abbreviation))",
                        bundle: .module,
                        comment: "Chart X axis label for distance with unit abbreviation"
                    ))
                    .font(self.theme.typography.caption2)
                    .foregroundStyle(self.theme.colors.textTertiary)
                }
                .chartYAxisLabel {
                    Text(String(
                        localized: "chart.axis.elevation",
                        defaultValue: "Elevation (m)",
                        bundle: .module,
                        comment: "Chart Y axis label for elevation in meters"
                    ))
                    .font(self.theme.typography.caption2)
                    .foregroundStyle(self.theme.colors.textTertiary)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(self.theme.colors.textTertiary.opacity(0.3))
                        AxisTick()
                            .foregroundStyle(self.theme.colors.textTertiary.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(self.theme.colors.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(self.theme.colors.textTertiary.opacity(0.3))
                        AxisTick()
                            .foregroundStyle(self.theme.colors.textTertiary.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(self.theme.colors.textTertiary)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let plotFrame = geo[proxy.plotFrame!]
                                        let x = value.location.x - plotFrame.origin.x
                                        let clampedX = max(0, min(x, plotFrame.width))
                                        if let dist: Double = proxy.value(atX: clampedX) {
                                            let meters = self.convertToMeters(dist)
                                            let minDist = self.elevationProfile.first?.distance ?? 0
                                            let maxDist = self.elevationProfile.last?.distance ?? 0
                                            self.selectedDistance = max(minDist, min(meters, maxDist))
                                        }
                                    }
                                    .onEnded { _ in
                                        self.selectedDistance = nil
                                    }
                            )
                    }
                }
                .frame(height: self.isPremiumStyle ? 200 : 180)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private var premiumGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: ColorPalette.IntensityZones.zone2.opacity(0.5), location: 0),
                .init(color: ColorPalette.IntensityZones.zone2.opacity(0.15), location: 0.5),
                .init(color: ColorPalette.IntensityZones.zone2.opacity(0.05), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var standardGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.IntensityZones.zone2.opacity(0.4),
                ColorPalette.IntensityZones.zone1.opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var chartContent: some View {
        let gradient = self.isPremiumStyle ? self.premiumGradient : self.standardGradient
        let lineWidth = self.isPremiumStyle ? 2.5 : 2.0

        return Chart {
            ForEach(self.elevationProfile) { point in
                AreaMark(
                    x: .value("Distance", self.convertDistance(point.distance)),
                    y: .value("Elevation", point.altitude)
                )
                .foregroundStyle(gradient)

                LineMark(
                    x: .value("Distance", self.convertDistance(point.distance)),
                    y: .value("Elevation", point.altitude)
                )
                .foregroundStyle(ColorPalette.IntensityZones.zone2)
                .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }

            if let selected = self.selectedDistance {
                RuleMark(x: .value("Selected", self.convertDistance(selected)))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        self.crosshairLabel(for: selected)
                    }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: self.theme.spacing.sm) {
            Image(systemName: "mountain.2")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(self.theme.colors.textTertiary)
                .accessibilityHidden(true)

            Text(String(
                localized: "elevation.unavailable.title",
                defaultValue: "Elevation Unavailable",
                bundle: .module,
                comment: "Elevation profile empty state title"
            ))
            .font(self.theme.typography.subheadline.weight(.medium))
            .foregroundStyle(self.theme.colors.textSecondary)

            Text(String(
                localized: "elevation.unavailable.description",
                defaultValue: "Altitude data wasn't recorded for this activity",
                bundle: .module,
                comment: "Elevation profile empty state description"
            ))
            .font(self.theme.typography.caption1)
            .foregroundStyle(self.theme.colors.textTertiary)
            .multilineTextAlignment(.center)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func crosshairLabel(for distance: Double) -> some View {
        if let alt = self.altitudeAt(distance: distance) {
            Text(sharedElevationFormatter.string(from: Measurement(value: alt, unit: UnitLength.meters)))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(self.theme.colors.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func altitudeAt(distance: Double) -> Double? {
        guard !self.elevationProfile.isEmpty else {
            return nil
        }
        // Find nearest elevation point
        return self.elevationProfile
            .min(by: { abs($0.distance - distance) < abs($1.distance - distance) })?
            .altitude
    }

    private func convertToMeters(_ displayDistance: Double) -> Double {
        switch self.distanceUnit {
        case .kilometers: displayDistance * 1000
        case .miles: displayDistance * 1609.34
        }
    }

    private func convertDistance(_ meters: Double) -> Double {
        switch self.distanceUnit {
        case .kilometers: meters / 1000
        case .miles: meters / 1609.34
        }
    }
}

// MARK: - SplitTimeRow

/// Single row in the split times table with premium circular pace indicator option
public struct SplitTimeRow: View {
    // MARK: Lifecycle

    public init(
        split: SplitData,
        distanceUnit: DistanceUnit,
        formatPace: @escaping (TimeInterval) -> String,
        isPremiumStyle: Bool = false
    ) {
        self.split = split
        self.distanceUnit = distanceUnit
        self.formatPace = formatPace
        self.isPremiumStyle = isPremiumStyle
    }

    // MARK: Public

    public let split: SplitData
    public let distanceUnit: DistanceUnit
    public let formatPace: (TimeInterval) -> String
    public let isPremiumStyle: Bool

    public var body: some View {
        HStack(spacing: self.theme.spacing.md) {
            // Split number with pace color indicator
            if self.isPremiumStyle {
                // Premium: Circular gradient indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    self.split.paceCategory.color.opacity(0.3),
                                    self.split.paceCategory.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Text(verbatim: "\(self.split.id)")
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(self.split.paceCategory.color)
                }
            } else {
                // Standard: Small circle with number
                HStack(spacing: self.theme.spacing.xs) {
                    Circle()
                        .fill(self.split.paceCategory.color)
                        .frame(width: 8, height: 8)

                    Text(verbatim: "\(self.split.id)")
                        .font(self.theme.typography.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(self.theme.colors.textPrimary)
                        .frame(width: 24, alignment: .trailing)
                }
            }

            // Pace
            Text(self.formatPace(self.split.pace))
                .font(self.theme.typography.body.monospacedDigit())
                .foregroundStyle(self.theme.colors.textPrimary)
                .frame(width: 50, alignment: .trailing)

            Text(verbatim: "/\(self.distanceUnit.abbreviation)")
                .font(self.theme.typography.caption1)
                .foregroundStyle(self.theme.colors.textSecondary)

            Spacer()

            // GAP (Grade Adjusted Pace)
            if let gap = self.split.gradeAdjustedPace {
                Text(self.formatPace(gap))
                    .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .frame(width: 40, alignment: .trailing)
            }

            // Effort score bar
            if let effort = self.split.effortScore {
                EffortScoreBar(score: effort)
                    .frame(width: 36)
            }

            // Elevation change
            HStack(spacing: 2) {
                AppIconView(
                    name: self.split.elevationChange >= 0 ? "arrowupright" : "arrowdownright",
                    isSystemIcon: false
                )
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
                .foregroundStyle(
                    self.split.elevationChange >= 0
                        ? self.theme.colors.success
                        : self.theme.colors.error
                )

                Text(sharedElevationFormatter.string(from: Measurement(
                    value: abs(self.split.elevationChange),
                    unit: UnitLength.meters
                )))
                .font(self.theme.typography.caption1.monospacedDigit())
                .foregroundStyle(self.theme.colors.textSecondary)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, self.theme.spacing.xs)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - EffortScoreBar

/// Compact colored bar representing effort intensity 0-100
public struct EffortScoreBar: View {
    // MARK: Lifecycle

    public init(score: Double) {
        self.score = score
    }

    // MARK: Public

    public let score: Double

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))

                RoundedRectangle(cornerRadius: 2)
                    .fill(self.effortColor)
                    .frame(width: geo.size.width * min(self.score / 100, 1))
            }
        }
        .frame(height: 6)
    }

    // MARK: Private

    private var effortColor: Color {
        switch self.score {
        case ..<30: ColorPalette.IntensityZones.zone1
        case 30..<50: ColorPalette.IntensityZones.zone2
        case 50..<70: ColorPalette.IntensityZones.zone3
        case 70..<85: ColorPalette.IntensityZones.zone4
        default: ColorPalette.IntensityZones.zone5
        }
    }
}

// MARK: - RouteStartMarker

/// Premium start marker for route maps
public struct RouteStartMarker: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.3),
                            Color.green.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)

            Circle()
                .strokeBorder(Color.green, lineWidth: 2)
                .background(Circle().fill(Color.green.opacity(0.2)))
                .frame(width: 16, height: 16)

            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - RouteEndMarker

/// Premium end marker for route maps
public struct RouteEndMarker: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.3),
                            Color.red.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)

            Circle()
                .strokeBorder(Color.red, lineWidth: 2)
                .background(Circle().fill(Color.red.opacity(0.2)))
                .frame(width: 16, height: 16)

            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Previews

#Preview("Pace Zone Bar - Standard") {
    VStack(spacing: 16) {
        PaceZoneBar(
            category: .fast,
            duration: 300,
            percentage: 15,
            maxPercentage: 45,
            isPremiumStyle: false
        )
        PaceZoneBar(
            category: .good,
            duration: 600,
            percentage: 30,
            maxPercentage: 45,
            isPremiumStyle: false
        )
    }
    .padding()
}

#Preview("Pace Zone Bar - Premium") {
    VStack(spacing: 16) {
        PaceZoneBar(
            category: .fast,
            duration: 300,
            percentage: 15,
            maxPercentage: 45,
            isPremiumStyle: true
        )
        PaceZoneBar(
            category: .good,
            duration: 600,
            percentage: 30,
            maxPercentage: 45,
            isPremiumStyle: true
        )
    }
    .padding()
}

#Preview("Split Time Row - Standard") {
    SplitTimeRow(
        split: SplitData(
            id: 1,
            distance: 1000,
            duration: 330,
            pace: 330,
            elevationChange: 12,
            paceCategory: .good
        ),
        distanceUnit: .kilometers,
        formatPace: { pace in
            let min = Int(pace) / 60
            let sec = Int(pace) % 60
            return String(format: "%d:%02d", min, sec)
        },
        isPremiumStyle: false
    )
    .padding()
}

#Preview("Split Time Row - Premium") {
    SplitTimeRow(
        split: SplitData(
            id: 1,
            distance: 1000,
            duration: 330,
            pace: 330,
            elevationChange: 12,
            paceCategory: .good
        ),
        distanceUnit: .kilometers,
        formatPace: { pace in
            let min = Int(pace) / 60
            let sec = Int(pace) % 60
            return String(format: "%d:%02d", min, sec)
        },
        isPremiumStyle: true
    )
    .padding()
}

#Preview("Split Time Row - GAP & Effort") {
    SplitTimeRow(
        split: SplitData(
            id: 3,
            distance: 1000,
            duration: 360,
            pace: 360,
            elevationChange: -18,
            paceCategory: .moderate,
            gradeAdjustedPace: 340,
            effortScore: 72
        ),
        distanceUnit: .kilometers,
        formatPace: { pace in
            let min = Int(pace) / 60
            let sec = Int(pace) % 60
            return String(format: "%d:%02d", min, sec)
        },
        isPremiumStyle: true
    )
    .padding()
}

#Preview("Effort Score Bar") {
    VStack(spacing: 12) {
        LabeledContent("Low (20)") {
            EffortScoreBar(score: 20)
                .frame(width: 60)
        }
        LabeledContent("Medium (55)") {
            EffortScoreBar(score: 55)
                .frame(width: 60)
        }
        LabeledContent("High (75)") {
            EffortScoreBar(score: 75)
                .frame(width: 60)
        }
        LabeledContent("Max (95)") {
            EffortScoreBar(score: 95)
                .frame(width: 60)
        }
    }
    .padding()
}

#Preview("Elevation Profile Chart") {
    ElevationProfileChart(
        elevationProfile: [
            ElevationPoint(distance: 0, altitude: 42),
            ElevationPoint(distance: 500, altitude: 48),
            ElevationPoint(distance: 1000, altitude: 65),
            ElevationPoint(distance: 1500, altitude: 80),
            ElevationPoint(distance: 2000, altitude: 72),
            ElevationPoint(distance: 2500, altitude: 55),
            ElevationPoint(distance: 3000, altitude: 60),
            ElevationPoint(distance: 3500, altitude: 78),
            ElevationPoint(distance: 4000, altitude: 90),
            ElevationPoint(distance: 4500, altitude: 85),
            ElevationPoint(distance: 5000, altitude: 68),
            ElevationPoint(distance: 5200, altitude: 45)
        ],
        distanceUnit: .kilometers,
        isPremiumStyle: true
    )
    .padding()
}

#Preview("Elevation Profile Chart - Interactive") {
    @Previewable @State var selectedDistance: Double?
    ElevationProfileChart(
        elevationProfile: [
            ElevationPoint(distance: 0, altitude: 42),
            ElevationPoint(distance: 500, altitude: 48),
            ElevationPoint(distance: 1000, altitude: 65),
            ElevationPoint(distance: 1500, altitude: 80),
            ElevationPoint(distance: 2000, altitude: 72),
            ElevationPoint(distance: 2500, altitude: 55),
            ElevationPoint(distance: 3000, altitude: 60),
            ElevationPoint(distance: 3500, altitude: 78),
            ElevationPoint(distance: 4000, altitude: 90),
            ElevationPoint(distance: 4500, altitude: 85),
            ElevationPoint(distance: 5000, altitude: 68),
            ElevationPoint(distance: 5200, altitude: 45)
        ],
        distanceUnit: .kilometers,
        isPremiumStyle: true,
        selectedDistance: $selectedDistance
    )
    .padding()
}

#Preview("Pace Zone Legend") {
    PaceZoneLegend()
        .padding()
}

#Preview("Route Markers") {
    HStack(spacing: 40) {
        RouteStartMarker()
        RouteEndMarker()
    }
    .padding()
    .background(Color.black)
}
