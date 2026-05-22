import Foundation
import SessionMesh

// MARK: - WorkoutPlayerSessionConfig

/// Workout configuration set when the workout starts and not changed during
/// the session. Both devices read the same config so they can render rounds /
/// sets / steps without a separate plan-distribution wire.
///
/// Coach-state fields (`isCoachPresented`, `coachChatState`) are intentionally
/// NOT in the mesh state — they are phone-only UI state, never replicated to
/// the watch and never overwritten by it.
public struct WorkoutPlayerSessionConfig: Codable, Sendable, Equatable {
    public init(
        workoutId: UUID? = nil,
        workoutName: String = "",
        scheduledActivityId: UUID? = nil,
        totalRounds: Int = 0,
        rounds: [WorkoutRoundSync] = [],
        isAssessmentWorkout: Bool = false
    ) {
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.scheduledActivityId = scheduledActivityId
        self.totalRounds = totalRounds
        self.rounds = rounds
        self.isAssessmentWorkout = isAssessmentWorkout
    }

    public let workoutId: UUID?
    public let workoutName: String
    public let scheduledActivityId: UUID?
    public let totalRounds: Int
    public let rounds: [WorkoutRoundSync]
    public let isAssessmentWorkout: Bool
}

// MARK: - WorkoutPlayerPositionState

/// Where the user is right now within the workout structure. Mutated by
/// `stepAdvanced` events; mesh's reducer guarantees both peers stay aligned
/// without each side having to recompute the next step independently.
public struct WorkoutPlayerPositionState: Codable, Sendable, Equatable {
    public init(
        currentRoundIndex: Int = 0,
        currentSetIndex: Int = 0,
        currentStepIndex: Int = 0,
        currentRepeatCount: Int = 0,
        roundName: String = "",
        stepName: String = "",
        stepType: String = "",
        stepDurationSeconds: TimeInterval? = nil,
        stepReps: Int? = nil,
        completedStepIds: [UUID] = []
    ) {
        self.currentRoundIndex = currentRoundIndex
        self.currentSetIndex = currentSetIndex
        self.currentStepIndex = currentStepIndex
        self.currentRepeatCount = currentRepeatCount
        self.roundName = roundName
        self.stepName = stepName
        self.stepType = stepType
        self.stepDurationSeconds = stepDurationSeconds
        self.stepReps = stepReps
        self.completedStepIds = completedStepIds
    }

    public var currentRoundIndex: Int
    public var currentSetIndex: Int
    public var currentStepIndex: Int
    public var currentRepeatCount: Int
    public var roundName: String
    public var stepName: String
    public var stepType: String
    public var stepDurationSeconds: TimeInterval?
    public var stepReps: Int?

    /// Append-only list of step IDs the user has completed during this run.
    /// The reducer appends on each `stepCompleted`; both devices share the
    /// same projection.
    public var completedStepIds: [UUID]
}

// MARK: - WorkoutPlayerMetricsState

/// HK-derived metrics. Watch-canonical on the wire — the watch publishes
/// samples; iPhone adopts.
public struct WorkoutPlayerMetricsState: Codable, Sendable, Equatable {
    public init(
        heartRate: Double = 0,
        activeCalories: Double = 0,
        totalRepsCompleted: Int = 0
    ) {
        self.heartRate = heartRate
        self.activeCalories = activeCalories
        self.totalRepsCompleted = totalRepsCompleted
    }

    public var heartRate: Double
    public var activeCalories: Double
    public var totalRepsCompleted: Int
}

// MARK: - WorkoutPlayerAudioState

/// Phone-canonical UI hint for which audio cue is playing / being prepared.
/// The watch reads this to render matching transition / loading overlays.
public struct WorkoutPlayerAudioState: Codable, Sendable, Equatable {
    public init(
        isPlayingPriorityAudio: Bool = false,
        priorityAudioType: String? = nil,
        isPreparingAudio: Bool = false
    ) {
        self.isPlayingPriorityAudio = isPlayingPriorityAudio
        self.priorityAudioType = priorityAudioType
        self.isPreparingAudio = isPreparingAudio
    }

    public var isPlayingPriorityAudio: Bool
    public var priorityAudioType: String?
    public var isPreparingAudio: Bool
}

// MARK: - WorkoutPlayerSyncState

/// State that `SessionSyncEngine` reduces over for the workout player. Single
/// source of truth on the wire — both devices reach this same shape after
/// applying any sequence of `WorkoutPlayerEvent` from any peer.
///
/// Notes on the shape:
///
/// - `phase` is derived from terminal events + the timer's `isPaused`. The
///   reducer keeps it in sync rather than deriving on every read so views can
///   bind cheaply. Workouts use `.resting` while the rest timer is active.
/// - `timer` is a `SessionTimerAnchor` from `SessionMesh`. Both devices
///   compute `elapsed(at: Date())` locally — there are no per-second tick
///   events on the wire. `stepStartedAt` on the anchor tracks the per-step
///   boundary for live "current step elapsed" rendering.
/// - `position.completedStepIds` is append-only; new completions are reduced
///   in, not snapshot-replaced.
/// - `metrics` are last-writer-wins per-sample (watch is canonical for HR /
///   calories; iPhone stays in lockstep via `metricsSampled` events).
public struct WorkoutPlayerSyncState: Codable, Sendable, Equatable {
    public init(
        config: WorkoutPlayerSessionConfig = WorkoutPlayerSessionConfig(),
        timer: SessionTimerAnchor,
        phase: ActivityPhase = .idle,
        position: WorkoutPlayerPositionState = WorkoutPlayerPositionState(),
        metrics: WorkoutPlayerMetricsState = WorkoutPlayerMetricsState(),
        audio: WorkoutPlayerAudioState = WorkoutPlayerAudioState(),
        countdownEndsAt: Date? = nil,
        transitionEndsAt: Date? = nil,
        restTimerEndsAt: Date? = nil,
        endedAt: Date? = nil,
        terminalReason: String? = nil,
        continueOnWatch: Bool = false,
        pendingStartRequest: WorkoutPlayerStartRequest? = nil
    ) {
        self.config = config
        self.timer = timer
        self.phase = phase
        self.position = position
        self.metrics = metrics
        self.audio = audio
        self.countdownEndsAt = countdownEndsAt
        self.transitionEndsAt = transitionEndsAt
        self.restTimerEndsAt = restTimerEndsAt
        self.endedAt = endedAt
        self.terminalReason = terminalReason
        self.continueOnWatch = continueOnWatch
        self.pendingStartRequest = pendingStartRequest
    }

    public var config: WorkoutPlayerSessionConfig
    public var timer: SessionTimerAnchor
    public var phase: ActivityPhase
    public var position: WorkoutPlayerPositionState
    public var metrics: WorkoutPlayerMetricsState
    public var audio: WorkoutPlayerAudioState

    /// Wall-clock target for the **pre-start** countdown — the 3-2-1 the
    /// player shows after intro audio and before the first step. Both peers
    /// render `max(0, ceil(countdownEndsAt - now))` from a shared
    /// `TimelineView`. `nil` outside the pre-start window.
    public var countdownEndsAt: Date?

    /// Wall-clock target for the **inter-step "Get Ready"** countdown —
    /// the 3-2-1 buffer between two regular workout steps. Distinct from
    /// `countdownEndsAt` (which is only the pre-start) and from
    /// `restTimerEndsAt` (which is an explicit rest *step*'s timer).
    /// Watch UI checks this first; if non-nil, render the Get Ready overlay.
    /// `nil` outside a transition.
    public var transitionEndsAt: Date?

    /// Wall-clock instant when the **rest step** timer fires. This is for
    /// rest steps explicitly authored in the workout plan (e.g. 30s
    /// recovery). Both devices render `max(0, restTimerEndsAt - now)`.
    /// `nil` outside `.resting`.
    public var restTimerEndsAt: Date?

    /// Wall-clock instant of the terminal event (`completed` or `abandoned`).
    /// `nil` while the workout is running.
    public var endedAt: Date?

    /// Optional human-readable reason for `abandoned`.
    public var terminalReason: String?

    /// Hint for `phase == .closed`: when `true`, the workout continues on
    /// the watch after the iPhone player closes. When `false` (default), the
    /// watch tears down too.
    public var continueOnWatch: Bool

    /// A pending Watch-initiated start request. Set by `requestStart`;
    /// cleared by the iPhone once it has constructed the live workout VM
    /// and emitted the first `started` event. The iPhone uses this as the
    /// signal to foreground and start the scheduled workout.
    public var pendingStartRequest: WorkoutPlayerStartRequest?

    /// Convenience: total elapsed workout time the user would see at `date`.
    /// Reads through to the timer anchor.
    public func elapsed(at date: Date) -> TimeInterval {
        self.timer.elapsed(at: date)
    }

    /// Returns a copy with `phase` and time-bound anchors normalized so
    /// they're internally consistent at the supplied `now`.
    ///
    /// The wire-level reducer stores `phase` (the last explicit phase
    /// transition) and the time anchors (`countdownEndsAt`,
    /// `transitionEndsAt`) independently. Between an anchor expiring
    /// and the iPhone's hooks firing the next phase-transition event,
    /// the two can disagree — most commonly:
    ///
    ///   `phase = .countdown` AND `countdownEndsAt < now`
    ///
    /// Snapshots published during that window are inconsistent at the
    /// wire level. Callers (publishers, receivers, view-projectors)
    /// can call this to get a self-consistent snapshot:
    ///
    ///   * Expired countdown: `phase` reverts to `.active` and the
    ///     `countdownEndsAt` anchor is cleared. The `.started` event
    ///     fired by the hook is now redundant for the receiver but
    ///     idempotent at the reducer level.
    ///   * Expired transition: `transitionEndsAt` is cleared
    ///     (transitions don't change phase, so nothing else moves).
    ///
    /// Idempotent — calling repeatedly with the same `now` is a no-op.
    public func normalizedForWire(at now: Date = Date()) -> WorkoutPlayerSyncState {
        var normalized = self

        // Countdown: if phase is .countdown but the anchor passed (or
        // never existed), the countdown is effectively over.
        if normalized.phase == .countdown {
            if let endsAt = normalized.countdownEndsAt {
                if endsAt <= now {
                    normalized.phase = .active
                    normalized.countdownEndsAt = nil
                }
                // else: anchor still active, keep phase=.countdown.
            } else {
                // No anchor and phase=.countdown is ill-defined.
                // Treat as .active so the receiver doesn't get stuck.
                normalized.phase = .active
            }
        }

        // Transition: anchor lives independently of phase, but
        // a stale anchor can still drive UI projections (e.g.,
        // `WatchWorkoutSyncStateDeriver`'s `.transitioning` branch).
        // Clear it once expired so peers don't briefly render a
        // Get Ready overlay for a transition that's already over.
        if let endsAt = normalized.transitionEndsAt, endsAt <= now {
            normalized.transitionEndsAt = nil
        }

        return normalized
    }
}

// MARK: - WorkoutPlayerStartRequest

/// A Watch-originated request to start a scheduled workout. The Watch puts
/// this on the wire when the user taps Start on a scheduled-today tile; the
/// iPhone observes it, foregrounds, and constructs the live VM. The iPhone
/// clears it once the workout is actually running.
public struct WorkoutPlayerStartRequest: Codable, Sendable, Equatable {
    public init(
        scheduledActivityId: UUID,
        requestedByPeerID: String,
        requestedAt: Date
    ) {
        self.scheduledActivityId = scheduledActivityId
        self.requestedByPeerID = requestedByPeerID
        self.requestedAt = requestedAt
    }

    public let scheduledActivityId: UUID
    public let requestedByPeerID: String
    public let requestedAt: Date
}
