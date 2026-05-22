import Foundation

// MARK: - WorkoutPlayerEvent

/// Feature-owned event payload for the workout player's `SessionSyncEngine`.
/// Every user action (pause / resume / step advance / step completion / rest
/// timer / complete / abandon) and every system observation (HK sample,
/// audio cue) becomes one of these. The engine gates duplicates by
/// `eventID`, gates ordering by per-peer `sequence`, and dispatches to
/// `WorkoutPlayerReducer` for state mutation.
///
/// Carries `at: Date` on every case so the reducer stamps step boundaries
/// and pause anchors at the originating tap moment, not at receive time.
public enum WorkoutPlayerEvent: Codable, Sendable, Equatable {
    // MARK: - Lifecycle

    /// User tapped pause on either device.
    case paused(at: Date)

    /// User tapped resume.
    case resumed(at: Date)

    /// Workout timer actually started ticking — user tapped Start (after any
    /// countdown / preparing buffer). Reducer rebases `timer.startedAt = at`.
    case started(at: Date)

    /// One-shot at workout boot: replaces the mesh state's `config` with
    /// the full workout structure (rounds tree + ids + names). The watch
    /// reads this to render the step list and step details without needing
    /// any legacy `WorkoutSyncData` wire. Subsequent in-session updates
    /// (e.g. coach mutations) re-fire the same event with the new config.
    case configUpdated(at: Date, config: WorkoutPlayerSessionConfig)

    /// Terminal: user completed the workout. Reducer stamps `endedAt`,
    /// freezes the timer at `at`, and transitions phase to `.completed`.
    case completed(at: Date)

    /// Terminal: user abandoned. Reducer transitions phase to `.abandoned`.
    case abandoned(at: Date, reason: String? = nil)

    // MARK: - Workout-specific structure

    /// Position moved to a new step. Carries the full new position so the
    /// peer can render without recomputing it locally; carries
    /// `stepStartedAt` so the timer's per-step boundary moves in lockstep.
    case stepAdvanced(
        at: Date,
        position: WorkoutPlayerPositionState,
        stepStartedAt: Date
    )

    /// User completed the current step (or it auto-completed via timer).
    /// `stepId` is appended to `position.completedStepIds`. Optional
    /// `repsCompleted` / `weight` carry the post-set values for strength /
    /// HIIT exercises.
    case stepCompleted(
        at: Date,
        stepId: UUID,
        repsCompleted: Int? = nil,
        weight: Double? = nil
    )

    // MARK: - Rest timer (rest *step* — explicit recovery step in the plan)

    /// Rest cycle started. `endsAt` is the wall-clock target both peers
    /// render via a shared `TimelineView`. Reducer transitions phase to
    /// `.resting`.
    case restTimerStarted(at: Date, endsAt: Date)

    /// User skipped the rest cycle. Reducer clears `restTimerEndsAt` and
    /// transitions phase back to `.active`.
    case restTimerCancelled(at: Date)

    // MARK: - Inter-step transition ("Get Ready" 3-2-1 between regular steps)

    /// Inter-step transition began. `endsAt` is the wall-clock target.
    /// Watch shows a Get Ready overlay; phase stays `.active` since the
    /// workout is mid-flight, just buffering. Reducer sets
    /// `state.transitionEndsAt`.
    case transitionStarted(at: Date, endsAt: Date)

    /// Inter-step transition ended (countdown finished or user advanced).
    /// Reducer clears `state.transitionEndsAt`.
    case transitionEnded(at: Date)

    // MARK: - HK metrics & audio

    /// HK sample. Watch-canonical for HR / calories; `totalRepsCompleted`
    /// carries cumulative reps for the assessment-mode display.
    case metricsSampled(
        at: Date,
        heartRate: Double,
        calories: Double,
        totalRepsCompleted: Int? = nil
    )

    /// Owner is loading or playing a priority audio cue (intro / round
    /// announcement / completion). Drives the peer's "Wrapping up…" /
    /// "Get Ready" overlays.
    case audioStateChanged(
        at: Date,
        isPlayingPriorityAudio: Bool,
        priorityAudioType: String?,
        isPreparingAudio: Bool
    )

    /// Pre-start countdown begins. `endsAt` is the wall-clock target.
    /// Reducer transitions phase to `.countdown` and stores the anchor.
    case countdownStarted(at: Date, endsAt: Date)

    // MARK: - Phase

    /// Owner explicitly transitions phase outside the user-action events.
    /// Used for `.preparing`, `.ready`, and `.closed` (iPhone closed the
    /// player; watch decides via `continueOnWatch` whether to take
    /// ownership).
    case phaseChanged(at: Date, phase: ActivityPhase, continueOnWatch: Bool = false)

    // MARK: - Watch-initiated start (Phase A — see SESSION_MESH_ARCHITECTURE.md §9)

    /// Watch user tapped Start on a scheduled-today tile. Reducer stores the
    /// `WorkoutPlayerStartRequest` on the state. The iPhone observes it,
    /// foregrounds, constructs the workout VM with the full plan, and emits
    /// `started(at:)` once it's actually ticking — the reducer clears the
    /// request at that point.
    ///
    /// This is the only event the watch submits before the workout has a
    /// `config` populated. It's also the only event the iPhone receives
    /// while in idle phase that should advance state.
    case requestStart(
        at: Date,
        scheduledActivityId: UUID,
        requestedByPeerID: String
    )

    // MARK: - Watch-initiated step navigation (Plan §C5+C6)

    /// Watch user tapped the Next button on the step view. The iPhone is
    /// the source-of-truth for step progression (it owns the workout
    /// structure + hooks pipeline), so this is a pure *intent* event:
    /// the reducer ignores it, the iPhone-side `onRemoteEvent` handler
    /// forwards to the VM's existing `watchDidRequestNextStep` delegate
    /// path. The iPhone then computes the next step and emits a
    /// `stepAdvanced` envelope so both peers converge.
    ///
    /// Replaces the legacy `WatchHealthKitManager.sendNavigationEvent`
    /// HK-channel wire (Plan §C5+C6: "Kill the dual-channel write").
    case requestNextStep(at: Date)

    /// Watch user tapped a step in the step list. Same intent-only
    /// semantics as `requestNextStep` — the iPhone resolves the
    /// (round, set) target and emits `stepAdvanced` from there.
    case requestJumpToStep(
        at: Date,
        roundIndex: Int,
        setIndex: Int
    )
}

extension WorkoutPlayerEvent {
    /// The event's wall-clock origin. Useful to the conflict policy for
    /// causal LWW comparisons.
    public var occurredAt: Date {
        switch self {
        case let .paused(at),
             let .resumed(at),
             let .started(at),
             let .completed(at),
             let .abandoned(at, _),
             let .stepAdvanced(at, _, _),
             let .stepCompleted(at, _, _, _),
             let .restTimerStarted(at, _),
             let .restTimerCancelled(at),
             let .transitionStarted(at, _),
             let .transitionEnded(at),
             let .configUpdated(at, _),
             let .metricsSampled(at, _, _, _),
             let .audioStateChanged(at, _, _, _),
             let .countdownStarted(at, _),
             let .phaseChanged(at, _, _),
             let .requestStart(at, _, _),
             let .requestNextStep(at),
             let .requestJumpToStep(at, _, _):
            return at
        }
    }

    /// `true` if this event transitions to a terminal phase. Used by the
    /// conflict policy to suppress non-terminal events arriving after a
    /// terminal has already been applied.
    public var isTerminal: Bool {
        switch self {
        case .completed, .abandoned: return true
        default: return false
        }
    }

    /// `true` if this event is a high-frequency metric sample. Used by the
    /// adapter to skip applicationContext snapshot refresh — metrics flow
    /// through the live envelope wire only, never via the recovery substrate.
    public var isMetric: Bool {
        switch self {
        case .metricsSampled: return true
        default: return false
        }
    }
}
