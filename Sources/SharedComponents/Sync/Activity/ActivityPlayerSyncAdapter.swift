import Foundation
import os
import SessionMesh

private let log = Logger(subsystem: "com.niora.sessionmesh", category: "ActivityPlayerSyncAdapter")

// MARK: - ActivityPlayerSyncAdapter

/// MainActor-bound bridge between an `ActivityPlayerViewModel` (or the watch's
/// equivalent manager) and the generic `SessionSyncEngine`. Owns:
///
/// - the engine instance for this session
/// - the transport (`WatchConnectivitySessionSyncTransport` in production,
///   `LoopbackSessionSyncTransport` in tests, `ScenarioSessionSyncTransport`
///   for deterministic convergence harnesses)
/// - the receive-loop tasks (envelopes, snapshots, snapshot requests,
///   reachability changes)
///
/// VMs interact with this object — they don't import `SessionMesh` directly.
/// Local user actions become `ActivityPlayerEvent` cases via `submitX(at:)`
/// methods; remote events flow through the engine and surface via the
/// observable `state` and `phase` properties.
@MainActor
public final class ActivityPlayerSyncAdapter: ObservableObject {
    // MARK: Lifecycle

    public init(
        sessionID: UUID,
        localPeer: SessionPeer,
        transport: any SessionSyncTransport,
        initialState: ActivityPlayerSyncState
    ) {
        self.sessionID = sessionID
        self.localPeer = localPeer
        self.transport = transport
        self.engine = SessionSyncEngine(
            sessionID: sessionID,
            featureID: Self.featureID,
            localPeerID: localPeer.id,
            payloadType: Self.eventPayloadType,
            snapshotPayloadType: Self.snapshotPayloadType,
            initialState: initialState,
            reducer: ActivityPlayerReducer(),
            conflictPolicy: ActivityPlayerConflictPolicy()
        )
        self.state = initialState
    }

    deinit {
        self.envelopeTask?.cancel()
        self.snapshotTask?.cancel()
        self.requestTask?.cancel()
        self.reachabilityTask?.cancel()
    }

    // MARK: Public

    /// Stable identifier consumers use to register payload codecs and
    /// recognize this feature on the wire. Matches the engine's `featureID`.
    public static let featureID = "activity-player"

    /// Wire-level type tag for `ActivityPlayerEvent`.
    public static let eventPayloadType = "ActivityPlayerEvent"

    /// Wire-level type tag for `ActivityPlayerSyncState` snapshots.
    public static let snapshotPayloadType = "ActivityPlayerSyncState"

    public let sessionID: UUID
    public let localPeer: SessionPeer

    /// The reduced state. SwiftUI views bind to this — every applied event
    /// (local or remote) re-publishes.
    @Published public private(set) var state: ActivityPlayerSyncState

    /// Fires when a *remote* peer's event has been applied. The owning VM /
    /// manager mirrors the event into its local UI state (e.g. flips
    /// `activityState.isPaused`) without re-submitting through the adapter,
    /// avoiding the echo. Local submits update `state` synchronously and do
    /// NOT trigger this callback.
    public var onRemoteEvent: ((ActivityPlayerEvent) -> Void)?

    /// Fires when a *remote* snapshot has been applied (peer hydration on
    /// wake/foreground). Owning code uses this to bootstrap UI state from
    /// the snapshot when joining mid-activity. Local snapshot publishes
    /// don't trigger it.
    public var onRemoteSnapshot: ((ActivityPlayerSyncState) -> Void)?

    /// Convenience: the current activity phase. Equivalent to `state.phase`.
    public var phase: ActivityPhase { self.state.phase }

    /// Whether the activity has reached a terminal phase. After this flips
    /// to `true`, further `submit` calls are no-ops (the reducer + policy
    /// drop late non-metric events).
    public var isTerminal: Bool {
        self.state.phase == .completed || self.state.phase == .abandoned
    }

    /// Begin consuming remote envelopes / snapshots / requests / reachability
    /// from the transport. Call once after init. Idempotent — calling again
    /// while already running is a no-op.
    public func start() {
        guard self.envelopeTask == nil else { return }
        self.envelopeTask = Task { [weak self] in await self?.consumeEnvelopes() }
        self.snapshotTask = Task { [weak self] in await self?.consumeSnapshots() }
        self.requestTask = Task { [weak self] in await self?.consumeSnapshotRequests() }
        self.reachabilityTask = Task { [weak self] in await self?.consumeReachability() }
    }

    /// Cancel the receive loops. Call from VM cleanup. After `stop()`, the
    /// adapter no longer reflects remote events.
    public func stop() {
        self.envelopeTask?.cancel()
        self.snapshotTask?.cancel()
        self.requestTask?.cancel()
        self.reachabilityTask?.cancel()
        self.envelopeTask = nil
        self.snapshotTask = nil
        self.requestTask = nil
        self.reachabilityTask = nil
    }

    // MARK: - Local user actions

    public func submitPause(at timestamp: Date = Date()) async throws {
        try await self.submit(.paused(at: timestamp), at: timestamp)
    }

    public func submitResume(at timestamp: Date = Date()) async throws {
        try await self.submit(.resumed(at: timestamp), at: timestamp)
    }

    public func submitLap(
        at timestamp: Date = Date(),
        distance: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    ) async throws {
        try await self.submit(
            .lapRecorded(at: timestamp, distance: distance, heartRate: heartRate, calories: calories),
            at: timestamp
        )
    }

    public func submitSet(
        at timestamp: Date = Date(),
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        weight: Double? = nil,
        heartRate: Double? = nil,
        calories: Double? = nil
    ) async throws {
        try await self.submit(
            .setRecorded(
                at: timestamp,
                reps: reps,
                duration: duration,
                weight: weight,
                heartRate: heartRate,
                calories: calories
            ),
            at: timestamp
        )
    }

    public func submitScore(
        at timestamp: Date = Date(),
        userScore: String,
        opponentScore: String? = nil,
        isUserServing: Bool? = nil,
        isUserBatting: Bool? = nil
    ) async throws {
        try await self.submit(
            .scoreUpdated(
                at: timestamp,
                userScore: userScore,
                opponentScore: opponentScore,
                isUserServing: isUserServing,
                isUserBatting: isUserBatting
            ),
            at: timestamp
        )
    }

    public func submitMetricsSample(
        at timestamp: Date = Date(),
        heartRate: Double,
        calories: Double,
        distance: Double? = nil,
        cadence: Double? = nil
    ) async throws {
        try await self.submit(
            .metricsSampled(
                at: timestamp,
                heartRate: heartRate,
                calories: calories,
                distance: distance,
                cadence: cadence
            ),
            at: timestamp
        )
    }

    public func submitCompleted(at timestamp: Date = Date()) async throws {
        try await self.submit(.completed(at: timestamp), at: timestamp)
    }

    public func submitAbandoned(at timestamp: Date = Date(), reason: String? = nil) async throws {
        try await self.submit(.abandoned(at: timestamp, reason: reason), at: timestamp)
    }

    public func submitAudioState(
        at timestamp: Date = Date(),
        isPlayingAudio: Bool,
        audioType: String? = nil
    ) async throws {
        try await self.submit(
            .audioStateChanged(at: timestamp, isPlayingAudio: isPlayingAudio, audioType: audioType),
            at: timestamp
        )
    }

    public func submitCountdownStarted(
        at timestamp: Date = Date(),
        endsAt: Date
    ) async throws {
        try await self.submit(.countdownStarted(at: timestamp, endsAt: endsAt), at: timestamp)
    }

    public func submitPhaseChange(
        at timestamp: Date = Date(),
        phase: ActivityPhase,
        continueOnWatch: Bool = false
    ) async throws {
        try await self.submit(
            .phaseChanged(at: timestamp, phase: phase, continueOnWatch: continueOnWatch),
            at: timestamp
        )
    }

    /// Mark the activity as actually started (user-tap moment after any
    /// preparing / countdown buffer). Rebases the timer anchor to `timestamp`
    /// so peers tick from the same wall-clock instant.
    public func submitStarted(at timestamp: Date = Date()) async throws {
        try await self.submit(.started(at: timestamp), at: timestamp)
    }

    public func submitPeriodChanged(
        at timestamp: Date = Date(),
        currentPeriodIndex: Int,
        currentPeriodName: String? = nil,
        engineScoreSnapshot: EngineScoreSnapshot? = nil
    ) async throws {
        try await self.submit(
            .periodChanged(
                at: timestamp,
                currentPeriodIndex: currentPeriodIndex,
                currentPeriodName: currentPeriodName,
                engineScoreSnapshot: engineScoreSnapshot
            ),
            at: timestamp
        )
    }

    /// Generic submit that doesn't pick the timestamp for you. Useful when
    /// the VM has captured an exact tap moment somewhere upstream and wants
    /// to thread it all the way through.
    public func submit(_ event: ActivityPlayerEvent, at timestamp: Date) async throws {
        // Local apply: the engine reduces synchronously, returns the envelope
        // to ship. Publishing local state immediately keeps the iPhone UI
        // responsive without waiting for the watch's echo (the optimistic
        // pattern we ended up hand-rolling in the previous architecture).
        let envelope = try self.engine.submitLocal(event, at: timestamp)
        self.state = self.engine.state

        let erased = try AnySessionSyncEnvelope(envelope)
        let mode = self.deliveryMode(for: event)
        do {
            try await self.transport.send(erased, mode: mode, to: nil)
        } catch {
            log.error("adapter.submit transport.send failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public) seq=\(envelope.metadata.sequence, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Refresh the applicationContext snapshot so peers waking up
        // mid-activity hydrate with current state instead of the boot-time
        // snapshot. `updateApplicationContext` replaces (doesn't queue), so
        // many calls in a row coalesce to the last value.
        //
        // High-frequency events (`metricsSampled`) skip this — the metrics
        // are best-effort and would drown the WC serialization queue.
        if !event.isMetric {
            try await self.publishLatestSnapshot()
        }
    }

    /// Send the current state as a snapshot via the transport's
    /// "latestSnapshot" channel. Peers that wake up mid-session use this to
    /// hydrate without replaying the full event log.
    public func publishLatestSnapshot() async throws {
        let snapshot = self.makeOutgoingSnapshot()
        let erased = try AnySessionSyncSnapshot(snapshot)
        try await self.transport.sendSnapshot(erased, mode: .latestSnapshot, to: nil)
    }

    /// Fire-and-forget wrapper for VM/manager call sites that can't `await`
    /// (synchronous UI handlers, `Task {}` enqueues). Routes any thrown
    /// error to `os.Logger` with the call-site label so silent drops surface
    /// in Console.app instead of disappearing under `try?`.
    public func fireAndForget(
        label: String,
        operation: @escaping (ActivityPlayerSyncAdapter) async throws -> Void
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operation(self)
            } catch {
                log.error("\(label, privacy: .public) failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: Internal

    typealias Engine = SessionSyncEngine<
        ActivityPlayerSyncState,
        ActivityPlayerEvent,
        ActivityPlayerReducer,
        ActivityPlayerConflictPolicy
    >

    // MARK: Private

    private var engine: Engine
    private let transport: any SessionSyncTransport
    private var envelopeTask: Task<Void, Never>?
    private var snapshotTask: Task<Void, Never>?
    private var requestTask: Task<Void, Never>?
    private var reachabilityTask: Task<Void, Never>?
    /// Defense-in-depth gate against stale `applicationContext`
    /// snapshots. Plan §C4.
    private let snapshotIntakePolicy = SnapshotIntakePolicy()

    private func consumeEnvelopes() async {
        for await raw in self.transport.receiveEnvelopes() {
            guard self.matches(metadata: raw.metadata) else { continue }
            guard raw.metadata.sourcePeerID != self.localPeer.id else { continue }
            do {
                let envelope = try raw.decoded(as: ActivityPlayerEvent.self)
                let result = try self.engine.receive(envelope)
                self.handle(receiveResult: result)
                if case .applied = result {
                    self.onRemoteEvent?(envelope.payload)
                }
            } catch {
                log.error("adapter.recv decode/apply failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public) seq=\(raw.metadata.sequence, privacy: .public): \(error.localizedDescription, privacy: .public)")
                continue
            }
        }
    }

    private func consumeSnapshots() async {
        for await raw in self.transport.receiveSnapshots() {
            guard self.matches(metadata: raw.metadata) else { continue }
            // Skip own echoes — local snapshot publishes shouldn't fire the
            // remote-snapshot callback.
            guard raw.metadata.sourcePeerID != self.localPeer.id else { continue }
            do {
                let snapshot = try raw.decoded(as: ActivityPlayerSyncState.self)
                // Reject stale `applicationContext` replays so a force-
                // quit session can't resurrect after relaunch. Plan §C4.
                let decision = self.snapshotIntakePolicy.shouldApply(
                    metadata: snapshot.metadata,
                    statePhase: snapshot.state.phase
                )
                switch decision {
                case let .rejectStale(age):
                    log.info("activity snapshot rejected as stale age=\(Int(age), privacy: .public)s session=\(self.sessionID.uuidString.prefix(8), privacy: .public)")
                    continue
                case .rejectIdle:
                    log.info("activity snapshot rejected as idle session=\(self.sessionID.uuidString.prefix(8), privacy: .public)")
                    continue
                case .apply:
                    break
                }
                let result = try self.engine.applySnapshot(snapshot)
                if case let .applied(state) = result {
                    self.state = state
                    self.onRemoteSnapshot?(state)
                }
            } catch {
                log.error("activity snapshot decode/apply failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public): \(String(describing: error), privacy: .public)")
                continue
            }
        }
    }

    private func consumeSnapshotRequests() async {
        for await request in self.transport.receiveSnapshotRequests() {
            guard request.sessionID == self.sessionID else { continue }
            // Don't fail the loop on a transport hiccup — log-and-continue.
            try? await self.publishLatestSnapshot()
        }
    }

    private func consumeReachability() async {
        for await change in self.transport.reachabilityChanges() {
            guard change.isReachable else { continue }
            // Best-effort republish so a peer that just came back online
            // hydrates from latest state without us waiting for the next
            // user action.
            try? await self.publishLatestSnapshot()
        }
    }

    private func handle(receiveResult result: SessionSyncReceiveResult<ActivityPlayerSyncState>) {
        switch result {
        case let .applied(state):
            self.state = state
        case .duplicate, .ignored:
            // Both leave state unchanged.
            break
        case .snapshotRequired:
            // The peer is ahead of us by more than one envelope; ask them
            // for a fresh snapshot instead of replaying. Fire-and-forget —
            // if it fails, the next peer-side action will republish anyway.
            Task { [transport, sessionID] in
                try? await transport.requestSnapshot(sessionID: sessionID, from: nil)
            }
        }
    }

    private func makeOutgoingSnapshot() -> SessionSyncSnapshot<ActivityPlayerSyncState> {
        let metadata = SessionSyncMetadata(
            sessionID: self.sessionID,
            featureID: Self.featureID,
            sourcePeerID: self.localPeer.id,
            sequence: self.engine.store.nextLocalSequence,
            causalTimestamp: Date(),
            payloadType: Self.snapshotPayloadType
        )
        return SessionSyncSnapshot(
            metadata: metadata,
            revision: self.engine.allocateOutgoingSnapshotRevision(),
            state: self.engine.state,
            peerSequenceVector: self.engine.store.lastSequenceByPeerID
        )
    }

    private func matches(metadata: SessionSyncMetadata) -> Bool {
        metadata.sessionID == self.sessionID && metadata.featureID == Self.featureID
    }

    /// Per-event delivery mode. Despite the name, `.realtimeBestEffort` is the
    /// right mode for *all* user-action events: the WC transport sends via
    /// live `sendMessage` if the peer is reachable, then automatically falls
    /// back to `transferUserInfo` on failure or when unreachable. The
    /// "best-effort" name refers to live-wire success — durability is still
    /// guaranteed by the userInfo fallback.
    ///
    /// `.reliableEventually` ALWAYS uses `transferUserInfo` even when the
    /// peer is reachable (queued, async, ~seconds latency) — it's the wrong
    /// fit for interactive events the user expects to apply immediately.
    private func deliveryMode(for _: ActivityPlayerEvent) -> SessionDeliveryMode {
        .realtimeBestEffort
    }
}

// MARK: - AnySessionSyncEnvelope helpers

private extension AnySessionSyncEnvelope {
    func decoded(as eventType: ActivityPlayerEvent.Type) throws -> SessionSyncEnvelope<ActivityPlayerEvent> {
        let payload = try self.decodePayload(as: eventType)
        return SessionSyncEnvelope(metadata: self.metadata, payload: payload)
    }
}

private extension AnySessionSyncSnapshot {
    func decoded(
        as stateType: ActivityPlayerSyncState.Type
    ) throws -> SessionSyncSnapshot<ActivityPlayerSyncState> {
        let state = try self.decodeState(as: stateType)
        return SessionSyncSnapshot(
            metadata: self.metadata,
            revision: self.revision,
            state: state,
            peerSequenceVector: self.peerSequenceVector
        )
    }
}
