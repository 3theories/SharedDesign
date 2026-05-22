import Foundation

// MARK: - ActivitySchemaVersion

public enum ActivitySchemaVersion {
    /// Current envelope schema. Bump when the envelope shape itself changes.
    public static let current: Int = 2

    /// Lowest schema this build can decode. Receivers reject envelopes below this.
    public static let minSupported: Int = 2
}

// MARK: - ActivityPhase

/// Canonical phase of an activity or workout, agreed by both iPhone and Watch.
///
/// Both players use this enum. Workouts additionally use `.resting`; sport / freeform
/// activities never transition to `.resting`.
public enum ActivityPhase: String, Codable, Sendable, CaseIterable, Equatable {
    case idle
    case preparing
    case ready
    case countdown
    case active
    case paused
    case resting
    case completing
    case completed
    case abandoned
    case closed

    public var isTerminal: Bool {
        switch self {
        case .completed, .abandoned, .closed: true
        default: false
        }
    }

    public var isRunning: Bool {
        switch self {
        case .active, .paused, .resting: true
        default: false
        }
    }

    /// "User has committed to the workout — player UI should show pause icon
    /// (running) rather than play icon (paused/idle)." Broader than
    /// `isRunning`; includes setup phases (`preparing` / `ready` / `countdown`)
    /// and the brief `completing` finalization. Used by the watch's
    /// `applyRemoteWorkoutSnapshot` to derive `state.isStarted` so a
    /// freshly-published config doesn't make the watch's play/pause button
    /// render as paused — see `WorkoutPlayerReducerTests.configUpdated*`
    /// and `ActivityPhaseTests.isLive*`.
    public var isLive: Bool {
        switch self {
        case .idle, .completed, .abandoned, .closed: false
        case .preparing, .ready, .countdown, .active, .paused, .resting, .completing: true
        }
    }
}

// MARK: - ActivityOwner

/// Which device currently owns authoritative state for the activity.
public enum ActivityOwner: String, Codable, Sendable {
    case phone
    case watch
}

// MARK: - ActivityEnvelope

/// Versioned, idempotent wrapper around any sync payload.
///
/// Receivers track `lastSequence[(epoch, type)]` and `lastEpoch` to reject
/// duplicates and out-of-order deliveries. A newer `epoch` (or higher
/// `sequence` within the same epoch) wins; older messages are dropped.
public struct ActivityEnvelope<Payload: Codable & Sendable>: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        schemaVersion: Int = ActivitySchemaVersion.current,
        epoch: UUID,
        sequence: UInt64,
        phase: ActivityPhase,
        owner: ActivityOwner,
        emittedAt: Date = Date(),
        payload: Payload
    ) {
        self.schemaVersion = schemaVersion
        self.epoch = epoch
        self.sequence = sequence
        self.phase = phase
        self.owner = owner
        self.emittedAt = emittedAt
        self.payload = payload
    }

    // MARK: Public

    public let schemaVersion: Int
    public let epoch: UUID
    public let sequence: UInt64
    public let phase: ActivityPhase
    public let owner: ActivityOwner
    public let emittedAt: Date
    public let payload: Payload
}

// MARK: - Sequence comparison

extension ActivityEnvelope {
    /// Returns `true` if `self` should supersede `other`.
    ///
    /// Rules:
    /// - Different epoch → newer `emittedAt` wins.
    /// - Same epoch → higher `sequence` wins.
    public func supersedes(_ other: ActivityEnvelope<some Codable & Sendable>) -> Bool {
        if self.epoch == other.epoch {
            return self.sequence > other.sequence
        }
        return self.emittedAt > other.emittedAt
    }
}
