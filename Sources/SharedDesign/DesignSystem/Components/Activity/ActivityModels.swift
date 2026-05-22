import SwiftUI

// MARK: - HeartRateZone

/// Heart rate training zones for visualization on route maps
public enum HeartRateZone: Int, Codable, Sendable, CaseIterable {
    case zone1 = 1 // Recovery: <120 BPM
    case zone2 = 2 // Aerobic Base: 120-140 BPM
    case zone3 = 3 // Aerobic: 140-160 BPM
    case zone4 = 4 // Lactate Threshold: 160-175 BPM
    case zone5 = 5 // VO2 Max: 175+ BPM

    // MARK: Public

    /// Color for this heart rate zone
    public var color: Color {
        ColorPalette.IntensityZones.color(for: self.rawValue)
    }

    /// Display name for this zone
    public var displayName: String {
        ColorPalette.IntensityZones.name(for: self.rawValue)
    }

    /// Short label for compact displays
    public var shortLabel: String {
        "Z\(self.rawValue)"
    }

    /// BPM range description using fixed thresholds (for display when maxHR unavailable)
    public var bpmRange: String {
        switch self {
        case .zone1: "<120"
        case .zone2: "120-140"
        case .zone3: "140-160"
        case .zone4: "160-175"
        case .zone5: "175+"
        }
    }

    /// BPM range description personalized to a max heart rate
    public func bpmRange(maxHR: Double) -> String {
        guard maxHR > 0 else { return self.bpmRange }
        let thresholds = [0.60, 0.70, 0.80, 0.90].map { Int($0 * maxHR) }
        switch self {
        case .zone1: return "<\(thresholds[0])"
        case .zone2: return "\(thresholds[0])-\(thresholds[1])"
        case .zone3: return "\(thresholds[1])-\(thresholds[2])"
        case .zone4: return "\(thresholds[2])-\(thresholds[3])"
        case .zone5: return "\(thresholds[3])+"
        }
    }

    /// Classify a heart rate value into a zone
    /// When maxHR is provided, uses percentage-based zones (recommended for personalization):
    /// Zone 1: <60%, Zone 2: 60-70%, Zone 3: 70-80%, Zone 4: 80-90%, Zone 5: >90%
    /// When maxHR is nil, falls back to standard fixed thresholds.
    public static func from(bpm: Double, maxHR: Double? = nil) -> HeartRateZone {
        if let maxHR, maxHR > 0 {
            let fraction = bpm / maxHR
            switch fraction {
            case ..<0.60: return .zone1
            case 0.60..<0.70: return .zone2
            case 0.70..<0.80: return .zone3
            case 0.80..<0.90: return .zone4
            default: return .zone5
            }
        }
        // Fallback: fixed thresholds
        switch bpm {
        case ..<120: return .zone1
        case 120..<140: return .zone2
        case 140..<160: return .zone3
        case 160..<175: return .zone4
        default: return .zone5
        }
    }
}

// MARK: - RouteOverlayMode

/// Metric used to color the route polyline
public enum RouteOverlayMode: String, CaseIterable, Sendable {
    case pace
    case heartRate
    case elevation

    // MARK: Public

    public var displayName: String {
        switch self {
        case .pace: "Pace"
        case .heartRate: "Heart Rate"
        case .elevation: "Elevation"
        }
    }

    public var icon: String {
        switch self {
        case .pace: "gauge.high"
        case .heartRate: "heart.fill"
        case .elevation: "mountain.2.fill"
        }
    }
}

// MARK: - PaceCategory

/// Classification of running/activity pace for visualization
public enum PaceCategory: String, Codable, Sendable {
    case fast
    case good
    case moderate
    case easy

    // MARK: Public

    /// Color representation for pace zone visualization
    public var color: Color {
        switch self {
        case .fast:
            ColorPalette.IntensityZones.zone4
        case .good:
            ColorPalette.IntensityZones.zone3
        case .moderate:
            ColorPalette.IntensityZones.zone2
        case .easy:
            ColorPalette.IntensityZones.zone1
        }
    }

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .fast:
            "Fast"
        case .good:
            "Good"
        case .moderate:
            "Moderate"
        case .easy:
            "Easy"
        }
    }

    /// Pace thresholds in seconds per kilometer
    public static func from(paceSecondsPerKm pace: Double) -> PaceCategory {
        switch pace {
        case ..<300:
            .fast
        case 300..<360:
            .good
        case 360..<420:
            .moderate
        default:
            .easy
        }
    }
}
