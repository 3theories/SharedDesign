import Foundation

// MARK: - ActivityPlayerEvent

/// Feature-owned event payload for `SessionSyncEngine`. Every user action
/// (pause / resume / lap / set / score / complete / abandon) and every
/// system observation (HK metric sample) becomes one of these. The engine
/// gates duplicates by `eventID`, gates ordering by per-peer `sequence`,
/// and dispatches to `ActivityPlayerReducer` for state mutation.
///
/// Carries `at: Date` on every case so the reducer can stamp lap boundaries
/// and pause anchors at the originating tap moment, not at receive time —
/// same anti-clock-drift fix we hand-rolled in pause/resume just before this
/// migration, now part of the wire format.
public enum ActivityPlayerEvent: Codable, Sendable, Equatable {
    /// User tapped pause on either device. `at` is the originating tap
    /// timestamp — the reducer freezes the timer at that moment regardless
    /// of when the envelope arrives.
    case paused(at: Date)

    /// User tapped resume. `at` becomes the new `startedAt` anchor for the
    /// timer, with prior accumulated elapsed preserved.
    case resumed(at: Date)

    /// User tapped lap. The reducer derives `startTime` from the previous
    /// lap's `endTime` (or session start) and `endTime = at`.
    case lapRecorded(
        at: Date,
        distance: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    )

    /// User tapped record-set (HIIT / strength).
    case setRecorded(
        at: Date,
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        weight: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    )

    /// Score change for sport activities. `userScore` and `opponentScore`
    /// carry display values (already formatted by the scoring engine).
    case scoreUpdated(
        at: Date,
        userScore: String,
        opponentScore: String? = nil,
        isUserServing: Bool? = nil,
        isUserBatting: Bool? = nil
    )

    /// HK or GPS sample. Watch-canonical for HR / calories; either device
    /// may publish distance depending on which has the GPS source.
    case metricsSampled(
        at: Date,
        heartRate: Double,
        calories: Double,
        distance: Double? = nil,
        cadence: Double? = nil
    )

    /// Terminal: user completed the activity. The reducer stamps `endedAt`,
    /// freezes the timer at `at`, and transitions phase to `.completed`.
    case completed(at: Date)

    /// Terminal: user abandoned. `reason` is optional (e.g. "Closed without
    /// finishing"). Reducer transitions phase to `.abandoned`.
    case abandoned(at: Date, reason: String? = nil)

    /// Owner is loading or playing an audio cue (intro / completion). Drives
    /// the peer's "Wrapping up…" / "Get Ready" overlays.
    case audioStateChanged(at: Date, isPlayingAudio: Bool, audioType: String?)

    /// Pre-start countdown begins. `endsAt` is the wall-clock target both
    /// peers render via a shared `TimelineView`. Reducer transitions phase
    /// to `.countdown` and stores the anchor.
    case countdownStarted(at: Date, endsAt: Date)

    /// Owner explicitly transitions phase outside the user-action events.
    /// Used for `.preparing` (start-of-activity buffer), `.ready`, and
    /// `.closed` (iPhone closed the player; watch decides via
    /// `continueOnWatch` whether to take ownership).
    case phaseChanged(at: Date, phase: ActivityPhase, continueOnWatch: Bool = false)

    /// Activity timer actually started ticking — user tapped Start (after
    /// any countdown/preparing buffer). Reducer rebases `timer.startedAt`
    /// to `at` so peers don't tick from the adapter-boot fallback. This
    /// is the *real* activity start; `phaseChanged(.active)` alone leaves
    /// the timer anchor at whatever the snapshot init set it to, which is
    /// often the adapter-boot moment (a few seconds before the user
    /// actually tapped Start).
    case started(at: Date)

    /// Sport period or innings boundary moved. Carries the new
    /// `currentPeriodIndex` (0-based) and an optional display name (e.g.
    /// "2nd Half"). The reducer updates `state.score`.
    case periodChanged(
        at: Date,
        currentPeriodIndex: Int,
        currentPeriodName: String? = nil,
        engineScoreSnapshot: EngineScoreSnapshot? = nil
    )
}

extension ActivityPlayerEvent {
    /// The event's wall-clock origin. Useful to the conflict policy for
    /// causal LWW comparisons that don't want to depend on `metadata`.
    public var occurredAt: Date {
        switch self {
        case let .paused(at),
             let .resumed(at),
             let .lapRecorded(at, _, _, _),
             let .setRecorded(at, _, _, _, _, _),
             let .scoreUpdated(at, _, _, _, _),
             let .metricsSampled(at, _, _, _, _),
             let .completed(at),
             let .abandoned(at, _),
             let .audioStateChanged(at, _, _),
             let .countdownStarted(at, _),
             let .phaseChanged(at, _, _),
             let .periodChanged(at, _, _, _),
             let .started(at):
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
