import Foundation
import SessionMesh

// MARK: - ActivityPlayerReducer

/// Pure reducer applying `ActivityPlayerEvent` to `ActivityPlayerSyncState`.
/// Stays Foundation-only and free of side effects: every transition is a
/// state mutation expressed as a function of the current state + the event.
///
/// Both the iPhone `ActivityPlayerSyncAdapter` and the watch's adapter run
/// the *same* reducer instance, so any sequence of events submitted from
/// either side converges to the same final state. Convergence is what the
/// `SessionSyncEngine` test harness exercises; the reducer is the deterministic
/// piece making that possible.
public struct ActivityPlayerReducer: SessionSyncReducer {
    public typealias State = ActivityPlayerSyncState
    public typealias Event = ActivityPlayerEvent

    public init() { }

    public func reduce(
        state: inout ActivityPlayerSyncState,
        event: ActivityPlayerEvent,
        context _: SessionEventContext
    ) throws {
        // Once terminal, only mutate metrics (HK samples may keep arriving for
        // a beat after `completed`). Everything else is dropped here so a
        // late `paused` doesn't undo `completed`.
        if state.phase == .completed || state.phase == .abandoned {
            if case let .metricsSampled(_, hr, cal, distance, cadence) = event {
                self.applyMetrics(&state, heartRate: hr, calories: cal, distance: distance, cadence: cadence)
            }
            return
        }

        switch event {
        case let .paused(at):
            self.applyPause(&state, at: at)

        case let .resumed(at):
            self.applyResume(&state, at: at)

        case let .lapRecorded(at, distance, heartRate, calories):
            self.applyLap(&state, at: at, distance: distance, heartRate: heartRate, calories: calories)

        case let .setRecorded(at, reps, duration, weight, heartRate, calories):
            self.applySet(
                &state,
                at: at,
                reps: reps,
                duration: duration,
                weight: weight,
                heartRate: heartRate,
                calories: calories
            )

        case let .scoreUpdated(_, userScore, opponentScore, isUserServing, isUserBatting):
            self.applyScore(
                &state,
                userScore: userScore,
                opponentScore: opponentScore,
                isUserServing: isUserServing,
                isUserBatting: isUserBatting
            )

        case let .metricsSampled(_, hr, cal, distance, cadence):
            self.applyMetrics(&state, heartRate: hr, calories: cal, distance: distance, cadence: cadence)

        case let .completed(at):
            self.applyTerminal(&state, at: at, phase: .completed, reason: nil)

        case let .abandoned(at, reason):
            self.applyTerminal(&state, at: at, phase: .abandoned, reason: reason)

        case let .audioStateChanged(_, isPlayingAudio, audioType):
            state.isPlayingAudio = isPlayingAudio
            state.audioType = audioType

        case let .countdownStarted(_, endsAt):
            state.countdownEndsAt = endsAt
            state.phase = .countdown

        case let .phaseChanged(_, phase, continueOnWatch):
            state.phase = phase
            if phase == .closed {
                state.continueOnWatch = continueOnWatch
            }

        case let .started(at):
            // Rebase the timer anchor to the actual user-tap moment so peers
            // don't tick from the adapter-boot fallback. Phase flips to active.
            state.timer = SessionTimerAnchor(
                startedAt: at,
                accumulatedElapsedBeforeAnchor: 0,
                pauseStartedAt: nil,
                isPaused: false,
                expectedEndAt: state.timer.expectedEndAt,
                stepStartedAt: state.timer.stepStartedAt
            )
            state.phase = .active
            state.countdownEndsAt = nil

        case let .periodChanged(_, periodIndex, periodName, engineSnapshot):
            if state.score == nil {
                state.score = ActivityScoreState(
                    userScore: "0",
                    currentPeriodIndex: periodIndex,
                    currentPeriodName: periodName,
                    engineScoreSnapshot: engineSnapshot
                )
            } else {
                state.score?.currentPeriodIndex = periodIndex
                state.score?.currentPeriodName = periodName
                if let engineSnapshot {
                    state.score?.engineScoreSnapshot = engineSnapshot
                }
            }
        }
    }

    // MARK: Private

    private func applyPause(_ state: inout ActivityPlayerSyncState, at: Date) {
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

    private func applyResume(_ state: inout ActivityPlayerSyncState, at: Date) {
        guard state.timer.isPaused else { return }
        state.timer = SessionTimerAnchor(
            startedAt: at,
            accumulatedElapsedBeforeAnchor: state.timer.accumulatedElapsedBeforeAnchor,
            pauseStartedAt: nil,
            isPaused: false,
            expectedEndAt: state.timer.expectedEndAt,
            stepStartedAt: state.timer.stepStartedAt
        )
        state.phase = .active
    }

    private func applyLap(
        _ state: inout ActivityPlayerSyncState,
        at: Date,
        distance: Double?,
        heartRate: Double?,
        calories: Double?
    ) {
        let startTime = state.laps.last?.endTime ?? state.timer.startedAt
        let duration = max(0, at.timeIntervalSince(startTime))
        let lap = LapState(
            lapNumber: state.laps.count + 1,
            startTime: startTime,
            endTime: at,
            duration: duration,
            distance: distance,
            averageHeartRate: heartRate,
            calories: calories
        )
        state.laps.append(lap)
    }

    private func applySet(
        _ state: inout ActivityPlayerSyncState,
        at: Date,
        reps: Int?,
        duration: TimeInterval?,
        weight: Double?,
        heartRate: Double?,
        calories: Double?
    ) {
        let set = SetState(
            setNumber: state.sets.count + 1,
            completedAt: at,
            reps: reps,
            duration: duration,
            weight: weight,
            averageHeartRate: heartRate,
            calories: calories
        )
        state.sets.append(set)
    }

    private func applyScore(
        _ state: inout ActivityPlayerSyncState,
        userScore: String,
        opponentScore: String?,
        isUserServing: Bool?,
        isUserBatting: Bool?
    ) {
        if state.score == nil {
            state.score = ActivityScoreState(
                userScore: userScore,
                opponentScore: opponentScore,
                isUserServing: isUserServing,
                isUserBatting: isUserBatting
            )
        } else {
            state.score?.userScore = userScore
            state.score?.opponentScore = opponentScore
            if let isUserServing { state.score?.isUserServing = isUserServing }
            if let isUserBatting { state.score?.isUserBatting = isUserBatting }
        }
    }

    private func applyMetrics(
        _ state: inout ActivityPlayerSyncState,
        heartRate: Double,
        calories: Double,
        distance: Double?,
        cadence: Double?
    ) {
        if heartRate > 0 { state.metrics.heartRate = heartRate }
        if calories > 0 { state.metrics.activeCalories = calories }
        if let distance, distance > 0 { state.metrics.distance = distance }
        if let cadence, cadence > 0 { state.metrics.cadence = cadence }
    }

    private func applyTerminal(
        _ state: inout ActivityPlayerSyncState,
        at: Date,
        phase: ActivityPhase,
        reason: String?
    ) {
        state.endedAt = at
        state.terminalReason = reason
        state.phase = phase
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
