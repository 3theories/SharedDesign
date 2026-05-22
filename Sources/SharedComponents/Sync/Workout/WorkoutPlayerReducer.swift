import Foundation
import SessionMesh

// MARK: - WorkoutPlayerReducer

/// Pure reducer applying `WorkoutPlayerEvent` to `WorkoutPlayerSyncState`.
/// Stays Foundation-only and free of side effects — every transition is a
/// state mutation expressed as a function of the current state + the event.
///
/// Both the iPhone `WorkoutPlayerSyncAdapter` and the watch's adapter run
/// the *same* reducer instance, so any sequence of events submitted from
/// either side converges to the same final state.
public struct WorkoutPlayerReducer: SessionSyncReducer {
    public typealias State = WorkoutPlayerSyncState
    public typealias Event = WorkoutPlayerEvent

    public init() { }

    public func reduce(
        state: inout WorkoutPlayerSyncState,
        event: WorkoutPlayerEvent,
        context _: SessionEventContext
    ) throws {
        // Once terminal, only metrics keep applying so HK samples that
        // arrive after `completed` still update the post-workout summary.
        if state.phase == .completed || state.phase == .abandoned {
            if case let .metricsSampled(_, hr, cal, totalReps) = event {
                self.applyMetrics(&state, heartRate: hr, calories: cal, totalReps: totalReps)
            }
            return
        }

        switch event {
        case let .paused(at):
            self.applyPause(&state, at: at)

        case let .resumed(at):
            self.applyResume(&state, at: at)

        case let .started(at):
            self.applyStarted(&state, at: at)

        case let .configUpdated(_, config):
            // Replace the workout's config tree. Position resets aren't
            // implied — the reducer leaves position alone; if the iPhone
            // wants to move position too it fires a stepAdvanced after.
            state.config = config
            // First config update leaves the engine in `.preparing` so
            // peers can recognize a live workout before `submitStarted`
            // (which only fires after the 3-second pre-start countdown).
            // Without this transition, every snapshot reads `phase=idle`
            // until the countdown completes, and the watch's gate would
            // never let the player surface during preparation.
            if state.phase == .idle {
                state.phase = .preparing
            }

        case let .completed(at):
            self.applyTerminal(&state, at: at, phase: .completed, reason: nil)

        case let .abandoned(at, reason):
            self.applyTerminal(&state, at: at, phase: .abandoned, reason: reason)

        case let .stepAdvanced(_, position, stepStartedAt):
            self.applyStepAdvanced(&state, position: position, stepStartedAt: stepStartedAt)

        case let .stepCompleted(_, stepId, _, _):
            // Only track the ID set on the wire — reps / weight are kept on
            // the iPhone's domain model (the canonical workout record). The
            // wire shape stays small.
            if !state.position.completedStepIds.contains(stepId) {
                state.position.completedStepIds.append(stepId)
            }

        case let .restTimerStarted(_, endsAt):
            state.restTimerEndsAt = endsAt
            state.phase = .resting

        case let .restTimerCancelled(_):
            state.restTimerEndsAt = nil
            // Only flip phase if we're actually resting; a redundant cancel
            // shouldn't move us out of e.g. `.paused`.
            if state.phase == .resting {
                state.phase = .active
            }

        case let .transitionStarted(_, endsAt):
            // Inter-step "Get Ready" buffer. Phase stays whatever it was
            // (typically `.active`) — the watch UI checks
            // `transitionEndsAt` first and shows the Get Ready overlay
            // regardless of the underlying phase.
            state.transitionEndsAt = endsAt

        case .transitionEnded:
            state.transitionEndsAt = nil

        case let .metricsSampled(_, hr, cal, totalReps):
            self.applyMetrics(&state, heartRate: hr, calories: cal, totalReps: totalReps)

        case let .audioStateChanged(_, isPlayingPriorityAudio, priorityAudioType, isPreparingAudio):
            state.audio = WorkoutPlayerAudioState(
                isPlayingPriorityAudio: isPlayingPriorityAudio,
                priorityAudioType: priorityAudioType,
                isPreparingAudio: isPreparingAudio
            )

        case let .countdownStarted(_, endsAt):
            state.countdownEndsAt = endsAt
            state.phase = .countdown

        case let .phaseChanged(_, phase, continueOnWatch):
            state.phase = phase
            if phase == .closed {
                state.continueOnWatch = continueOnWatch
            }

        case let .requestStart(at, scheduledActivityId, requestedByPeerID):
            // Watch asked iPhone to start a scheduled workout. Park the
            // request on state; iPhone observes and acts. iPhone clears it
            // by emitting `started(at:)` once the workout VM is live, which
            // is what flips phase to `.active` and rebases the timer anchor.
            state.pendingStartRequest = WorkoutPlayerStartRequest(
                scheduledActivityId: scheduledActivityId,
                requestedByPeerID: requestedByPeerID,
                requestedAt: at
            )

        case .requestNextStep, .requestJumpToStep:
            // Pure intent events — no reducer mutation. iPhone's
            // `WorkoutWatchSyncService.applyRemoteWorkoutEvent` consumes
            // these via `onRemoteEvent` and dispatches to the VM's
            // `watchDidRequestNextStep` / `watchDidRequestJumpToStep`
            // delegate methods, which compute the actual step move and
            // emit a `stepAdvanced` envelope. The reducer stays a pure
            // function of state — intent routing is the adapter's job.
            break
        }
    }

    // MARK: Private

    private func applyPause(_ state: inout WorkoutPlayerSyncState, at: Date) {
        guard !state.timer.isPaused else { return }
        let priorAccumulated = state.timer.accumulatedElapsedBeforeAnchor
        let runFromAnchor = max(0, at.timeIntervalSince(state.timer.startedAt))
        state.timer = SessionTimerAnchor(
            startedAt: state.timer.startedAt,
            accumulatedElapsedBeforeAnchor: priorAccumulated + runFromAnchor,
            pauseStartedAt: at,
            isPaused: true,
            expectedEndAt: state.timer.expectedEndAt,
            stepStartedAt: state.timer.stepStartedAt
        )
        state.phase = .paused
    }

    private func applyResume(_ state: inout WorkoutPlayerSyncState, at: Date) {
        guard state.timer.isPaused else {
            // Common case for "resumed from server-side paused workout":
            // iPhone calls submitResume to bring the player live, but the
            // mesh state was never paused at the engine level (it just
            // went idle → preparing on the first configUpdated). Without
            // this branch the resume event would be silently dropped, the
            // mesh phase would stay `.preparing` forever, and the watch
            // (which uses phase to derive its play/pause icon and timer
            // state) would render the player as paused even though iPhone
            // is running. Flip phase to `.active` without touching the
            // timer anchors — they were already correct from the prior
            // events and don't need rebasing.
            //
            // Defensive guard: never promote from `.idle`. An out-of-order
            // or replayed `resumed` envelope arriving before the workout's
            // `configUpdated` would otherwise silently flip an empty
            // session into `.active`, presenting a UI for a workout that
            // doesn't exist. Sequence ordering on the wire should prevent
            // this in practice, but the reducer is the last guard.
            guard state.phase != .idle else { return }
            if state.phase != .active {
                state.phase = .active
            }
            return
        }
        // Rebase BOTH workout-level `startedAt` AND step-level
        // `stepStartedAt` so peers can compute elapsed without needing a
        // separate "accumulated pause time" field on the wire.
        //
        // For workout level: `startedAt = resumeTime`,
        // `accumulatedElapsedBeforeAnchor` already holds pre-pause run
        // time. So `accumulated + (now - startedAt) = correct workout
        // elapsed`.
        //
        // For step level: capture the pre-pause step elapsed
        // (`pauseStartedAt - oldStepStartedAt`), then set the new
        // `stepStartedAt = resumeTime - prePauseElapsed`. This makes
        // `now - stepStartedAt = prePauseElapsed + (now - resumeTime) =
        // correct step elapsed` — for any peer, just from the wall clock.
        // No `stepTotalPausedTime` to sync.
        let rebasedStepStartedAt: Date?
        if let oldStepStartedAt = state.timer.stepStartedAt {
            let referenceForPrePause = state.timer.pauseStartedAt ?? at
            let stepPrePauseElapsed = max(0, referenceForPrePause.timeIntervalSince(oldStepStartedAt))
            rebasedStepStartedAt = at.addingTimeInterval(-stepPrePauseElapsed)
        } else {
            rebasedStepStartedAt = nil
        }
        state.timer = SessionTimerAnchor(
            startedAt: at,
            accumulatedElapsedBeforeAnchor: state.timer.accumulatedElapsedBeforeAnchor,
            pauseStartedAt: nil,
            isPaused: false,
            expectedEndAt: state.timer.expectedEndAt,
            stepStartedAt: rebasedStepStartedAt
        )
        // Resume from rest goes back to .resting only if we were resting
        // before the pause; otherwise back to active. The reducer doesn't
        // remember pre-pause sub-state explicitly, so the convention is:
        // resume → .active, and the next rest event re-enters `.resting`.
        state.phase = .active
    }

    private func applyStarted(_ state: inout WorkoutPlayerSyncState, at: Date) {
        // Rebase the timer anchor to the actual user-tap moment so peers
        // don't tick from the adapter-boot fallback. Phase flips to active.
        state.timer = SessionTimerAnchor(
            startedAt: at,
            accumulatedElapsedBeforeAnchor: 0,
            pauseStartedAt: nil,
            isPaused: false,
            expectedEndAt: state.timer.expectedEndAt,
            stepStartedAt: at
        )
        state.phase = .active
        state.countdownEndsAt = nil
        // The iPhone clears any pending Watch start request once it has
        // actually started the workout — the request has been honored.
        state.pendingStartRequest = nil
    }

    private func applyStepAdvanced(
        _ state: inout WorkoutPlayerSyncState,
        position: WorkoutPlayerPositionState,
        stepStartedAt: Date
    ) {
        // Preserve any locally-recorded `completedStepIds` that the new
        // position payload doesn't yet include — the canonical owner builds
        // the position from its domain model and may emit before the
        // `stepCompleted` event has rounded back through the engine.
        var nextPosition = position
        for completedId in state.position.completedStepIds where !nextPosition.completedStepIds.contains(completedId) {
            nextPosition.completedStepIds.append(completedId)
        }
        state.position = nextPosition

        // Move the per-step anchor; total-workout `startedAt` stays put. We
        // also leave any `restTimerEndsAt` intact — `restTimerCancelled` is
        // the explicit boundary back to `.active`.
        state.timer = SessionTimerAnchor(
            startedAt: state.timer.startedAt,
            accumulatedElapsedBeforeAnchor: state.timer.accumulatedElapsedBeforeAnchor,
            pauseStartedAt: state.timer.pauseStartedAt,
            isPaused: state.timer.isPaused,
            expectedEndAt: state.timer.expectedEndAt,
            stepStartedAt: stepStartedAt
        )
    }

    private func applyMetrics(
        _ state: inout WorkoutPlayerSyncState,
        heartRate: Double,
        calories: Double,
        totalReps: Int?
    ) {
        if heartRate > 0 { state.metrics.heartRate = heartRate }
        if calories > 0 { state.metrics.activeCalories = calories }
        if let totalReps, totalReps > state.metrics.totalRepsCompleted {
            state.metrics.totalRepsCompleted = totalReps
        }
    }

    private func applyTerminal(
        _ state: inout WorkoutPlayerSyncState,
        at: Date,
        phase: ActivityPhase,
        reason: String?
    ) {
        state.endedAt = at
        state.terminalReason = reason
        state.phase = phase
        state.restTimerEndsAt = nil
        // Freeze the timer at the terminal moment so `elapsed(at: now)` stays
        // stable on the summary view.
        if !state.timer.isPaused {
            let runFromAnchor = max(0, at.timeIntervalSince(state.timer.startedAt))
            state.timer = SessionTimerAnchor(
                startedAt: state.timer.startedAt,
                accumulatedElapsedBeforeAnchor: state.timer.accumulatedElapsedBeforeAnchor + runFromAnchor,
                pauseStartedAt: at,
                isPaused: true,
                expectedEndAt: state.timer.expectedEndAt,
                stepStartedAt: state.timer.stepStartedAt
            )
        }
    }
}
