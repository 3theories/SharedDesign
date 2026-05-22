import SwiftUI

// MARK: - CurrentLocationMarker

/// Pulsing marker for showing user's current position on map
/// Uses PulsingIndicator pattern with Fitness.distance color
public struct CurrentLocationMarker: View {
    // MARK: Lifecycle

    /// Creates a current location marker
    /// - Parameter heading: Direction of travel in degrees from north (optional)
    public init(heading: Double? = nil) {
        self.heading = heading
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .fill(self.markerColor.opacity(0.4))
                .frame(width: 40, height: 40)
                .scaleEffect(self.isPulsing ? 1.5 : 0.5)
                .opacity(self.isPulsing ? 0 : 1)
                .animation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: self.isPulsing
                )

            // Middle glow
            Circle()
                .fill(self.markerColor)
                .frame(width: 16, height: 16)
                .shadow(color: self.markerColor.opacity(0.5), radius: 8)

            // White border for visibility
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 16, height: 16)

            // Direction indicator
            if let heading = self.heading {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(self.markerColor)
                    .rotationEffect(.degrees(heading))
                    .offset(y: -20)
            }
        }
        .frame(width: 50, height: 50)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(
            localized: "map.marker.current",
            defaultValue: "Current Location",
            bundle: .module,
            comment: "Map marker for current location"
        ))
        .onAppear {
            self.isPulsing = true
        }
    }

    // MARK: Internal

    let heading: Double?

    // MARK: Private

    @State private var isPulsing = false

    private let markerColor = ColorPalette.Fitness.distance
}

// MARK: - StartLocationMarker

/// Marker for route start point
public struct StartLocationMarker: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        ZStack {
            Circle()
                .fill(ColorPalette.Semantic.success)
                .frame(width: 24, height: 24)

            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 24, height: 24)

            Image("flag")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 10, height: 10)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(
            localized: "map.marker.start",
            defaultValue: "Start Location",
            bundle: .module,
            comment: "Map marker for start location"
        ))
    }
}

// MARK: - EndLocationMarker

/// Marker for route end/finish point
public struct EndLocationMarker: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        ZStack {
            Circle()
                .fill(ColorPalette.Fitness.heartRate)
                .frame(width: 24, height: 24)

            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 24, height: 24)

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(
            localized: "map.marker.end",
            defaultValue: "End Location",
            bundle: .module,
            comment: "Map marker for end location"
        ))
    }
}

// MARK: - Preview

#Preview("Location Markers") {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            VStack {
                CurrentLocationMarker()
                Text("Current")
                    .font(.caption)
            }

            VStack {
                CurrentLocationMarker(heading: 45)
                Text("With Heading")
                    .font(.caption)
            }
        }

        HStack(spacing: 40) {
            VStack {
                StartLocationMarker()
                Text("Start")
                    .font(.caption)
            }

            VStack {
                EndLocationMarker()
                Text("End")
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
