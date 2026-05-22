import Foundation
#if canImport(WatchConnectivity)
    import WatchConnectivity
#endif
import SwiftData

// MARK: - ObserverToken

/// Opaque handle returned by `addObserver` / `addSnapshotObserver`. Identity-equatable
/// so callers can hold onto it and remove their observer later.
public final class ObserverToken: Hashable {
    public init() {}
    public static func == (lhs: ObserverToken, rhs: ObserverToken) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

// MARK: - ConnectivityManager

public class ConnectivityManager: NSObject, ObservableObject {
    // MARK: Lifecycle

    private override init() {
        #if canImport(WatchConnectivity)
            self.session = WCSession.default
        #endif
        super.init()

        #if canImport(WatchConnectivity)
            if WCSession.isSupported() {
                self.session.delegate = self
                self.session.activate()
            } else {
                print("ConnectivityManager: ❌ WCSession is not supported on this device")
            }
        #endif
    }

    // MARK: Public

    public static let shared = ConnectivityManager()

    @Published public var isReachable = false
    @Published public var isCompanionAppInstalled = false

    /// Schema version the peer device most recently advertised. `nil` until the first
    /// handshake completes.
    ///
    /// See ``ActivitySchemaVersion``. This drives version-mismatch UX (e.g. an
    /// "update your companion app" banner) once both sides ship Ship 1.
    @Published public var peerSchemaVersion: Int?

    /// `true` when the peer's advertised schema is older than what this build can
    /// understand. UI surfaces should prompt the user to update the companion app.
    @Published public var requiresCompanionUpdate: Bool = false

    #if canImport(WatchConnectivity)
        public private(set) var session: WCSession
    #endif

    // MARK: - Registration

    public func registerHandler(for type: MessageType, handler: @escaping (Any) -> Void) {
        self.messageHandlers[type] = handler
    }

    public func unregisterHandler(for type: MessageType) {
        self.messageHandlers[type] = nil
    }

    /// Register handler for Watch requests (iOS only)
    public func registerRequestHandler(for type: MessageType, handler: @escaping () async -> Codable?) {
        self.requestHandlers[type] = handler
    }

    // MARK: - Sending

    public func send(_ data: Codable, type: MessageType) {
        do {
            let message = try Self.encodeWireMessage(data, type: type)
            self.dispatchOrEnqueue(message: message, type: type, mode: .fireAndForget)
        } catch {
            print("ConnectivityManager: Error encoding data: \(error)")
        }
    }

    /// Send data with fallback to transferUserInfo when not reachable
    /// Use this for important initial sync data that MUST reach the Watch
    /// (e.g., activity sync data when launching Watch app)
    public func sendWithFallback(_ data: Codable, type: MessageType) {
        do {
            let message = try Self.encodeWireMessage(data, type: type)
            self.dispatchOrEnqueue(message: message, type: type, mode: .reliable)
        } catch {
            print("ConnectivityManager: Error encoding data: \(error)")
        }
    }

    // MARK: - Requesting

    public func requestUpdate(for type: MessageType) {
        guard self.session.activationState == .activated else {
            print("ConnectivityManager: Session not activated")
            return
        }

        let message = ["request": type.rawValue]

        if self.session.isReachable {
            print("ConnectivityManager: Requesting update for type: \(type)")
            self.session.sendMessage(message, replyHandler: { [weak self] response in
                print("ConnectivityManager: Received response for \(type)")

                guard let typeString = response["type"] as? String,
                      let messageType = MessageType(rawValue: typeString) else {
                    print("ConnectivityManager: Invalid type in response - \(response)")
                    return
                }

                // Extract data - it might be Data, NSData, or _NSInlineData
                let data: Data?
                if let directData = response["data"] as? Data {
                    data = directData
                } else if let nsData = response["data"] as? NSData {
                    data = nsData as Data
                } else if let anyData = response["data"] {
                    // Handle _NSInlineData or other data variants
                    data = anyData as? Data
                } else {
                    data = nil
                }

                guard let finalData = data, let handler = self?.messageHandlers[messageType] else {
                    print("ConnectivityManager: No data or handler for \(messageType)")
                    return
                }

                print(
                    "ConnectivityManager: Processing response data for type: \(messageType), size: \(finalData.count) bytes"
                )
                Task { @MainActor in
                    handler(finalData)
                }
            }) { error in
                print("ConnectivityManager: Error requesting update: \(error)")
            }
        }
    }

    // MARK: - Send queue

    /// Transport semantics requested by the caller.
    public enum SendMode: Sendable {
        /// `WCSession.sendMessage` only — dropped if the peer is unreachable. Used
        /// for high-frequency live ticks (heart rate, position) where missing one
        /// update is fine.
        case fireAndForget

        /// `sendMessage` if reachable, otherwise queue via `transferUserInfo` so the
        /// peer eventually receives it. Used for must-deliver state changes
        /// (start, pause, complete).
        case reliable
    }

    private struct PendingSend {
        let type: MessageType
        let mode: SendMode
        let message: [String: Any]
    }

    private static func encodeWireMessage(_ data: Codable, type: MessageType) throws -> [String: Any] {
        let messageData: Data =
            if let existingData = data as? Data {
                existingData
            } else {
                try JSONEncoder().encode(data)
            }

        return [
            "type": type.rawValue,
            "data": messageData
        ]
    }

    /// Either dispatches the message immediately if the WCSession is activated, or
    /// buffers it until activation completes. Eliminates the silent drop that
    /// caused "stuck initializing" when sends raced session activation.
    private func dispatchOrEnqueue(message: [String: Any], type: MessageType, mode: SendMode) {
        #if canImport(WatchConnectivity)
            self.pendingSendsLock.lock()
            let activated = self.session.activationState == .activated
            if !activated {
                self.pendingSends.append(PendingSend(type: type, mode: mode, message: message))
                self.pendingSendsLock.unlock()
                print("ConnectivityManager: ⏳ Buffered \(type) (\(mode)) — session not activated yet")
                return
            }
            self.pendingSendsLock.unlock()
        #endif

        self.dispatchSend(message: message, type: type, mode: mode)
    }

    private func dispatchSend(message: [String: Any], type: MessageType, mode: SendMode) {
        #if canImport(WatchConnectivity)
            switch mode {
            case .fireAndForget:
                if self.session.isReachable {
                    print("ConnectivityManager: Sending data for type: \(type)")
                    self.session.sendMessage(message, replyHandler: nil) { error in
                        print("ConnectivityManager: Error sending message: \(error)")
                    }
                } else {
                    print("ConnectivityManager: Session not reachable, dropping fire-and-forget (type: \(type))")
                }

            case .reliable:
                print("ConnectivityManager: Sending data with fallback for type: \(type)")
                if self.session.isReachable {
                    self.session.sendMessage(message, replyHandler: nil) { [weak self] error in
                        print("ConnectivityManager: Error sending, falling back to transferUserInfo: \(error)")
                        self?.session.transferUserInfo(message)
                    }
                } else {
                    print("ConnectivityManager: Session not reachable, queuing via transferUserInfo (type: \(type))")
                    self.session.transferUserInfo(message)
                }
            }
        #endif
    }

    /// Atomically take the queued sends and clear the buffer.
    private func drainPendingSends() -> [PendingSend] {
        self.pendingSendsLock.lock()
        defer { self.pendingSendsLock.unlock() }
        let drained = self.pendingSends
        self.pendingSends.removeAll()
        return drained
    }

    private func flushPendingSends() {
        let drained = self.drainPendingSends()
        guard !drained.isEmpty else { return }
        print("ConnectivityManager: 🚿 Flushing \(drained.count) buffered send(s) after activation")
        for item in drained {
            self.dispatchSend(message: item.message, type: item.type, mode: item.mode)
        }
    }

    // MARK: - Envelope-aware sending (Ship 3+)

    /// Send a versioned envelope via the activation queue. Identical wire format to
    /// `send`/`sendWithFallback` (still goes in the `data` field), but the payload
    /// is the JSON-encoded `ActivityEnvelope<P>` so receivers can sequence-gate.
    public func sendEnvelope<P: Codable & Sendable>(
        _ envelope: ActivityEnvelope<P>,
        type: MessageType,
        mode: SendMode = .reliable
    ) {
        do {
            let data = try EnvelopeCoder.encode(envelope: envelope)
            let message = try Self.encodeWireMessage(data, type: type)
            self.dispatchOrEnqueue(message: message, type: type, mode: mode)
        } catch {
            print("ConnectivityManager: ❌ sendEnvelope encode failed: \(error)")
        }
    }

    /// Publish the latest snapshot to `applicationContext`. This is the *recovery
    /// substrate* that lets a peer hydrate state on cold launch / foreground without
    /// waiting for a live message.
    ///
    /// - Latest-wins per type. Subsequent calls overwrite the value for the same
    ///   `type` key in the application context dictionary.
    /// - Coexists with the schema-version handshake key (does not overwrite it).
    /// - **Never use this for live ticks** (heart rate, position). WatchOS heavily
    ///   coalesces application context updates; high-frequency writes are dropped.
    public func publishSnapshot<P: Codable & Sendable>(
        _ envelope: ActivityEnvelope<P>,
        type: MessageType
    ) {
        do {
            let data = try EnvelopeCoder.encode(envelope: envelope)
            self.mergeIntoApplicationContext([
                Self.snapshotKey(for: type): data
            ])
        } catch {
            print("ConnectivityManager: ❌ publishSnapshot encode failed: \(error)")
        }
    }

    /// Convention for embedding a snapshot's data under a stable key in the
    /// application context dictionary.
    public static func snapshotKey(for type: MessageType) -> String {
        "snapshot.\(type.rawValue)"
    }

    // MARK: - Schema handshake

    /// Wire key used to advertise the local build's envelope schema version inside
    /// the application context.
    public static let schemaVersionContextKey = "envelopeSchemaVersion"

    /// Merge the given keys into our `applicationContext`. Preserves any other keys
    /// already present (e.g. snapshot state once Ship 2 lands).
    ///
    /// `WCSession.updateApplicationContext` replaces the whole context, so we read
    /// the current local context first and merge into it.
    public func mergeIntoApplicationContext(_ keys: [String: Any]) {
        #if canImport(WatchConnectivity)
            guard self.session.activationState == .activated else { return }
            var merged = self.session.applicationContext
            for (key, value) in keys {
                merged[key] = value
            }
            do {
                try self.session.updateApplicationContext(merged)
            } catch {
                print("ConnectivityManager: ❌ updateApplicationContext failed: \(error)")
            }
        #endif
    }

    /// Record the peer's advertised schema version and update the
    /// `requiresCompanionUpdate` flag.
    @MainActor
    private func recordPeerSchemaVersion(_ version: Int) {
        self.peerSchemaVersion = version
        // Peer advertises the highest schema *they* can produce. If that's lower
        // than what we require, our build can't reliably decode them anymore.
        self.requiresCompanionUpdate = version < ActivitySchemaVersion.minSupported
    }

    private func advertiseLocalSchemaVersion() {
        self.mergeIntoApplicationContext([
            Self.schemaVersionContextKey: ActivitySchemaVersion.current
        ])
    }

    // MARK: Private

    private var messageHandlers: [MessageType: (Any) -> Void] = [:]
    private var messageObservers: [MessageType: [ObserverToken: (Any) -> Void]] = [:]
    private var requestHandlers: [MessageType: () async -> Codable?] = [:]
    private var snapshotHandlers: [MessageType: (Data) -> Void] = [:]
    private var snapshotObservers: [MessageType: [ObserverToken: (Data) -> Void]] = [:]

    /// Sends queued while the WCSession is not yet `.activated`. Drained on
    /// `activationDidCompleteWith` in arrival order.
    private var pendingSends: [PendingSend] = []
    private let pendingSendsLock = NSLock()

    // MARK: - Message Handling

    private func handleMessage(_ message: [String: Any]) {
        // First check if this is a request message
        if let requestType = message["request"] as? String,
           let type = MessageType(rawValue: requestType),
           let handler = messageHandlers[type] {
            print("ConnectivityManager: Handling request message for type: \(type)")
            handler(message)
            return
        }

        // Then handle regular messages
        guard let messageType = message["type"] as? String,
              let type = MessageType(rawValue: messageType) else {
            print("ConnectivityManager: Invalid message format - keys: \(message.keys)")
            return
        }

        // Extract data - it might be Data, NSData, or _NSInlineData (especially from transferUserInfo)
        let data: Data?
        if let directData = message["data"] as? Data {
            data = directData
        } else if let nsData = message["data"] as? NSData {
            data = nsData as Data
        } else if let anyData = message["data"] {
            // Handle _NSInlineData or other data variants
            data = anyData as? Data
        } else {
            data = nil
        }

        guard let finalData = data else {
            print("ConnectivityManager: No data for type: \(type)")
            return
        }
        let primary = messageHandlers[type]
        let observers = Array(messageObservers[type, default: [:]].values)
        guard primary != nil || !observers.isEmpty else {
            print("ConnectivityManager: No handler/observers for type: \(type)")
            return
        }

        print("[SYNC_DEBUG] ConnectivityManager: Handling message type: \(type), data size: \(finalData.count) bytes")
        Task { @MainActor in
            primary?(finalData)
            for observer in observers {
                observer(finalData)
            }
        }
    }

    private func handleRequest(_ requestType: MessageType, replyHandler: @escaping ([String: Any]) -> Void) async {
        print("ConnectivityManager: Handling request for type: \(requestType)")

        guard let handler = requestHandlers[requestType] else {
            print("ConnectivityManager: No handler registered for request type: \(requestType)")
            replyHandler([:])
            return
        }

        // Call the handler to fetch data
        if let data = await handler() {
            do {
                let encodedData = try JSONEncoder().encode(data)
                let response: [String: Any] = [
                    "type": requestType.rawValue,
                    "data": encodedData
                ]
                print(
                    "ConnectivityManager: Sending response for \(requestType) with data size: \(encodedData.count) bytes"
                )
                replyHandler(response)
            } catch {
                print("ConnectivityManager: Error encoding response data: \(error)")
                replyHandler([:])
            }
        } else {
            print("ConnectivityManager: Handler returned nil for \(requestType)")
            replyHandler([:])
        }
    }
}

// MARK: WCSessionDelegate

extension ConnectivityManager: WCSessionDelegate {
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                print("ConnectivityManager: ❌ Session activation failed: \(error)")
                return
            }

            print("ConnectivityManager: ✅ Session activated with state: \(activationState.rawValue)")
            print("ConnectivityManager: isReachable: \(session.isReachable)")

            #if os(iOS)
                print("ConnectivityManager: [iOS] Watch app installed: \(session.isWatchAppInstalled)")
                print("ConnectivityManager: [iOS] Paired watch: \(session.isPaired ? "Yes" : "No")")
                if !session.isPaired {
                    print(
                        "ConnectivityManager: ⚠️ [iOS] Watch is not paired! Please pair your Apple Watch in the Watch app."
                    )
                }

                // Note: we deliberately do NOT cancel `outstandingUserInfoTransfers`
                // here. The previous version cancelled them to avoid noisy wake-ups
                // when the watch came online, but this also dropped legitimate state
                // updates queued before activation — the root cause of the
                // "watch stuck initializing" bug. Sequence-gating on the receiver
                // (Ship 4) handles deduplication of any stale transfers instead.
                let outstandingCount = session.outstandingUserInfoTransfers.count
                if outstandingCount > 0 {
                    print("ConnectivityManager: [iOS] \(outstandingCount) outstanding userInfo transfer(s) — letting them deliver")
                }
            #endif

            #if os(watchOS)
                self.isCompanionAppInstalled = session.isCompanionAppInstalled
                print("ConnectivityManager: [watchOS] Companion app installed: \(session.isCompanionAppInstalled)")
                if !session.isCompanionAppInstalled {
                    print("ConnectivityManager: ⚠️ [watchOS] iOS companion app is not installed!")
                }
            #endif

            self.isReachable = session.isReachable

            // Advertise our envelope schema version so the peer can detect
            // version mismatches and decide how to talk to us.
            self.advertiseLocalSchemaVersion()

            // Capture anything the peer published before we activated — schema
            // version, last-known snapshots, etc.
            self.processReceivedApplicationContext(session.receivedApplicationContext)

            // Drain any sends that were buffered while the session was activating.
            // Without this, sends made during cold launch are silently dropped.
            self.flushPendingSends()
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            // Post notification for observers (e.g., WatchSyncManager)
            NotificationCenter.default.post(name: NSNotification.Name("ConnectivityChanged"), object: nil)
        }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleMessage(message)
        }
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        print("ConnectivityManager: Received message with reply handler - \(message)")
        Task { @MainActor in
            if let requestTypeString = message["request"] as? String,
               let requestType = MessageType(rawValue: requestTypeString) {
                // Handle request and prepare response with data
                await self.handleRequest(requestType, replyHandler: replyHandler)
            } else {
                // If not a request, just handle the message
                self.handleMessage(message)
                replyHandler([:])
            }
        }
    }

    /// For background transfers
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("ConnectivityManager: Received user info - \(userInfo)")
        Task { @MainActor in
            self.handleMessage(userInfo)
        }
    }

    /// Add handler for application context updates
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("ConnectivityManager: Received application context update - \(applicationContext)")
        Task { @MainActor in
            self.processReceivedApplicationContext(applicationContext)
        }
    }

    /// Walks an application-context dict and dispatches recognized keys (schema
    /// version, snapshots, legacy "type"/"data" pair). Idempotent — safe to call
    /// when activation completes after a context already arrived.
    @MainActor
    private func processReceivedApplicationContext(_ applicationContext: [String: Any]) {
        // Schema-version handshake key may travel alongside other context fields.
        if let peerVersion = applicationContext[Self.schemaVersionContextKey] as? Int {
            self.recordPeerSchemaVersion(peerVersion)
        }

        // Snapshot keys (Ship 3+): "snapshot.<message_type>" → envelope bytes.
        for (key, value) in applicationContext {
            guard key.hasPrefix("snapshot.") else { continue }
            let rawType = String(key.dropFirst("snapshot.".count))
            guard let messageType = MessageType(rawValue: rawType),
                  let data = value as? Data else { continue }
            self.snapshotHandlers[messageType]?(data)
            for observer in self.snapshotObservers[messageType, default: [:]].values {
                observer(data)
            }
        }

        // Legacy single-snapshot wire shape ("type"/"data" keys) — preserved so
        // older companion builds still hand off state through application context
        // until they upgrade.
        if let type = applicationContext["type"] as? String,
           let messageType = MessageType(rawValue: type),
           let data = applicationContext["data"] as? Data,
           let handler = self.messageHandlers[messageType] {
            handler(data)
        }
    }

    #if os(iOS)
        public func sessionDidBecomeInactive(_ session: WCSession) {
            print("ConnectivityManager: Session became inactive")
        }

        public func sessionDidDeactivate(_ session: WCSession) {
            // Activate the new session after having switched to a new watch
            WCSession.default.activate()
        }
    #endif
}
