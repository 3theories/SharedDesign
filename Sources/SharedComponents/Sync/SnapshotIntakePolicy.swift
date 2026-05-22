import Foundation
import SessionMesh

// MARK: - SnapshotIntakePolicy

/// Adapter-level intake gate shared by `WorkoutPlayerSyncAdapter` and
/// `ActivityPlayerSyncAdapter`.
///
/// `applicationContext` is OS-persisted across app launches. When the
/// iPhone-side player dies without firing a terminal envelope (force
/// quit, crash, OOM), the OS keeps serving the last "live" snapshot
/// to the watch on every cold launch — sometimes hours or days
/// later. The bridge's `handlePeer*Snapshot` paths filter this for
/// UI-hydration purposes, but the adapter consumes the same wire in
/// parallel and was previously letting the engine absorb the stale
/// state. Plan §C4 — defense in depth at the adapter layer.
public struct SnapshotIntakePolicy: Sendable, Equatable {
    // MARK: Lifecycle

    public init(staleness: TimeInterval = 5 * 60) {
        self.staleness = staleness
    }

    // MARK: Public

    public enum Decision: Equatable, Sendable {
        case apply
        /// Snapshot's `causalTimestamp` is older than the staleness
        /// budget — almost certainly a leftover from a force-quit
        /// session that the OS keeps replaying.
        case rejectStale(age: TimeInterval)
        /// Phase is `.idle` — there's no active session in the peer's
        /// model. Applying this would zero out a freshly-started local
        /// session if the timing were unlucky.
        case rejectIdle
    }

    /// 5 minutes by default — generous enough for screen-lock /
    /// out-of-range disconnects, short enough that yesterday's
    /// killed session can't hijack a fresh app launch.
    public let staleness: TimeInterval

    public func shouldApply(
        metadata: SessionSyncMetadata,
        statePhase: ActivityPhase,
        now: Date = Date()
    ) -> Decision {
        // Evaluation order matters and is load-bearing:
        //
        //   1. Staleness wins first. A `.completed` snapshot from 3 hours
        //      ago is rejected as stale before we look at its phase — we
        //      do NOT want to apply terminal events from yesterday's
        //      force-quit session just because they happen to be
        //      terminal.
        //   2. `.idle` is rejected next — it's "no active session" and
        //      applying it would zero out a freshly-started local one.
        //   3. Everything else passes — including non-stale terminal
        //      phases (`.completed`, `.abandoned`, `.closed`). Those are
        //      meaningful state transitions the peer is genuinely
        //      communicating, not stale resurrection. The bridge's
        //      UI-hydration handler filters terminal phases separately;
        //      the engine should still see them so the local state
        //      machine converges.
        //
        // Note on clock drift: this is a wall-clock comparison and
        // iPhone↔Watch clocks can drift by a few seconds. With a 5-minute
        // window that's well within tolerance; if the staleness budget
        // is ever tightened below ~1 minute, revisit using a monotonic
        // sequence-based check instead.
        let age = now.timeIntervalSince(metadata.causalTimestamp)
        if age > self.staleness {
            return .rejectStale(age: age)
        }
        if statePhase == .idle {
            return .rejectIdle
        }
        return .apply
    }
}

// MARK: - Backwards-compatibility alias

/// Existing callers used the workout-scoped name; preserved as an
/// alias so the rename doesn't ripple. New code should use
/// `SnapshotIntakePolicy` directly.
public typealias WorkoutSnapshotIntakePolicy = SnapshotIntakePolicy
