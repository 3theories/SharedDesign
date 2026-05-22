import Foundation

// MARK: - IncomingMessageBus

/// Serial dispatcher that gates incoming envelopes by `(epoch, type, sequence)`.
///
/// The previous design fanned out every WCSession delegate callback into an
/// independent `Task { @MainActor in ... }`. That gave SwiftUI a stream of
/// updates with no ordering guarantee — a `paused` envelope emitted at
/// sequence 5 could land *after* `resumed` from sequence 6 if the runtime
/// happened to schedule them in that order. The bus serializes processing
/// and rejects anything older than what we've already applied.
///
/// Use:
/// ```swift
/// let bus = IncomingMessageBus()
/// await bus.register(handler: { [weak self] env in
///     self?.applyFastingUpdate(env)
/// }, for: .fastingUpdate)
///
/// // Inside WCSession delegate:
/// await bus.process(rawData, type: .fastingUpdate, as: FastingStatusDTO.self)
/// ```
public actor IncomingMessageBus {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    /// Register an async handler that receives decoded envelopes in arrival order.
    /// Only v2 envelopes flow through the bus; legacy v1 raw payloads continue to
    /// arrive via `ConnectivityManager`'s `messageHandlers` path.
    public func register<P: Codable & Sendable>(
        for type: MessageType,
        as _: P.Type,
        handler: @escaping @Sendable (ActivityEnvelope<P>) async -> Void
    ) {
        self.handlers[type] = { data in
            guard let envelope = try? JSONDecoder().decode(ActivityEnvelope<P>.self, from: data) else {
                return
            }
            await handler(envelope)
        }
    }

    public func unregister(for type: MessageType) {
        self.handlers[type] = nil
        self.lastSequence[type] = nil
        self.lastEpoch[type] = nil
    }

    /// Process raw envelope bytes for `type`. Drops the message if its
    /// `(epoch, sequence)` is older than what's been applied.
    public func process(_ data: Data, type: MessageType) async {
        guard let handler = handlers[type] else { return }

        // Read metadata cheaply via the full envelope decode helper.
        guard let decoded = try? EnvelopeCoder.decode(data, as: PassthroughPayload.self),
              let metadata = decoded.metadata else {
            // v1 raw or missing metadata: outside the bus's responsibility.
            return
        }

        // Sequence gate.
        if let priorEpoch = lastEpoch[type], priorEpoch == metadata.epoch {
            if let priorSequence = lastSequence[type], metadata.sequence <= priorSequence {
                // Out-of-order or duplicate within the same epoch.
                return
            }
        } else {
            // New epoch supersedes any previous one for this type.
            self.lastEpoch[type] = metadata.epoch
            self.lastSequence[type] = nil
        }

        self.lastSequence[type] = metadata.sequence
        await handler(data)
    }

    // MARK: Private

    /// Type-erased handler keyed by message type. The closure decodes the
    /// envelope to its concrete payload internally.
    private var handlers: [MessageType: @Sendable (Data) async -> Void] = [:]

    private var lastSequence: [MessageType: UInt64] = [:]
    private var lastEpoch: [MessageType: UUID] = [:]
}

// MARK: - PassthroughPayload

/// Marker payload used by the bus when it only needs the envelope's metadata
/// (epoch / sequence) for gating, not the inner payload. Decodes any JSON value
/// into an opaque container — used so `EnvelopeCoder.decode` can succeed
/// regardless of the actual payload schema.
struct PassthroughPayload: Codable, Sendable {
    init(from _: Decoder) throws {}
    func encode(to _: Encoder) throws {}
}
