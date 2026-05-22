import Foundation
import SessionMesh

// MARK: - WorkoutPlayerConflictPolicy

/// Convergence rules for `WorkoutPlayerEvent`. The reducer is idempotent for
/// most event types (a second `paused` is a no-op), but the policy gates
/// edge-case events the reducer can't safely apply.
///
/// Rules:
///
/// 1. Once a terminal phase is recorded (`completed` or `abandoned`),
///    further user-action events are ignored. Late `metricsSampled` is
///    still applied (HK observations may keep arriving for a beat after the
///    user taps Done).
///
/// 2. `requestStart` only applies when the workout is not yet running
///    (idle / preparing). After the workout has started, a duplicate
///    request is dropped — the iPhone has already honored the original.
///
/// 3. When neither side has gone terminal yet, all other events apply. The
///    reducer's idempotent guards take care of repeats.
///
/// 4. Cross-kind terminal races (`completed` vs `abandoned` arriving near
///    simultaneously) resolve by arrival order today. Causal LWW based on
///    `event.occurredAt` vs `lastAppliedMetadata.causalTimestamp` is a
///    follow-up — same gap the activity-player policy has.
///
/// **Known gap (H1 from the SessionMesh migration adversarial review):**
/// LWW is intentional only for the no-conflict case. For two-peer concurrent
/// terminal events (rare in practice — both users tapping Done within ms of
/// each other) the current arrival-order behavior can drop one side's
/// intent. Tracking issue: see PR #410 follow-up list. Implementation
/// sketch: extend `SessionConflictContext` with `lastAppliedMetadata` and
/// gate non-strictly-newer terminal events when one already landed.
public struct WorkoutPlayerConflictPolicy: SessionConflictPolicy {
    public typealias State = WorkoutPlayerSyncState
    public typealias Event = WorkoutPlayerEvent

    public init() { }

    public func shouldApply(
        event: WorkoutPlayerEvent,
        context: SessionConflictContext<WorkoutPlayerSyncState>
    ) -> Bool {
        let alreadyTerminal = context.state.phase == .completed
            || context.state.phase == .abandoned

        // Already terminal: only metrics keep applying so HK samples that
        // arrive after `completed` still update the post-workout summary.
        if alreadyTerminal {
            if case .metricsSampled = event { return true }
            return false
        }

        // `requestStart` is only meaningful before the workout is running.
        // Once `phase.isRunning` is true, the request has either been
        // honored (and `pendingStartRequest` was cleared by `started`) or
        // a different workout has started since — either way drop it.
        if case .requestStart = event, context.state.phase.isRunning {
            return false
        }

        return true
    }
}
