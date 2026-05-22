import Foundation
import SessionMesh

// MARK: - WorkoutPlayerSyncBridge

/// App-scope singleton vending `WorkoutPlayerSyncAdapter` instances.
///
/// Unlike the per-process `WCSession`, multiple SessionMesh features can
/// share one transport — each adapter filters by `featureID`. So this
/// bridge does NOT construct its own `WatchConnectivitySessionSyncTransport`;
/// instead it borrows the transport (and `localPeer`) that
/// `ActivityPlayerSyncBridge.shared` already owns. The activity bridge is
/// effectively the host for the single `WCSession.default` delegate.
///
/// If we ever ship a third mesh feature, the right refactor is to extract a
/// neutral `MeshTransportHub` singleton both bridges read from. Until then,
/// borrowing keeps the surface area small.
public final class WorkoutPlayerSyncBridge: @unchecked Sendable {
    // MARK: Public

    public static let shared = WorkoutPlayerSyncBridge()

    /// Borrowed from `ActivityPlayerSyncBridge` — same physical device, same
    /// peer identity across every mesh feature.
    public var localPeer: SessionPeer {
        ActivityPlayerSyncBridge.shared.localPeer
    }

    /// Borrowed from `ActivityPlayerSyncBridge`. Test overrides applied to
    /// the activity bridge automatically apply here too.
    public var transport: any SessionSyncTransport {
        ActivityPlayerSyncBridge.shared.transport
    }

    /// Construct an adapter for a workout session. Same shape as
    /// `ActivityPlayerSyncBridge.makeAdapter` — caller supplies the
    /// `sessionID` (the per-workout epoch) and the initial state, the
    /// bridge wires up the engine + transport.
    @MainActor
    public func makeAdapter(
        sessionID: UUID,
        initialState: WorkoutPlayerSyncState
    ) -> WorkoutPlayerSyncAdapter {
        WorkoutPlayerSyncAdapter(
            sessionID: sessionID,
            localPeer: self.localPeer,
            transport: self.transport,
            initialState: initialState
        )
    }

    /// Mesh-native session discovery: read the canonical peer's most recent
    /// workout snapshot from the transport's recovery substrate
    /// (applicationContext on WatchConnectivity) and return its `sessionID`.
    ///
    /// A joiner peer (e.g. iPhone foregrounding to a watch-started workout —
    /// once we extend Phase A to standalone-watch-run, Phase B) calls this
    /// before constructing its adapter so both peers' adapters agree on the
    /// session UUID. Returns `nil` when no peer snapshot exists yet.
    public func discoverActiveSessionID(
        featureID: String = WorkoutPlayerSyncAdapter.featureID
    ) -> UUID? {
        self.transport.latestPeerSnapshot(featureID: featureID)?.metadata.sessionID
    }

    /// Read the current peer workout snapshot from the transport's recovery
    /// substrate, if any. App-level consumers (e.g. an `ActiveWorkoutService`
    /// equivalent) use this to detect "is the watch-side already in a
    /// workout?" without owning a `SessionSyncEngine`.
    public func latestPeerWorkoutState() -> WorkoutPlayerSyncState? {
        guard let raw = self.transport.latestPeerSnapshot(featureID: WorkoutPlayerSyncAdapter.featureID),
              let state = try? raw.decodeState(as: WorkoutPlayerSyncState.self)
        else {
            return nil
        }
        return state
    }

    /// Same as `latestPeerWorkoutState()`, but returns the full
    /// `PeerWorkoutSnapshot` (state + wire metadata) so callers can adopt
    /// the `sessionID` when bootstrapping their own adapter. Used when the
    /// watch app launches mid-iPhone-workout: the transport already holds
    /// the latest applicationContext, but the live snapshot stream won't
    /// re-deliver it because that delivery happened before the consumer
    /// subscribed.
    public func latestPeerWorkoutSnapshot() -> PeerWorkoutSnapshot? {
        guard let raw = self.transport.latestPeerSnapshot(featureID: WorkoutPlayerSyncAdapter.featureID),
              let state = try? raw.decodeState(as: WorkoutPlayerSyncState.self)
        else {
            return nil
        }
        return PeerWorkoutSnapshot(
            state: state,
            sessionID: raw.metadata.sessionID,
            sequence: raw.metadata.sequence,
            sourcePeerID: raw.metadata.sourcePeerID,
            causalTimestamp: raw.metadata.causalTimestamp
        )
    }

    /// Snapshot delivered to a `subscribeToPeerWorkoutSnapshots` handler.
    /// Carries wire metadata so the consumer has the real `sessionID` /
    /// `sequence` instead of having to fabricate identifiers.
    public struct PeerWorkoutSnapshot: Sendable {
        public let state: WorkoutPlayerSyncState
        public let sessionID: UUID
        public let sequence: UInt64
        public let sourcePeerID: String
        public let causalTimestamp: Date
    }

    /// Subscribe to incoming peer workout-player snapshots. Each snapshot
    /// arrives via the transport's recovery substrate or live snapshot wire.
    /// Used by app-level consumers that want to react to peer state without
    /// owning their own adapter — e.g. an iPhone-side service that observes
    /// a Watch-published `pendingStartRequest` and foregrounds the player.
    ///
    /// The returned task should be cancelled when the consumer goes away.
    @discardableResult
    public func subscribeToPeerWorkoutSnapshots(
        _ handler: @escaping @Sendable (PeerWorkoutSnapshot) -> Void
    ) -> Task<Void, Never> {
        let stream = self.transport.receiveSnapshots()
        let localPeerID = self.localPeer.id
        let featureID = WorkoutPlayerSyncAdapter.featureID
        return Task { [stream] in
            for await raw in stream {
                guard raw.metadata.featureID == featureID else { continue }
                guard raw.metadata.sourcePeerID != localPeerID else { continue }
                guard let state = try? raw.decodeState(as: WorkoutPlayerSyncState.self) else {
                    continue
                }
                handler(
                    PeerWorkoutSnapshot(
                        state: state,
                        sessionID: raw.metadata.sessionID,
                        sequence: raw.metadata.sequence,
                        sourcePeerID: raw.metadata.sourcePeerID,
                        causalTimestamp: raw.metadata.causalTimestamp
                    )
                )
            }
        }
    }

    // MARK: Private

    private init() { }
}
