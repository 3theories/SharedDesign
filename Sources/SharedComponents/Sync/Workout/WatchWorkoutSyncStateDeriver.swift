import Foundation

// MARK: - WatchSyncState

/// Sync state the Watch's workout player UI binds to. Derived from a
/// `WorkoutPlayerSyncState` snapshot via `WatchWorkoutSyncStateDeriver`.
///
/// Defined here in `SharedComponents` (rather than in `NioraWatchApp`)
/// so the test target — which targets `Niora` — can exercise the
/// derivation logic without importing watch-only modules.
public enum WatchSyncState: Equatable, Sendable {
    /// Initial loading or audio generation on iPhone.
    case loading
    /// Priority audio is playing (intro, round announcement, completion).
    case playingAudio(type: String)
    /// Inter-step "Get Ready" or pre-start countdown. Carries a wall-clock
    /// anchor so the view ticks via `TimelineView` without per-second
    /// snapshot republish — both peers compute
    /// `remaining = max(0, ceil(endsAt - now))`.
    case transitioning(stepName: String, endsAt: Date)
    /// Normal step view — step timer is running.
    case activeStep
    /// Workout is paused.
    case paused
    /// Workout is complete.
    case completed
}

// MARK: - WatchWorkoutSyncStateDeriver

/// Pure projection from `WorkoutPlayerSyncState` to `WatchSyncState`.
///
/// Extracted into `SharedComponents` so it can be unit-tested without
/// the `NioraWatchApp` target. Earlier bugs all originated in the
/// view-selector projection — "watch stuck on Connecting…", flicker
/// between Connecting and step view between steps, demote-to-loading
/// on transient audio prep — so locking the contract down with tests
/// is now load-bearing.
///
/// Branch precedence (top-down — first match wins):
///
///   1. Terminal (`.completed` / `.abandoned`)             → `.completed`
///   2. Paused                                              → `.paused`
///   3. Inter-step transition anchor (`transitionEndsAt`)   → `.transitioning`
///   4. Pre-start countdown anchor (`countdownEndsAt`)      → `.transitioning`
///   5. Setup phases (`.preparing` / `.ready` / `.countdown`) → `.loading`
///   6. Mid-workout priority audio playing                  → `.playingAudio`
///   7. Default (live phase, no overrides)                  → `.activeStep`
///
/// Notably absent: audio-prep does NOT demote to `.loading` mid-
/// workout. The previous design dropped to `.loading` whenever
/// `isPreparingAudio == true` in active/resting phase, but every step
/// transition flickers prep=true → false in rapid succession (next-step
/// intro audio cue prepares, plays, stops). Each flicker re-ran this
/// projection and produced visible "Connecting…" flashes between steps.
/// Worse: if the iPhone's last-published snapshot before
/// `applicationContext` coalesced happened to land with prep=true, the
/// watch stuck on `.loading` indefinitely. Audio prep is a transient
/// hint, not a structural signal — preserving the caller's `current`
/// syncState in that case keeps the view stable.
public enum WatchWorkoutSyncStateDeriver {
    public static func compute(
        from remote: WorkoutPlayerSyncState,
        current: WatchSyncState,
        now: Date = Date()
    ) -> WatchSyncState {
        // 1. Terminal phases → completed (regardless of anchors).
        if remote.phase == .completed || remote.phase == .abandoned {
            return .completed
        }

        // 2. Paused overrides everything except terminal — stable view.
        if remote.phase == .paused {
            return .paused
        }

        // 3 + 4. Active wall-clock anchor (inter-step or pre-start
        // countdown). Both render as `.transitioning`; their semantic
        // difference is captured in the iPhone's hook, not in the
        // watch UI.
        if let endsAt = remote.transitionEndsAt, endsAt > now {
            return .transitioning(stepName: remote.position.stepName, endsAt: endsAt)
        }
        if let endsAt = remote.countdownEndsAt, endsAt > now {
            return .transitioning(stepName: remote.position.stepName, endsAt: endsAt)
        }

        // 5. Setup phases (`.preparing` / `.ready`) — the workout is
        // booting OR mid-workout state briefly regressed (e.g. a coach
        // mutation re-fired `configUpdated` which reseeds the engine
        // through `.preparing`). Two cases:
        //
        //   • Cold boot — `current == .loading` was the seed value
        //     before any non-loading state ever rendered. Stay on
        //     `.loading` so the connecting overlay is shown.
        //   • Mid-workout regression — `current` is already a live
        //     mid-workout view (`.activeStep`, `.transitioning`,
        //     `.paused`, `.playingAudio`). PRESERVE that view rather
        //     than demoting back to `.loading`. The user has clearly
        //     started a workout; flashing "Connecting to iPhone…"
        //     between steps is a UX bug — the structural state is
        //     fine, the wire just briefly lied.
        //
        // `.countdown` is INTENTIONALLY excluded here. The phase is set
        // by the iPhone's `submitMeshCountdownStarted(endsAt:)` and
        // cleared (back to `.active`) by the subsequent `started`
        // event. There's a small gap (tens-to-hundreds of ms) between
        // the countdown's `endsAt` passing and the `.started` envelope
        // arriving where the snapshot still says
        // `phase=.countdown` with an expired anchor. If we treated
        // that as `.loading`, the watch would briefly drop to
        // "Connecting…" at the moment the countdown finishes — which
        // is what users actually saw in production logs at the
        // tail end of the pre-start 3-2-1.
        //
        // Anchor-in-the-future case is already handled by branch 4 and
        // returns `.transitioning` before this branch runs. So if we
        // reach here with phase=`.countdown`, the anchor is either
        // already expired or never set, and the countdown is
        // effectively over — show the step view.
        if remote.phase == .preparing || remote.phase == .ready {
            if current == .loading {
                return .loading
            }
            // Mid-workout regression — preserve the live view.
            return current
        }
        if remote.phase == .countdown {
            return .activeStep
        }

        // 6 + 7. Live phase (.active / .resting) or defensive fallback.
        if remote.phase == .active || remote.phase == .resting {
            if remote.audio.isPlayingPriorityAudio, let raw = remote.audio.priorityAudioType {
                return .playingAudio(type: raw)
            }
            if remote.audio.isPreparingAudio {
                // Mid-workout audio prep is transient; preserve the
                // caller's current view to avoid step-transition
                // flicker. If `current` was already `.loading` (e.g.
                // we just arrived from `.preparing`), preserve that;
                // otherwise stay on `.activeStep`. Either way, never
                // DEMOTE a non-loading view back to `.loading` solely
                // on audio prep.
                if current == .loading {
                    return .loading
                }
                return current
            }
            return .activeStep
        }

        // .idle / .completing / .closed — defensive fallback.
        return .activeStep
    }
}
