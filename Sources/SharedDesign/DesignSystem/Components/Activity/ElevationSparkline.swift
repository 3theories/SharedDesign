import SwiftUI

// MARK: - Elevation Sparkline

/// Mini elevation profile chart using IntensityZones colors
/// Displays altitude changes along a route with gradient fill
public struct ElevationSparkline: View {
    // MARK: Lifecycle

    /// Creates an elevation sparkline
    /// - Parameters:
    ///   - data: Array of altitude values in meters
    ///   - showLabels: Whether to show min/max labels (default: false)
    public init(data: [Double], showLabels: Bool = false) {
        self.data = data
        self.showLabels = showLabels
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            let minVal = self.data.min() ?? 0
            let maxVal = self.data.max() ?? 1
            let range = max(maxVal - minVal, 1)

            ZStack {
                // Fill underneath
                Path { path in
                    guard self.data.count > 1 else {
                        return
                    }

                    let stepX = geometry.size.width / CGFloat(self.data.count - 1)

                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    path.addLine(to: CGPoint(
                        x: 0,
                        y: geometry.size.height * (1 - (self.data[0] - minVal) / range)
                    ))

                    for (index, value) in self.data.enumerated().dropFirst() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height * (1 - (value - minVal) / range)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            ColorPalette.IntensityZones.zone2.opacity(0.3),
                            ColorPalette.IntensityZones.zone1.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Stroke line
                Path { path in
                    guard self.data.count > 1 else {
                        return
                    }

                    let stepX = geometry.size.width / CGFloat(self.data.count - 1)

                    path.move(to: CGPoint(
                        x: 0,
                        y: geometry.size.height * (1 - (self.data[0] - minVal) / range)
                    ))

                    for (index, value) in self.data.enumerated().dropFirst() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height * (1 - (value - minVal) / range)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            ColorPalette.IntensityZones.zone1,
                            ColorPalette.IntensityZones.zone2,
                            ColorPalette.IntensityZones.zone3
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // Min/Max labels
                if self.showLabels, !self.data.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Text(L10n.format("fitness.elevation_sparkline.max_label_format", Int(maxVal)))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(self.theme.colors.textSecondary)
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Text(String(
                                format: L10n.string("fitness.elevation_sparkline.min_label_format"),
                                Int(minVal)
                            ))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(self.theme.colors.textSecondary)
                        }
                    }
                }
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: Internal

    let data: [Double]
    let showLabels: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#Preview("Elevation Sparkline") {
    VStack(spacing: 24) {
        ElevationSparkline(data: [100, 120, 115, 140, 160, 155, 180, 170, 190, 185])
            .frame(height: 40)

        ElevationSparkline(data: [100, 120, 115, 140, 160, 155, 180, 170, 190, 185], showLabels: true)
            .frame(height: 60)

        ElevationSparkline(data: [50, 55, 60, 58, 62, 65, 63, 68, 70, 72, 75, 73, 78, 80])
            .frame(height: 32)
    }
    .padding()
    .background(Color.black)
}
