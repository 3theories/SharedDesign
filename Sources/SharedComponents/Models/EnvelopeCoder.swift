import Foundation

// MARK: - DecodedEnvelope

/// Result of decoding wire data that may be either a v2 envelope or a raw v1 payload.
///
/// Senders progressively migrate to v2 (Ship 1 of the watch-sync overhaul). During
/// the rollout, receivers must accept both forms. `metadata` is `nil` for v1
/// payloads — receivers that need epoch/sequence gating should treat that as
/// "trust this once" and avoid sequence-based rejections.
public struct DecodedEnvelope<Payload: Codable & Sendable>: Sendable {
    public let payload: Payload
    public let metadata: ActivityEnvelopeMetadata?

    public var isLegacyV1: Bool { self.metadata == nil }
}

// MARK: - ActivityEnvelopeMetadata

/// Type-erased view of envelope metadata, useful when receivers don't need the
/// generic payload typing for routing/sequence-gating decisions.
public struct ActivityEnvelopeMetadata: Sendable, Equatable {
    public let schemaVersion: Int
    public let epoch: UUID
    public let sequence: UInt64
    public let phase: ActivityPhase
    public let owner: ActivityOwner
    public let emittedAt: Date

    public init(
        schemaVersion: Int,
        epoch: UUID,
        sequence: UInt64,
        phase: ActivityPhase,
        owner: ActivityOwner,
        emittedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.epoch = epoch
        self.sequence = sequence
        self.phase = phase
        self.owner = owner
        self.emittedAt = emittedAt
    }
}

extension ActivityEnvelope {
    public var metadata: ActivityEnvelopeMetadata {
        ActivityEnvelopeMetadata(
            schemaVersion: self.schemaVersion,
            epoch: self.epoch,
            sequence: self.sequence,
            phase: self.phase,
            owner: self.owner,
            emittedAt: self.emittedAt
        )
    }
}

// MARK: - EnvelopeCoder

/// Encodes and decodes the wire data field used by `ConnectivityManager`.
///
/// Wire format during Ship 1 rollout:
///
/// - **v2 (preferred):** JSON-encoded `ActivityEnvelope<Payload>` with `schemaVersion: 2`.
/// - **v1 (legacy):** JSON-encoded `Payload` directly (no envelope).
///
/// Receivers always try v2 first and fall back to v1. This lets the iPhone and
/// Watch be upgraded independently without breaking existing flows.
public enum EnvelopeCoder {
    // MARK: - Encode

    /// Encode a payload as a v2 envelope.
    public static func encode<P: Codable & Sendable>(
        envelope: ActivityEnvelope<P>,
        encoder: JSONEncoder = .activityEnvelopeEncoder
    ) throws -> Data {
        try encoder.encode(envelope)
    }

    /// Encode a payload as a raw v1 blob (no envelope). Provided so call sites that
    /// haven't migrated yet stay byte-compatible during the transition.
    public static func encodeLegacy<P: Codable & Sendable>(
        payload: P,
        encoder: JSONEncoder = .activityEnvelopeEncoder
    ) throws -> Data {
        try encoder.encode(payload)
    }

    // MARK: - Decode

    /// Decode wire data into an envelope + payload. Tries v2 first, falls back to v1.
    /// Throws only if both decodings fail — i.e. the data is genuinely malformed.
    public static func decode<P: Codable & Sendable>(
        _ data: Data,
        as _: P.Type,
        decoder: JSONDecoder = .activityEnvelopeDecoder
    ) throws -> DecodedEnvelope<P> {
        // Try v2 envelope.
        if let envelope = try? decoder.decode(ActivityEnvelope<P>.self, from: data),
           envelope.schemaVersion >= ActivitySchemaVersion.minSupported {
            return DecodedEnvelope(payload: envelope.payload, metadata: envelope.metadata)
        }

        // Fall back to v1 raw payload.
        let payload = try decoder.decode(P.self, from: data)
        return DecodedEnvelope(payload: payload, metadata: nil)
    }

    /// Convenience for receivers that only need the payload and don't care about
    /// envelope metadata — used heavily during Ship 1 to keep call sites short.
    public static func decodePayload<P: Codable & Sendable>(
        _ data: Data,
        as type: P.Type,
        decoder: JSONDecoder = .activityEnvelopeDecoder
    ) throws -> P {
        try self.decode(data, as: type, decoder: decoder).payload
    }
}

// MARK: - Coder defaults

extension JSONEncoder {
    /// Shared encoder used for envelope wire format. Matches the default encoding the
    /// codebase has shipped with so v1 payloads embedded in v2 envelopes remain
    /// byte-compatible with what existing peers produced and consumed.
    public static let activityEnvelopeEncoder: JSONEncoder = JSONEncoder()
}

extension JSONDecoder {
    public static let activityEnvelopeDecoder: JSONDecoder = JSONDecoder()
}
