import Foundation
import os
import SessionMesh

private let log = Logger(subsystem: "com.niora.sessionmesh", category: "WorkoutPlayerSyncAdapter")

// MARK: - WorkoutPlayerSyncAdapter

/// MainActor-bound bridge between a `WorkoutActivityPlayerViewModel` (or the
/// watch's `WatchWorkoutManager`) and the generic `SessionSyncEngine`. Mirrors
/// `ActivityPlayerSyncAdapter` exactly — same lifecycle, same error logging,
/// same fireAndForget helper. The only differences are the feature ID, the
/// state / event types, and the workout-specific submit methods.
///
/// VMs interact with this object — they don't import `SessionMesh` directly.
@MainActor
public final class WorkoutPlayerSyncAdapter: ObservableObject {
    // MARK: Lifecycle

    public init(
        sessionID: UUID,
        localPeer: SessionPeer,
        transport: any SessionSyncTransport,
        initialState: WorkoutPlayerSyncState
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
            reducer: WorkoutPlayerReducer(),
            conflictPolicy: WorkoutPlayerConflictPolicy()
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
    /// recognize this feature on the wire. Must be different from the
    /// activity player's ID so the two adapters can share one transport.
    public static let featureID = "workout-player"

    /// Wire-level type tag for `WorkoutPlayerEvent`.
    public static let eventPayloadType = "WorkoutPlayerEvent"

    /// Wire-level type tag for `WorkoutPlayerSyncState` snapshots.
    public static let snapshotPayloadType = "WorkoutPlayerSyncState"

    public let sessionID: UUID
    public let localPeer: SessionPeer

    /// The reduced state. SwiftUI views bind to this — every applied event
    /// (local or remote) re-publishes.
    @Published public private(set) var state: WorkoutPlayerSyncState

    /// Fires when a *remote* peer's event has been applied. The owning VM /
    /// manager mirrors the event into its local UI state without re-submitting
    /// through the adapter, avoiding the echo. Local submits update `state`
    /// synchronously and do NOT trigger this callback.
    public var onRemoteEvent: ((WorkoutPlayerEvent) -> Void)?

    /// Fires when a *remote* snapshot has been applied (peer hydration on
    /// wake/foreground). Owning code uses this to bootstrap UI state from
    /// the snapshot when joining mid-workout.
    public var onRemoteSnapshot: ((WorkoutPlayerSyncState) -> Void)?

    /// Convenience: the current workout phase. Equivalent to `state.phase`.
    public var phase: ActivityPhase { self.state.phase }

    /// Whether the workout has reached a terminal phase. After this flips
    /// to `true`, further `submit` calls are no-ops at the reducer level.
    public var isTerminal: Bool {
        self.state.phase == .completed || self.state.phase == .abandoned
    }

    /// Begin consuming remote envelopes / snapshots / requests / reachability
    /// from the transport. Call once after init. Idempotent.
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

    public func submitStarted(at timestamp: Date = Date()) async throws {
        try await self.submit(.started(at: timestamp), at: timestamp)
    }

    public func submitConfigUpdated(
        at timestamp: Date = Date(),
        config: WorkoutPlayerSessionConfig
    ) async throws {
        try await self.submit(.configUpdated(at: timestamp, config: config), at: timestamp)
    }

    public func submitCompleted(at timestamp: Date = Date()) async throws {
        try await self.submit(.completed(at: timestamp), at: timestamp)
    }

    public func submitAbandoned(at timestamp: Date = Date(), reason: String? = nil) async throws {
        try await self.submit(.abandoned(at: timestamp, reason: reason), at: timestamp)
    }

    public func submitStepAdvanced(
        at timestamp: Date = Date(),
        position: WorkoutPlayerPositionState,
        stepStartedAt: Date
    ) async throws {
        try await self.submit(
            .stepAdvanced(at: timestamp, position: position, stepStartedAt: stepStartedAt),
            at: timestamp
        )
    }

    public func submitStepCompleted(
        at timestamp: Date = Date(),
        stepId: UUID,
        repsCompleted: Int? = nil,
        weight: Double? = nil
    ) async throws {
        try await self.submit(
            .stepCompleted(at: timestamp, stepId: stepId, repsCompleted: repsCompleted, weight: weight),
            at: timestamp
        )
    }

    public func submitRestTimerStarted(
        at timestamp: Date = Date(),
        endsAt: Date
    ) async throws {
        try await self.submit(.restTimerStarted(at: timestamp, endsAt: endsAt), at: timestamp)
    }

    public func submitRestTimerCancelled(at timestamp: Date = Date()) async throws {
        try await self.submit(.restTimerCancelled(at: timestamp), at: timestamp)
    }

    public func submitTransitionStarted(
        at timestamp: Date = Date(),
        endsAt: Date
    ) async throws {
        try await self.submit(.transitionStarted(at: timestamp, endsAt: endsAt), at: timestamp)
    }

    public func submitTransitionEnded(at timestamp: Date = Date()) async throws {
        try await self.submit(.transitionEnded(at: timestamp), at: timestamp)
    }

    public func submitMetricsSample(
        at timestamp: Date = Date(),
        heartRate: Double,
        calories: Double,
        totalRepsCompleted: Int? = nil
    ) async throws {
        try await self.submit(
            .metricsSampled(
                at: timestamp,
                heartRate: heartRate,
                calories: calories,
                totalRepsCompleted: totalRepsCompleted
            ),
            at: timestamp
        )
    }

    public func submitAudioState(
        at timestamp: Date = Date(),
        isPlayingPriorityAudio: Bool,
        priorityAudioType: String? = nil,
        isPreparingAudio: Bool = false
    ) async throws {
        try await self.submit(
            .audioStateChanged(
                at: timestamp,
                isPlayingPriorityAudio: isPlayingPriorityAudio,
                priorityAudioType: priorityAudioType,
                isPreparingAudio: isPreparingAudio
            ),
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

    /// Watch-side helper for the scheduled-today start handshake.
    public func submitRequestStart(
        at timestamp: Date = Date(),
        scheduledActivityId: UUID
    ) async throws {
        try await self.submit(
            .requestStart(
                at: timestamp,
                scheduledActivityId: scheduledActivityId,
                requestedByPeerID: self.localPeer.id
            ),
            at: timestamp
        )
    }

    /// Watch-side helper for the next-step intent. Replaces the legacy
    /// `WatchHealthKitManager.sendNavigationEvent(.navigateToNext(...))`
    /// HK-channel wire (Plan §C5+C6).
    public func submitRequestNextStep(at timestamp: Date = Date()) async throws {
        try await self.submit(.requestNextStep(at: timestamp), at: timestamp)
    }

    /// Watch-side helper for the jump-to-step intent. Replaces the legacy
    /// `WatchHealthKitManager.sendNavigationEvent(.jumpToStep(...))`
    /// HK-channel wire (Plan §C5+C6).
    public func submitRequestJumpToStep(
        at timestamp: Date = Date(),
        roundIndex: Int,
        setIndex: Int
    ) async throws {
        try await self.submit(
            .requestJumpToStep(at: timestamp, roundIndex: roundIndex, setIndex: setIndex),
            at: timestamp
        )
    }

    /// Generic submit. Apply locally (so the originating UI updates
    /// instantly), ship the envelope, then republish the snapshot for
    /// non-metric events so cold-launching peers hydrate fresh.
    public func submit(_ event: WorkoutPlayerEvent, at timestamp: Date) async throws {
        let envelope = try self.engine.submitLocal(event, at: timestamp)
        self.state = self.engine.state

        let erased = try AnySessionSyncEnvelope(envelope)
        let mode = self.deliveryMode(for: event)
        do {
            try await self.transport.send(erased, mode: mode, to: nil)
        } catch {
            log.error("submit transport.send failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public) seq=\(envelope.metadata.sequence, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }

        if !event.isMetric {
            try await self.publishLatestSnapshot()
        }
    }

    /// Send the current state as a snapshot via the transport's
    /// "latestSnapshot" channel. Peers that wake up mid-workout use this to
    /// hydrate without replaying the full event log.
    public func publishLatestSnapshot() async throws {
        let snapshot = self.makeOutgoingSnapshot()
        let erased = try AnySessionSyncSnapshot(snapshot)
        try await self.transport.sendSnapshot(erased, mode: .latestSnapshot, to: nil)
    }

    /// Fire-and-forget wrapper for VM/manager call sites that can't `await`.
    /// Routes any thrown error to `os.Logger` with the call-site label so
    /// silent drops surface in Console.app.
    public func fireAndForget(
        label: String,
        operation: @escaping (WorkoutPlayerSyncAdapter) async throws -> Void
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
        WorkoutPlayerSyncState,
        WorkoutPlayerEvent,
        WorkoutPlayerReducer,
        WorkoutPlayerConflictPolicy
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
    private let snapshotIntakePolicy = WorkoutSnapshotIntakePolicy()

    private func consumeEnvelopes() async {
        for await raw in self.transport.receiveEnvelopes() {
            guard self.matches(metadata: raw.metadata) else { continue }
            guard raw.metadata.sourcePeerID != self.localPeer.id else { continue }
            do {
                let envelope = try raw.decoded(as: WorkoutPlayerEvent.self)
                let result = try self.engine.receive(envelope)
                self.handle(receiveResult: result)
                if case .applied = result {
                    self.onRemoteEvent?(envelope.payload)
                }
            } catch {
                log.error("recv decode/apply failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public) seq=\(raw.metadata.sequence, privacy: .public): \(error.localizedDescription, privacy: .public)")
                continue
            }
        }
    }

    private func consumeSnapshots() async {
        for await raw in self.transport.receiveSnapshots() {
            guard self.matches(metadata: raw.metadata) else { continue }
            guard raw.metadata.sourcePeerID != self.localPeer.id else { continue }
            do {
                let snapshot = try raw.decoded(as: WorkoutPlayerSyncState.self)
                // Adapter-level intake gate. Without this, a force-quit
                // workout's stale `applicationContext` snapshot — which
                // the OS replays on every cold launch — gets absorbed
                // by the engine and resurrects the dead workout. The
                // bridge's UI-hydration handler had its own guard, but
                // the engine ran in parallel and bypassed it. Plan §C4.
                let decision = self.snapshotIntakePolicy.shouldApply(
                    metadata: snapshot.metadata,
                    statePhase: snapshot.state.phase
                )
                switch decision {
                case let .rejectStale(age):
                    log.info("snapshot rejected as stale age=\(Int(age), privacy: .public)s session=\(self.sessionID.uuidString.prefix(8), privacy: .public)")
                    continue
                case .rejectIdle:
                    log.info("snapshot rejected as idle session=\(self.sessionID.uuidString.prefix(8), privacy: .public)")
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
                log.error("snapshot decode/apply failed for session=\(self.sessionID.uuidString.prefix(8), privacy: .public): \(String(describing: error), privacy: .public)")
                continue
            }
        }
    }

    private func consumeSnapshotRequests() async {
        for await request in self.transport.receiveSnapshotRequests() {
            guard request.sessionID == self.sessionID else { continue }
            try? await self.publishLatestSnapshot()
        }
    }

    private func consumeReachability() async {
        for await change in self.transport.reachabilityChanges() {
            guard change.isReachable else { continue }
            try? await self.publishLatestSnapshot()
        }
    }

    private func handle(receiveResult result: SessionSyncReceiveResult<WorkoutPlayerSyncState>) {
        switch result {
        case let .applied(state):
            self.state = state
        case .duplicate, .ignored:
            break
        case .snapshotRequired:
            Task { [transport, sessionID] in
                try? await transport.requestSnapshot(sessionID: sessionID, from: nil)
            }
        }
    }

    private func makeOutgoingSnapshot() -> SessionSyncSnapshot<WorkoutPlayerSyncState> {
        let now = Date()
        let metadata = SessionSyncMetadata(
            sessionID: self.sessionID,
            featureID: Self.featureID,
            sourcePeerID: self.localPeer.id,
            sequence: self.engine.store.nextLocalSequence,
            causalTimestamp: now,
            payloadType: Self.snapshotPayloadType
        )
        return SessionSyncSnapshot(
            metadata: metadata,
            revision: self.engine.allocateOutgoingSnapshotRevision(),
            // Normalize phase + anchors so the published snapshot is
            // internally consistent at `now`. The reducer stores phase
            // and time anchors independently; they can briefly disagree
            // between an anchor expiring and the next phase-transition
            // event firing. Publishing the inconsistent state put the
            // watch's view selector into "Connecting…" at the moment
            // the pre-start countdown finished. See
            // `WorkoutPlayerSyncState.normalizedForWire(at:)`.
            state: self.engine.state.normalizedForWire(at: now),
            peerSequenceVector: self.engine.store.lastSequenceByPeerID
        )
    }

    private func matches(metadata: SessionSyncMetadata) -> Bool {
        metadata.sessionID == self.sessionID && metadata.featureID == Self.featureID
    }

    /// Per-event delivery mode. `.realtimeBestEffort` is the right mode for
    /// every workout event — the WC transport sends via live `sendMessage`
    /// if the peer is reachable and falls back to `transferUserInfo` on
    /// failure. See the activity adapter for the full reasoning; same trade.
    private func deliveryMode(for _: WorkoutPlayerEvent) -> SessionDeliveryMode {
        .realtimeBestEffort
    }
}

// MARK: - AnySessionSyncEnvelope helpers

private extension AnySessionSyncEnvelope {
    func decoded(as eventType: WorkoutPlayerEvent.Type) throws -> SessionSyncEnvelope<WorkoutPlayerEvent> {
        let payload = try self.decodePayload(as: eventType)
        return SessionSyncEnvelope(metadata: self.metadata, payload: payload)
    }
}

private extension AnySessionSyncSnapshot {
    func decoded(
        as stateType: WorkoutPlayerSyncState.Type
    ) throws -> SessionSyncSnapshot<WorkoutPlayerSyncState> {
        let state = try self.decodeState(as: stateType)
        return SessionSyncSnapshot(
            metadata: self.metadata,
            revision: self.revision,
            state: state,
            peerSequenceVector: self.peerSequenceVector
        )
    }
}
