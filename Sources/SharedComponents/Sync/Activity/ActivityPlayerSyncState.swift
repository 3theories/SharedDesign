import Foundation
import SessionMesh

// MARK: - ActivityPlayerSessionConfig

/// Configuration that's set when the activity starts and doesn't change during
/// the session. Both devices read the same config so they can render the
/// correct activity name, choose lap-vs-set tracking mode, etc.
public struct ActivityPlayerSessionConfig: Codable, Sendable, Equatable {
    public init(
        activityType: String,
        sportType: String? = nil,
        activityName: String,
        trackingMode: ActivityTrackingMode? = nil,
        opponentName: String? = nil,
        matchType: String? = nil,
        periodConfig: PeriodConfig? = nil,
        quickActions: [QuickActionSync] = [],
        hasScoring: Bool = false,
        isInningsBased: Bool = false,
        estimatedDuration: TimeInterval? = nil
    ) {
        self.activityType = activityType
        self.sportType = sportType
        self.activityName = activityName
        self.trackingMode = trackingMode
        self.opponentName = opponentName
        self.matchType = matchType
        self.periodConfig = periodConfig
        self.quickActions = quickActions
        self.hasScoring = hasScoring
        self.isInningsBased = isInningsBased
        self.estimatedDuration = estimatedDuration
    }

    public let activityType: String
    public let sportType: String?
    public let activityName: String
    public let trackingMode: ActivityTrackingMode?
    public let opponentName: String?
    public let matchType: String?
    public let periodConfig: PeriodConfig?
    public let quickActions: [QuickActionSync]
    public let hasScoring: Bool
    public let isInningsBased: Bool
    public let estimatedDuration: TimeInterval?
}

// MARK: - ActivityScoreState

/// Sport-only score state — `nil` for freeform activities.
public struct ActivityScoreState: Codable, Sendable, Equatable {
    public init(
        userScore: String,
        opponentScore: String? = nil,
        isUserServing: Bool? = nil,
        isUserBatting: Bool? = nil,
        currentPeriodIndex: Int? = nil,
        currentPeriodName: String? = nil,
        engineScoreSnapshot: EngineScoreSnapshot? = nil
    ) {
        self.userScore = userScore
        self.opponentScore = opponentScore
        self.isUserServing = isUserServing
        self.isUserBatting = isUserBatting
        self.currentPeriodIndex = currentPeriodIndex
        self.currentPeriodName = currentPeriodName
        self.engineScoreSnapshot = engineScoreSnapshot
    }

    public var userScore: String
    public var opponentScore: String?
    public var isUserServing: Bool?
    public var isUserBatting: Bool?
    public var currentPeriodIndex: Int?
    public var currentPeriodName: String?
    public var engineScoreSnapshot: EngineScoreSnapshot?
}

// MARK: - ActivityMetricsState

/// HK-derived metrics. Watch-canonical — the watch publishes samples; iPhone
/// adopts. Stored on the synced state so the iPhone mini-player + main VM
/// both see the same numbers without separate plumbing.
public struct ActivityMetricsState: Codable, Sendable, Equatable {
    public init(
        heartRate: Double = 0,
        activeCalories: Double = 0,
        distance: Double? = nil,
        cadence: Double? = nil
    ) {
        self.heartRate = heartRate
        self.activeCalories = activeCalories
        self.distance = distance
        self.cadence = cadence
    }

    public var heartRate: Double
    public var activeCalories: Double
    public var distance: Double?
    public var cadence: Double?
}

// MARK: - ActivityPlayerSyncState

/// State that `SessionSyncEngine` reduces over for the activity player. This
/// is the single source of truth on the wire — both devices reach this same
/// shape after applying any sequence of `ActivityPlayerEvent` from any peer.
///
/// Notes on the shape:
///
/// - `phase` is derived from terminal events + the timer's `isPaused`. The
///   reducer keeps it in sync rather than deriving on every read so views can
///   bind cheaply.
/// - `timer` is a `SessionTimerAnchor` from `SessionMesh`. Both devices
///   compute `elapsed(at: Date())` locally — there are no per-second tick
///   events on the wire.
/// - `laps` / `sets` are append-only event projections; new actions are
///   reduced into them, not snapshot-replaced field-by-field.
/// - `metrics` are last-writer-wins per-sample (watch is authoritative for HK
///   metrics; iPhone is for distance when GPS-tracking).
public struct ActivityPlayerSyncState: Codable, Sendable, Equatable {
    public init(
        config: ActivityPlayerSessionConfig,
        timer: SessionTimerAnchor,
        phase: ActivityPhase = .active,
        laps: [LapState] = [],
        sets: [SetState] = [],
        score: ActivityScoreState? = nil,
        metrics: ActivityMetricsState = ActivityMetricsState(),
        endedAt: Date? = nil,
        terminalReason: String? = nil,
        countdownEndsAt: Date? = nil,
        continueOnWatch: Bool = false,
        isPlayingAudio: Bool = false,
        audioType: String? = nil,
        currentLapStartTime: Date? = nil,
        currentLapPausedTime: TimeInterval = 0,
        currentSetNumber: Int? = nil
    ) {
        self.config = config
        self.timer = timer
        self.phase = phase
        self.laps = laps
        self.sets = sets
        self.score = score
        self.metrics = metrics
        self.endedAt = endedAt
        self.terminalReason = terminalReason
        self.countdownEndsAt = countdownEndsAt
        self.continueOnWatch = continueOnWatch
        self.isPlayingAudio = isPlayingAudio
        self.audioType = audioType
        self.currentLapStartTime = currentLapStartTime
        self.currentLapPausedTime = currentLapPausedTime
        self.currentSetNumber = currentSetNumber
    }

    public var config: ActivityPlayerSessionConfig
    public var timer: SessionTimerAnchor
    public var phase: ActivityPhase
    public var laps: [LapState]
    public var sets: [SetState]
    public var score: ActivityScoreState?
    public var metrics: ActivityMetricsState

    /// Wall-clock instant of the terminal event (`completed` or `abandoned`).
    /// `nil` while the activity is running.
    public var endedAt: Date?

    /// Optional human-readable reason for `abandoned`. Surface in summaries
    /// or post-activity flows; the reducer preserves it through subsequent
    /// no-op events.
    public var terminalReason: String?

    /// Wall-clock target for the pre-start countdown; both peers render
    /// `max(0, countdownEndsAt - now)` from a shared `TimelineView` so the
    /// countdown ticks in lockstep without drift.
    public var countdownEndsAt: Date?

    /// Hint for `phase == .closed`: when `true`, the activity continues on
    /// the watch after the iPhone player closes. When `false` (default), the
    /// watch tears down too.
    public var continueOnWatch: Bool

    /// Whether the iPhone is playing an audio cue (intro / completion).
    /// Drives the watch's "Wrapping up…" / "Get Ready" overlays.
    public var isPlayingAudio: Bool

    /// Identifier for the audio cue type currently playing (e.g. "instruction").
    public var audioType: String?

    /// Lap-in-progress start time. Per-lap timer state for live UI display.
    /// Derivable from `laps.last?.endTime ?? timer.startedAt` but cached here
    /// for the watch's bootstrap path which needs it inline.
    public var currentLapStartTime: Date?

    /// Time accumulated as paused within the current lap. Reset to 0 when
    /// `lapRecorded` fires.
    public var currentLapPausedTime: TimeInterval

    /// Next set number to be recorded (1-based). For `tracking == .sets` only.
    public var currentSetNumber: Int?

    /// Convenience: elapsed time the user would see at `date`. Reads through
    /// to the timer anchor; doesn't account for per-lap paused time (that's
    /// tracked separately on `LapState`).
    public func elapsed(at date: Date) -> TimeInterval {
        self.timer.elapsed(at: date)
    }

    /// Effective `startTime` for consumers using the legacy
    /// `ActivityPlayerState.calculateElapsedTime` model (`(now - startTime) -
    /// totalPausedTime`).
    ///
    /// Mesh's `SessionTimerAnchor` rebases `startedAt` on every resume and
    /// tracks cumulative active time in `accumulatedElapsedBeforeAnchor`.
    /// The legacy formula expects an unmoving `startTime` plus cumulative
    /// `totalPausedTime`. To bridge them, back-shift the live anchor (or the
    /// pause anchor when paused) by `accumulated` so the legacy formula
    /// reduces to `(now - effectiveStart)` with `totalPausedTime: 0` —
    /// matching what `elapsed(at:)` returns from the mesh model.
    ///
    /// Returns `nil` for non-running phases (idle / preparing / countdown /
    /// terminal); callers should leave their local `startTime` alone in
    /// those cases.
    public var legacyEffectiveStartTime: Date? {
        guard self.phase == .active || self.phase == .paused else { return nil }
        let accumulated = self.timer.accumulatedElapsedBeforeAnchor
        let anchor = self.timer.isPaused
            ? (self.timer.pauseStartedAt ?? self.timer.startedAt)
            : self.timer.startedAt
        return anchor.addingTimeInterval(-accumulated)
    }
}
