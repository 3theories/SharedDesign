import Foundation

/// Shared storage for pending intent requests
///
/// This allows intents to store their requests when the app launches,
/// and the main app can pick them up once it's fully initialized.
/// Uses App Group UserDefaults for cross-process communication.
public final class IntentRequestStore {
    // MARK: Lifecycle

    private init() {
        // Try App Group first for cross-process communication (widgets, extensions)
        // Fall back to standard UserDefaults if App Group isn't available
        if let groupDefaults = UserDefaults(suiteName: "group.com.3theories.niora") {
            self.defaults = groupDefaults
            print("[IntentRequestStore] Initialized with App Group UserDefaults")
        } else {
            self.defaults = .standard
            print("[IntentRequestStore] Falling back to standard UserDefaults")
        }
    }

    // MARK: Public

    // MARK: - Meal Log Request

    /// Pending meal log request data
    public struct MealLogRequest: Codable {
        // MARK: Lifecycle

        public init(mealType: String?) {
            self.mealType = mealType
            self.timestamp = Date()
        }

        // MARK: Public

        public let mealType: String?
        public let timestamp: Date
    }

    // MARK: - Snap Meal Request

    /// Pending snap meal request data (open camera)
    public struct SnapMealRequest: Codable {
        // MARK: Lifecycle

        public init(mealType: String?) {
            self.mealType = mealType
            self.timestamp = Date()
        }

        // MARK: Public

        public let mealType: String?
        public let timestamp: Date
    }

    // MARK: - Water Log Request (Siri Intent - 30 second timeout)

    /// Pending water log request data
    public struct WaterLogRequest: Codable {
        // MARK: Lifecycle

        public init(amount: Double) {
            self.amount = amount
            self.timestamp = Date()
        }

        // MARK: Public

        public let amount: Double
        public let timestamp: Date
    }

    // MARK: - Start Workout Request

    /// Pending start workout request data
    public struct StartWorkoutRequest: Codable {
        // MARK: Lifecycle

        public init(workoutId: String?) {
            self.workoutId = workoutId
            self.timestamp = Date()
        }

        // MARK: Public

        public let workoutId: String?
        public let timestamp: Date
    }

    // MARK: - View Workout Request

    /// Pending view workout request data
    public struct ViewWorkoutRequest: Codable {
        // MARK: Lifecycle

        public init() {
            self.timestamp = Date()
        }

        // MARK: Public

        public let timestamp: Date
    }

    // MARK: - Fasting Request

    /// Fasting action type
    public enum FastingAction: String, Codable {
        case start
        case end
    }

    /// Pending fasting request data
    public struct FastingRequest: Codable {
        // MARK: Lifecycle

        public init(action: FastingAction) {
            self.action = action
            self.timestamp = Date()
        }

        // MARK: Public

        public let action: FastingAction
        public let timestamp: Date
    }

    /// Widget fasting toggle entry
    public struct WidgetFastingToggle: Codable {
        // MARK: Lifecycle

        public init(action: FastingAction, windowHours: Int) {
            self.action = action
            self.windowHours = windowHours
            self.timestamp = Date()
        }

        // MARK: Public

        public let action: FastingAction
        public let windowHours: Int
        public let timestamp: Date
    }

    // MARK: - Singleton

    public static let shared = IntentRequestStore()

    /// Store a pending meal log request
    public func storeMealLogRequest(mealType: String?) {
        print("[IntentRequestStore] storeMealLogRequest called with mealType: \(mealType ?? "nil")")
        let request = MealLogRequest(mealType: mealType)
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingMealLog)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored meal log request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode meal log request")
        }
    }

    /// Get and clear the pending meal log request
    public func consumeMealLogRequest() -> MealLogRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingMealLog) else {
            print("[IntentRequestStore] No pending meal log request found")
            return nil
        }

        print("[IntentRequestStore] Found pending meal log data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingMealLog)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(MealLogRequest.self, from: data) else {
            print("[IntentRequestStore] Failed to decode meal log request")
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        print("[IntentRequestStore] Meal log request age: \(age) seconds")
        if age > 30 {
            print("[IntentRequestStore] Request too old, discarding")
            return nil
        }

        print("[IntentRequestStore] Returning meal log request: \(request.mealType ?? "nil")")
        return request
    }

    /// Check if there's a pending meal log request without consuming it
    public func hasPendingMealLogRequest() -> Bool {
        self.defaults.data(forKey: Keys.pendingMealLog) != nil
    }

    /// Store a pending snap meal request
    public func storeSnapMealRequest(mealType: String?) {
        print("[IntentRequestStore] storeSnapMealRequest called with mealType: \(mealType ?? "nil")")
        let request = SnapMealRequest(mealType: mealType)
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingSnapMeal)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored snap meal request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode snap meal request")
        }
    }

    /// Get and clear the pending snap meal request
    public func consumeSnapMealRequest() -> SnapMealRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingSnapMeal) else {
            print("[IntentRequestStore] No pending snap meal request found")
            return nil
        }

        print("[IntentRequestStore] Found pending snap meal data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingSnapMeal)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(SnapMealRequest.self, from: data) else {
            print("[IntentRequestStore] Failed to decode snap meal request")
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        print("[IntentRequestStore] Snap meal request age: \(age) seconds")
        if age > 30 {
            print("[IntentRequestStore] Request too old, discarding")
            return nil
        }

        print("[IntentRequestStore] Returning snap meal request: \(request.mealType ?? "nil")")
        return request
    }

    /// Store a pending water log request (Siri intents - times out after 30 seconds)
    public func storeWaterLogRequest(amount: Double) {
        print("[IntentRequestStore] storeWaterLogRequest called with amount: \(amount)")
        let request = WaterLogRequest(amount: amount)
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingWaterLog)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored water log request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode water log request")
        }
    }

    /// Get and clear the pending water log request
    public func consumeWaterLogRequest() -> WaterLogRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingWaterLog) else {
            print("[IntentRequestStore] No pending water log request found")
            return nil
        }

        print("[IntentRequestStore] Found pending water log data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingWaterLog)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(WaterLogRequest.self, from: data) else {
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        if age > 30 {
            return nil
        }

        return request
    }

    /// Queue a water log from the widget (persists until consumed by app)
    public func queueWidgetWaterLog(amountMl: Int) {
        var queue = self.getWidgetWaterLogQueue()
        let entry = WaterLogRequest(amount: Double(amountMl))
        queue.append(entry)

        if let data = try? JSONEncoder().encode(queue) {
            self.defaults.set(data, forKey: Self.widgetWaterLogsKey)
            self.defaults.synchronize()
            print("[IntentRequestStore] Queued widget water log: \(amountMl)ml (queue size: \(queue.count))")
        }
    }

    /// Get all pending widget water logs without clearing
    public func getWidgetWaterLogQueue() -> [WaterLogRequest] {
        self.defaults.synchronize()
        guard let data = defaults.data(forKey: Self.widgetWaterLogsKey),
              let queue = try? JSONDecoder().decode([WaterLogRequest].self, from: data) else {
            return []
        }
        return queue
    }

    /// Consume all pending widget water logs (clears the queue)
    public func consumeWidgetWaterLogQueue() -> [WaterLogRequest] {
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Self.widgetWaterLogsKey),
              let queue = try? JSONDecoder().decode([WaterLogRequest].self, from: data) else {
            return []
        }

        // Clear the queue
        self.defaults.removeObject(forKey: Self.widgetWaterLogsKey)
        self.defaults.synchronize()

        // Filter to only include logs from today (discard stale entries from previous days)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filtered = queue.filter { calendar.startOfDay(for: $0.timestamp) == today }

        print(
            "[IntentRequestStore] Consumed \(filtered.count) widget water logs (discarded \(queue.count - filtered.count) stale)"
        )
        return filtered
    }

    /// Check if there are pending widget water logs
    public func hasWidgetWaterLogs() -> Bool {
        !self.getWidgetWaterLogQueue().isEmpty
    }

    /// Store a pending start workout request
    public func storeStartWorkoutRequest(workoutId: String?) {
        print("[IntentRequestStore] storeStartWorkoutRequest called with workoutId: \(workoutId ?? "nil")")
        let request = StartWorkoutRequest(workoutId: workoutId)
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingStartWorkout)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored start workout request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode start workout request")
        }
    }

    /// Get and clear the pending start workout request
    public func consumeStartWorkoutRequest() -> StartWorkoutRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingStartWorkout) else {
            print("[IntentRequestStore] No pending start workout request found")
            return nil
        }

        print("[IntentRequestStore] Found pending start workout data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingStartWorkout)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(StartWorkoutRequest.self, from: data) else {
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        if age > 30 {
            return nil
        }

        return request
    }

    /// Store a pending view workout request
    public func storeViewWorkoutRequest() {
        print("[IntentRequestStore] storeViewWorkoutRequest called")
        let request = ViewWorkoutRequest()
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingViewWorkout)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored view workout request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode view workout request")
        }
    }

    /// Get and clear the pending view workout request
    public func consumeViewWorkoutRequest() -> ViewWorkoutRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingViewWorkout) else {
            print("[IntentRequestStore] No pending view workout request found")
            return nil
        }

        print("[IntentRequestStore] Found pending view workout data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingViewWorkout)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(ViewWorkoutRequest.self, from: data) else {
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        if age > 30 {
            return nil
        }

        return request
    }

    /// Store a pending fasting request
    public func storeFastingRequest(action: FastingAction) {
        print("[IntentRequestStore] storeFastingRequest called with action: \(action.rawValue)")
        let request = FastingRequest(action: action)
        if let data = try? JSONEncoder().encode(request) {
            self.defaults.set(data, forKey: Keys.pendingFasting)
            self.defaults.synchronize()
            print("[IntentRequestStore] Stored fasting request: \(data.count) bytes")
        } else {
            print("[IntentRequestStore] Failed to encode fasting request")
        }
    }

    /// Get and clear the pending fasting request
    public func consumeFastingRequest() -> FastingRequest? {
        // Force sync from disk to handle cross-process scenarios (Siri → App)
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Keys.pendingFasting) else {
            print("[IntentRequestStore] No pending fasting request found")
            return nil
        }

        print("[IntentRequestStore] Found pending fasting data: \(data.count) bytes")

        // Clear the request
        self.defaults.removeObject(forKey: Keys.pendingFasting)
        self.defaults.synchronize()

        // Decode and return
        guard let request = try? JSONDecoder().decode(FastingRequest.self, from: data) else {
            print("[IntentRequestStore] Failed to decode fasting request")
            return nil
        }

        // Only return if request is recent (within last 30 seconds)
        let age = Date().timeIntervalSince(request.timestamp)
        print("[IntentRequestStore] Fasting request age: \(age) seconds")
        if age > 30 {
            print("[IntentRequestStore] Request too old, discarding")
            return nil
        }

        print("[IntentRequestStore] Returning fasting request: \(request.action.rawValue)")
        return request
    }

    /// Queue a fasting toggle from the widget (persists until consumed by app)
    public func queueWidgetFastingToggle(action: FastingAction, windowHours: Int) {
        var queue = self.getWidgetFastingToggleQueue()
        let entry = WidgetFastingToggle(action: action, windowHours: windowHours)
        queue.append(entry)

        if let data = try? JSONEncoder().encode(queue) {
            self.defaults.set(data, forKey: Self.widgetFastingTogglesKey)
            self.defaults.synchronize()
            print("[IntentRequestStore] Queued widget fasting toggle: \(action.rawValue) (queue size: \(queue.count))")
        }
    }

    /// Get all pending widget fasting toggles without clearing
    public func getWidgetFastingToggleQueue() -> [WidgetFastingToggle] {
        self.defaults.synchronize()
        guard let data = defaults.data(forKey: Self.widgetFastingTogglesKey),
              let queue = try? JSONDecoder().decode([WidgetFastingToggle].self, from: data) else {
            return []
        }
        return queue
    }

    /// Consume all pending widget fasting toggles (clears the queue)
    public func consumeWidgetFastingToggleQueue() -> [WidgetFastingToggle] {
        self.defaults.synchronize()

        guard let data = defaults.data(forKey: Self.widgetFastingTogglesKey),
              let queue = try? JSONDecoder().decode([WidgetFastingToggle].self, from: data) else {
            return []
        }

        // Clear the queue
        self.defaults.removeObject(forKey: Self.widgetFastingTogglesKey)
        self.defaults.synchronize()

        // Filter to only include toggles from today (discard stale entries from previous days)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filtered = queue.filter { calendar.startOfDay(for: $0.timestamp) == today }

        print(
            "[IntentRequestStore] Consumed \(filtered.count) widget fasting toggles (discarded \(queue.count - filtered.count) stale)"
        )
        return filtered
    }

    /// Check if there are pending widget fasting toggles
    public func hasWidgetFastingToggles() -> Bool {
        !self.getWidgetFastingToggleQueue().isEmpty
    }

    // MARK: Private

    // MARK: - Storage Keys

    private enum Keys {
        static let pendingMealLog = "pendingMealLogRequest"

        static let pendingSnapMeal = "pendingSnapMealRequest"

        static let pendingWaterLog = "pendingWaterLogRequest"
        static let pendingStartWorkout = "pendingStartWorkoutRequest"
        static let pendingViewWorkout = "pendingViewWorkoutRequest"
        static let pendingFasting = "pendingFastingRequest"
    }

    // MARK: - Widget Water Log Queue (Persistent - no timeout)

    private static let widgetWaterLogsKey = "widgetWaterLogQueue"

    // MARK: - Widget Fasting Toggle Queue (Persistent - no timeout)

    private static let widgetFastingTogglesKey = "widgetFastingToggleQueue"

    // MARK: - Storage

    private let defaults: UserDefaults
}
