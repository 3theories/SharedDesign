import Foundation
import SessionMesh
#if canImport(WatchConnectivity)
    import SessionMeshWatchConnectivity
#endif
#if os(watchOS)
    import WatchKit
#elseif os(iOS)
    import UIKit
#endif

// MARK: - ActivityPlayerSyncBridge

/// App-scope singleton that owns the `WatchConnectivitySessionSyncTransport`
/// used by every `ActivityPlayerSyncAdapter`. The transport is process-scoped
/// (one WCSession per app, one set of receive streams) so we instantiate it
/// once at first access and hand it to each VM-owned adapter.
///
/// On iOS/watchOS the bridge constructs a real `WatchConnectivitySessionSyncTransport`
/// against `WCSession.default`; on macOS / SPM build environments without
/// WatchConnectivity it falls back to a no-op transport so SharedComponents
/// stays buildable in the package's macOS target (used for previews / tests).
public final class ActivityPlayerSyncBridge: @unchecked Sendable {
    // MARK: Public

    public static let shared = ActivityPlayerSyncBridge()

    /// Stable peer identifier for the local device. Same value across the
    /// app's lifetime so the session sync engine's per-peer sequence
    /// tracking is meaningful — `vendor identifier` would change on reinstall
    /// but stays stable for the duration of a normal session.
    public let localPeer: SessionPeer

    /// The single transport instance shared across all activity adapters.
    /// Tests can substitute via `setOverrideTransportForTesting(_:)`.
    public var transport: any SessionSyncTransport {
        self.lock.withLock { self.activeTransport }
    }

    /// Construct an adapter for an activity session. The adapter shares the
    /// bridge's process-scoped transport and uses the bridge's `localPeer`
    /// as its source identity. MainActor-bound because the adapter itself
    /// runs there (callers are typically VMs / managers on the main actor).
    @MainActor
    public func makeAdapter(
        sessionID: UUID,
        initialState: ActivityPlayerSyncState
    ) -> ActivityPlayerSyncAdapter {
        ActivityPlayerSyncAdapter(
            sessionID: sessionID,
            localPeer: self.localPeer,
            transport: self.transport,
            initialState: initialState
        )
    }

    /// Mesh-native session discovery: read the canonical peer's most recent
    /// SessionMesh snapshot (sitting in the transport's recovery substrate
    /// — applicationContext on WatchConnectivity) and return its
    /// `sessionID`.
    ///
    /// A joiner peer (e.g. iPhone opening the player to view a watch-started
    /// activity) calls this *before* constructing its adapter, so both
    /// peers' adapters agree on the session UUID. Returns `nil` when no
    /// peer snapshot exists yet — caller falls back to a fresh UUID and
    /// becomes the canonical peer for that activity instance.
    public func discoverActiveSessionID(featureID: String = ActivityPlayerSyncAdapter.featureID) -> UUID? {
        self.transport.latestPeerSnapshot(featureID: featureID)?.metadata.sessionID
    }

    /// Read the current peer activity-player snapshot from the transport's
    /// recovery substrate (applicationContext on WatchConnectivity), if any.
    /// App-level consumers like `ActiveActivityService` use this to detect
    /// "is the watch in an activity?" without owning a `SessionSyncEngine`.
    public func latestPeerActivityState() -> ActivityPlayerSyncState? {
        guard let raw = self.transport.latestPeerSnapshot(featureID: ActivityPlayerSyncAdapter.featureID),
              let state = try? raw.decodeState(as: ActivityPlayerSyncState.self)
        else {
            return nil
        }
        return state
    }

    /// Same as `latestPeerActivityState()` but returns the full
    /// `PeerActivitySnapshot` (state + wire metadata). Lets joining peers
    /// adopt the canonical `sessionID` when bootstrapping their adapter
    /// from applicationContext that arrived before they subscribed.
    public func latestPeerActivitySnapshot() -> PeerActivitySnapshot? {
        guard let raw = self.transport.latestPeerSnapshot(featureID: ActivityPlayerSyncAdapter.featureID),
              let state = try? raw.decodeState(as: ActivityPlayerSyncState.self)
        else {
            return nil
        }
        return PeerActivitySnapshot(
            state: state,
            sessionID: raw.metadata.sessionID,
            sequence: raw.metadata.sequence,
            sourcePeerID: raw.metadata.sourcePeerID,
            causalTimestamp: raw.metadata.causalTimestamp
        )
    }

    /// Snapshot delivered to a `subscribeToPeerActivitySnapshots` handler.
    /// Carries the wire metadata (sessionID, sequence, sourcePeerID) so the
    /// consumer can build a properly-gated `ActivityEnvelope` without
    /// fabricating identifiers.
    public struct PeerActivitySnapshot: Sendable {
        public let state: ActivityPlayerSyncState
        public let sessionID: UUID
        public let sequence: UInt64
        public let sourcePeerID: String
        public let causalTimestamp: Date
    }

    /// Subscribe to incoming peer activity-player snapshots. Each snapshot
    /// arrives via the transport's recovery substrate (applicationContext)
    /// or the live snapshot wire. Used by `ActiveActivityService` to react
    /// to watch-started activities without per-VM adapter wiring.
    ///
    /// The returned task should be cancelled when the consumer goes away.
    @discardableResult
    public func subscribeToPeerActivitySnapshots(
        _ handler: @escaping @Sendable (PeerActivitySnapshot) -> Void
    ) -> Task<Void, Never> {
        let stream = self.transport.receiveSnapshots()
        let localPeerID = self.localPeer.id
        let featureID = ActivityPlayerSyncAdapter.featureID
        return Task { [stream] in
            for await raw in stream {
                guard raw.metadata.featureID == featureID else { continue }
                guard raw.metadata.sourcePeerID != localPeerID else { continue }
                guard let state = try? raw.decodeState(as: ActivityPlayerSyncState.self) else {
                    continue
                }
                handler(
                    PeerActivitySnapshot(
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

    /// Test-only seam — swap in a `LoopbackSessionSyncTransport` /
    /// `ScenarioSessionSyncTransport` for deterministic VM-level tests.
    /// Not for production callers.
    public func setOverrideTransportForTesting(_ transport: any SessionSyncTransport) {
        self.lock.withLock { self.activeTransport = transport }
    }

    /// Restore the bridge's default WatchConnectivity transport after a
    /// test override. No-op when no override was applied.
    public func clearOverrideTransportForTesting() {
        self.lock.withLock { self.activeTransport = self.defaultTransport }
    }

    // MARK: Private

    private let lock = NSLock()
    private let defaultTransport: any SessionSyncTransport
    private var activeTransport: any SessionSyncTransport

    private init() {
        let peer = Self.makeLocalPeer()
        self.localPeer = peer
        let transport = Self.makeDefaultTransport(localPeer: peer)
        self.defaultTransport = transport
        self.activeTransport = transport
    }

    private static func makeLocalPeer() -> SessionPeer {
        let id = Self.persistentDeviceID()
        let deviceClass: SessionPeerDeviceClass = {
            #if os(watchOS)
                return .watch
            #elseif os(iOS)
                return .phone
            #else
                return .unknown
            #endif
        }()
        return SessionPeer(
            id: id,
            deviceClass: deviceClass,
            appInstanceID: id,
            topology: .pairedCompanion
        )
    }

    /// Stable per-install device identifier. Survives app launches but resets
    /// on uninstall — fine for `SessionSyncEngine.localPeerID` which only
    /// needs to be unique-per-device for the lifetime of a session.
    private static func persistentDeviceID() -> String {
        let key = "com.niora.sessionMesh.localPeerID"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }

    private static func makeDefaultTransport(localPeer: SessionPeer) -> any SessionSyncTransport {
        #if canImport(WatchConnectivity)
            // Force `ConnectivityManager` to claim the `WCSession.default`
            // delegate slot *before* the transport's init runs, so the
            // transport's `forwardingDelegate` captures `ConnectivityManager`
            // and not nil. Without this nudge, on the watch the bridge can
            // boot before any other code has touched `ConnectivityManager.shared`
            // — the resulting `forwardingDelegate = nil` silently drops every
            // non-mesh WCSession message (the workout player's legacy wires,
            // auth/fasting/nutrition updates, etc.).
            _ = ConnectivityManager.shared
            return WatchConnectivitySessionSyncTransport(localPeer: localPeer)
        #else
            return NoopSessionSyncTransport(localPeer: localPeer)
        #endif
    }
}

// MARK: - NoopSessionSyncTransport

/// Fallback transport for build environments without WatchConnectivity (the
/// package's macOS target used by previews / SPM builds). Conforms to the
/// protocol but moves no bytes — adapters constructed against it will run
/// the engine locally only.
private final class NoopSessionSyncTransport: SessionSyncTransport, @unchecked Sendable {
    init(localPeer: SessionPeer) {
        self.localPeer = localPeer
    }

    let localPeer: SessionPeer
    var knownPeers: [SessionPeer] { [] }
    let capabilities = SessionTransportCapabilities(
        supportsRealtime: false,
        supportsDurableQueue: false,
        supportsLatestStateReplacement: false,
        supportsRequestReply: false,
        supportsBroadcast: false,
        supportsPeerDiscovery: false,
        maximumPayloadSize: 0,
        expectedLatency: .eventual
    )

    func send(_: AnySessionSyncEnvelope, mode _: SessionDeliveryMode, to _: SessionPeer?) async throws { }
    func sendSnapshot(_: AnySessionSyncSnapshot, mode _: SessionDeliveryMode, to _: SessionPeer?) async throws { }
    func requestSnapshot(sessionID _: UUID, from _: SessionPeer?) async throws { }
    func receiveEnvelopes() -> AsyncStream<AnySessionSyncEnvelope> { AsyncStream { _ in } }
    func receiveSnapshots() -> AsyncStream<AnySessionSyncSnapshot> { AsyncStream { _ in } }
    func receiveSnapshotRequests() -> AsyncStream<SessionSnapshotRequest> { AsyncStream { _ in } }
    func reachabilityChanges() -> AsyncStream<SessionPeerReachability> { AsyncStream { _ in } }
}
