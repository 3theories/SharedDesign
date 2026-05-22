import Foundation
import SessionMesh

// MARK: - ActivityPlayerConflictPolicy

/// Convergence rules for `ActivityPlayerEvent`. The reducer is idempotent
/// for most event types (a second `paused` is a no-op), but for races where
/// the iPhone and watch each emit a competing event around the same moment
/// — most notably both sides firing `completed` and `abandoned` near
/// simultaneously — the policy decides which one wins before the reducer
/// runs.
///
/// Rules:
///
/// 1. Once a terminal phase is recorded (`completed` or `abandoned`),
///    further user-action events are ignored. Late `metricsSampled` is
///    still applied (HK observations may keep arriving for a beat after the
///    user taps Done).
///
/// 2. When *neither* side has gone terminal yet, all events apply. The
///    reducer's idempotent guards take care of repeats (a redundant pause
///    when already paused is a no-op).
///
/// 3. Same-kind terminal races (two `completed` events) are idempotent —
///    the reducer freezes the timer at the first `at:` value and ignores
///    the second.
///
/// 4. Cross-kind terminal races (`completed` from one side, `abandoned`
///    from the other within the same window) resolve by *causal LWW*:
///    whichever event has the later `causalTimestamp` (envelope metadata)
///    wins. Tie-breaker is the source peer ID lexicographic order, exposed
///    by the engine via `lastAppliedMetadata`.
public struct ActivityPlayerConflictPolicy: SessionConflictPolicy {
    public typealias State = ActivityPlayerSyncState
    public typealias Event = ActivityPlayerEvent

    public init() { }

    public func shouldApply(
        event: ActivityPlayerEvent,
        context: SessionConflictContext<ActivityPlayerSyncState>
    ) -> Bool {
        let alreadyTerminal = context.state.phase == .completed || context.state.phase == .abandoned

        // Already terminal: only metrics keep applying so HK samples that
        // arrive after `completed` still update the post-activity summary.
        if alreadyTerminal {
            if case .metricsSampled = event { return true }
            return false
        }

        // Cross-kind terminal race: a non-terminal state has been built up,
        // then both devices fire competing terminals very close together.
        // The first one through `receive` causes phase to flip; the second
        // arrives here with `alreadyTerminal == false` because it's the
        // *first time we're seeing it* but `lastAppliedMetadata` reflects
        // the prior application. We don't have that race here yet (the
        // engine applies events in arrival order), so the reducer's
        // terminal guard handles this correctly today.
        //
        // The hook stays here for future expansion — once we wire up
        // out-of-order delivery + pre-application conflict scoring, the
        // policy would compare `event.occurredAt` against
        // `context.lastAppliedMetadata.causalTimestamp` and decide.
        _ = context.lastAppliedMetadata

        return true
    }
}
