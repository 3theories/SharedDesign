import SwiftUI

// MARK: - RouteHistoryCard

/// Card displaying a route summary with optional thumbnail
/// Used in activity history lists
public struct RouteHistoryCard: View {
    // MARK: Lifecycle

    /// Creates a route history card
    /// - Parameters:
    ///   - activityType: Display name of the activity type
    ///   - distance: Total distance in meters
    ///   - duration: Total duration in seconds
    ///   - elevationGain: Total elevation gain in meters
    ///   - date: Completion date
    ///   - thumbnail: Optional snapshot image
    ///   - polyline: Optional encoded polyline for mini-map
    ///   - onTap: Action when card is tapped
    public init(
        activityType: String,
        distance: Double,
        duration: TimeInterval,
        elevationGain: Double,
        date: Date? = nil,
        thumbnail: Image? = nil,
        polyline: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.activityType = activityType
        self.distance = distance
        self.duration = duration
        self.elevationGain = elevationGain
        self.date = date
        self.thumbnail = thumbnail
        self.polyline = polyline
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: self.theme.spacing.md) {
                // Thumbnail or placeholder
                self.thumbnailView
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Stats
                VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
                    // Title and date
                    HStack {
                        Text(self.activityType)
                            .font(self.theme.typography.headline)
                            .foregroundStyle(self.theme.colors.textPrimary)

                        Spacer()

                        if let date = self.date {
                            Text(date, style: .date)
                                .font(self.theme.typography.caption1)
                                .foregroundStyle(self.theme.colors.textTertiary)
                        }
                    }

                    // Stats row
                    HStack(spacing: self.theme.spacing.lg) {
                        self.statItem(
                            value: self.formatDistance(self.distance),
                            unit: "km",
                            color: ColorPalette.Fitness.distance
                        )

                        self.statItem(
                            value: self.formatDuration(self.duration),
                            unit: "",
                            color: self.theme.colors.textSecondary
                        )

                        self.statItem(
                            value: "\(Int(self.elevationGain))",
                            unit: "m ↑",
                            color: ColorPalette.Fitness.steps
                        )
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(self.theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.theme.colors.surface1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(self.activityType), \(self.date != nil ? self.date!.formatted(date: .abbreviated, time: .omitted) : ""), \(self.formatDistance(self.distance)) kilometers, \(self.formatDuration(self.duration)), \(Int(self.elevationGain)) meters elevation gain"
            )
            .accessibilityHint("Double tap to open route details")
        }
        .buttonStyle(.plain)
    }

    // MARK: Internal

    let activityType: String
    let distance: Double
    let duration: TimeInterval
    let elevationGain: Double
    let date: Date?
    let thumbnail: Image?
    let polyline: String?
    let onTap: () -> Void

    // MARK: Private

    // MARK: - Formatting

    /// Locale-aware number formatter for distance values (2 fraction digits).
    private static let distanceNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    @Environment(\.theme) private var theme

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = self.thumbnail {
            thumbnail
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if self.polyline != nil {
            // Mini polyline preview
            MiniRoutePreview(polyline: self.polyline)
        } else {
            // Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(self.theme.colors.surface2)

                Image(systemName: "map")
                    .font(.system(size: 20))
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(value: String, unit: String, color: Color) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(color)

            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.colors.textSecondary)
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return Self.distanceNumberFormatter.string(from: NSNumber(value: km)) ?? "\(km)"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - MiniRoutePreview

/// Small polyline preview for route cards
public struct MiniRoutePreview: View {
    // MARK: Lifecycle

    public init(polyline: String?) {
        self.polyline = polyline
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(self.theme.colors.surface2)

                if let polyline = self.polyline, !polyline.isEmpty {
                    self.polylinePath(in: geometry.size)
                } else {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 16))
                        .foregroundStyle(self.theme.colors.textTertiary)
                }
            }
        }
    }

    // MARK: Internal

    let polyline: String?

    // MARK: Private

    @Environment(\.theme) private var theme

    @ViewBuilder
    private func polylinePath(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            guard let polyline = self.polyline else {
                return
            }

            // Decode polyline (simplified decoding for preview)
            let points = self.decodePolyline(polyline)
            guard points.count > 1 else {
                return
            }

            // Find bounds
            var minLat = points[0].0
            var maxLat = points[0].0
            var minLon = points[0].1
            var maxLon = points[0].1

            for point in points {
                minLat = min(minLat, point.0)
                maxLat = max(maxLat, point.0)
                minLon = min(minLon, point.1)
                maxLon = max(maxLon, point.1)
            }

            let latRange = maxLat - minLat
            let lonRange = maxLon - minLon

            guard latRange > 0, lonRange > 0 else {
                return
            }

            // Map to canvas with padding
            let padding: CGFloat = 8
            let drawWidth = canvasSize.width - padding * 2
            let drawHeight = canvasSize.height - padding * 2

            var path = Path()
            for (index, point) in points.enumerated() {
                let x = padding + ((point.1 - minLon) / lonRange) * drawWidth
                let y = padding + drawHeight - ((point.0 - minLat) / latRange) * drawHeight

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(
                path,
                with: .color(ColorPalette.Fitness.distance),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func decodePolyline(_ encoded: String) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        var index = encoded.startIndex
        var lat = 0
        var lon = 0

        while index < encoded.endIndex {
            var shift = 0
            var result = 0

            repeat {
                let char = encoded[index]
                index = encoded.index(after: index)
                let byte = Int(char.asciiValue ?? 0) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20 {
                    break
                }
            } while index < encoded.endIndex

            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lat += deltaLat

            shift = 0
            result = 0

            guard index < encoded.endIndex else {
                break
            }

            repeat {
                let char = encoded[index]
                index = encoded.index(after: index)
                let byte = Int(char.asciiValue ?? 0) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20 {
                    break
                }
            } while index < encoded.endIndex

            let deltaLon = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lon += deltaLon

            points.append((Double(lat) / 1e5, Double(lon) / 1e5))
        }

        return points
    }
}

// MARK: - Preview

#Preview("Route History Card") {
    VStack(spacing: 16) {
        RouteHistoryCard(
            activityType: "Outdoor Run",
            distance: 5240,
            duration: 1845,
            elevationGain: 156,
            date: Date(),
            thumbnail: nil,
            polyline: nil
        ) { }

        RouteHistoryCard(
            activityType: "Hike",
            distance: 12500,
            duration: 7200,
            elevationGain: 520,
            date: Date().addingTimeInterval(-86400),
            thumbnail: nil,
            polyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
        ) { }
    }
    .padding()
    .background(Color.black)
}
