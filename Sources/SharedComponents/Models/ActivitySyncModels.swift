import Foundation

// MARK: - ScheduledActivitySyncData

/// Scheduled activity summary sent from iPhone to Watch for display
/// Used to show upcoming activities on Watch before they're started
public struct ScheduledActivitySyncData: Codable, Sendable, Identifiable {
    // MARK: Lifecycle

    public init(
        id: UUID,
        activityType: ActivityCategory,
        sportType: String?,
        activityName: String,
        scheduledDate: Date,
        scheduledTime: Date? = nil,
        estimatedDuration: Int? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.sportType = sportType
        self.activityName = activityName
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.estimatedDuration = estimatedDuration
    }

    // MARK: Public

    public let id: UUID
    public let activityType: ActivityCategory
    public let sportType: String?
    public let activityName: String
    public let scheduledDate: Date
    public let scheduledTime: Date?
    public let estimatedDuration: Int? // minutes

    /// Display icon based on activity type and sport type
    public var icon: String {
        switch self.activityType {
        case .workout:
            return "dumbell"
        case .sport:
            // Map sport type to icon
            guard let sport = self.sportType?.lowercased() else {
                return "trophy.fill"
            }
            switch sport {
            case "tennis": return "tennis.racket"
            case "cricket": return "cricketball.fill"
            case "soccer": return "soccerball"
            case "basketball": return "basketball.fill"
            case "badminton": return "figure.badminton"
            case "golf": return "figure.golf"
            default: return "sportscourt.fill"
            }
        case .freeform:
            // Map activity name to icon
            let name = self.activityName.lowercased()
            if name.contains("run") { return "figure.run" }
            if name.contains("walk") { return "figure.walk" }
            if name.contains("yoga") { return "figure.yoga" }
            if name.contains("swim") { return "figure.pool.swim" }
            if name.contains("cycl") || name.contains("bike") { return "figure.outdoor.cycle" }
            if name.contains("hiit") { return "flame.fill" }
            return "figure.mixed.cardio"
        case .run:
            return "figure.run"
        case .hike:
            return "figure.hiking"
        case .cycle:
            return "figure.outdoor.cycle"
        case .yoga:
            return "figure.yoga"
        case .swim:
            return "figure.pool.swim"
        case .indoor:
            return "figure.indoor.cycle"
        case .rest:
            return "moon.zzz"
        }
    }

    /// Whether the icon is an SF Symbol (true) or a custom asset icon (false)
    public var isSystemIcon: Bool {
        switch self.activityType {
        case .workout:
            false
        case .sport, .freeform, .run, .hike, .cycle, .yoga, .swim, .indoor, .rest:
            true
        }
    }
}

// MARK: - QuickActionSync

/// Sync model for sport/activity quick actions
public struct QuickActionSync: Codable, Sendable, Identifiable, Equatable {
    // MARK: Lifecycle

    public init(
        shortLabel: String,
        icon: String,
        eventType: String,
        points: Int,
        forScorer: String = "user"
    ) {
        self.shortLabel = shortLabel
        self.icon = icon
        self.eventType = eventType
        self.points = points
        self.forScorer = forScorer
    }

    // MARK: Public

    public let shortLabel: String
    public let icon: String
    public let eventType: String
    public let points: Int
    public let forScorer: String // "user", "opponent", or "both"

    public var id: String { self.eventType }
}

// MARK: - ActivityNavigationEvent

/// Navigation events sent from Watch to iPhone
public enum ActivityNavigationEvent: Codable, Sendable {
    case paused(timestamp: Date)
    case resumed(timestamp: Date)
    case completed(timestamp: Date)
    case abandoned(timestamp: Date, reason: String?)
    case scoreEvent(eventType: String, scorer: String, points: Int, timestamp: Date)
    case lapRecorded(timestamp: Date)
    case setRecorded(reps: Int?, timestamp: Date)
    case periodEnded(timestamp: Date)
    case sideSwitch(timestamp: Date)

    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)

        switch type {
        case "paused":
            self = .paused(timestamp: timestamp)
        case "resumed":
            self = .resumed(timestamp: timestamp)
        case "completed":
            self = .completed(timestamp: timestamp)
        case "abandoned":
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            self = .abandoned(timestamp: timestamp, reason: reason)
        case "scoreEvent":
            let eventType = try container.decode(String.self, forKey: .eventType)
            let scorer = try container.decode(String.self, forKey: .scorer)
            let points = try container.decode(Int.self, forKey: .points)
            self = .scoreEvent(eventType: eventType, scorer: scorer, points: points, timestamp: timestamp)
        case "lapRecorded":
            self = .lapRecorded(timestamp: timestamp)
        case "setRecorded":
            let reps = try container.decodeIfPresent(Int.self, forKey: .reps)
            self = .setRecorded(reps: reps, timestamp: timestamp)
        case "periodEnded":
            self = .periodEnded(timestamp: timestamp)
        case "sideSwitch":
            self = .sideSwitch(timestamp: timestamp)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown type: \(type)"
            )
        }
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .paused(timestamp):
            try container.encode("paused", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)

        case let .resumed(timestamp):
            try container.encode("resumed", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)

        case let .completed(timestamp):
            try container.encode("completed", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)

        case let .abandoned(timestamp, reason):
            try container.encode("abandoned", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(reason, forKey: .reason)

        case let .scoreEvent(eventType, scorer, points, timestamp):
            try container.encode("scoreEvent", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encode(eventType, forKey: .eventType)
            try container.encode(scorer, forKey: .scorer)
            try container.encode(points, forKey: .points)

        case let .lapRecorded(timestamp):
            try container.encode("lapRecorded", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)

        case let .setRecorded(reps, timestamp):
            try container.encode("setRecorded", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(reps, forKey: .reps)

        case let .periodEnded(timestamp):
            try container.encode("periodEnded", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)

        case let .sideSwitch(timestamp):
            try container.encode("sideSwitch", forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
        }
    }

    // MARK: Private

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case timestamp
        case eventType
        case scorer
        case points
        case reason
        case reps
    }
}

// MARK: - ActivityMetricsData

/// Metrics update sent from Watch to iPhone
public struct ActivityMetricsData: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        heartRate: Double? = nil,
        activeCalories: Double? = nil,
        distanceCovered: Double? = nil,
        cadence: Double? = nil,
        strideLength: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.heartRate = heartRate
        self.activeCalories = activeCalories
        self.distanceCovered = distanceCovered
        self.cadence = cadence
        self.strideLength = strideLength
        self.timestamp = timestamp
    }

    // MARK: Public

    public let heartRate: Double?
    public let activeCalories: Double?
    public let distanceCovered: Double?
    public let cadence: Double? // steps per minute
    public let strideLength: Double? // meters
    public let timestamp: Date
}

// MARK: - WatchActivitySyncState

/// Sync state for Watch to determine which view to show
/// Similar to WatchSyncState for workouts but for activities
public enum WatchActivitySyncState: Equatable, Sendable {
    case loading // Initial loading or waiting for sync data
    case active // Activity is running normally
    case paused // Activity is paused
    case playingAudio(type: String) // Audio instruction playing
    case completed // Activity is complete
    case abandoned // Activity was abandoned
}
