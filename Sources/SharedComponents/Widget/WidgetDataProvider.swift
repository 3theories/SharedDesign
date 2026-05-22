import Foundation

// MARK: - WidgetDataProvider

/// Protocol for widget data providers
public protocol WidgetDataProvider {
    associatedtype SnapshotType: Codable

    static var appGroupId: String { get }
    static var snapshotKey: String { get }

    static func saveSnapshot(_ snapshot: SnapshotType)
    static func loadSnapshot() -> SnapshotType?
}

/// Default implementation using UserDefaults
extension WidgetDataProvider {
    public static var appGroupId: String { "group.com.3theories.niora" }

    /// Persist to an atomic JSON file in the App Group container to avoid cross-process timing races
    private static func snapshotURL() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[WidgetDataProvider] Missing container URL for app group: \(self.appGroupId)")
            return nil
        }
        let dir = container.appendingPathComponent("widgets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(snapshotKey).json", conformingTo: .json)
    }

    public static func saveSnapshot(_ snapshot: SnapshotType) {
        do {
            let data = try JSONEncoder().encode(snapshot)

            // Save to BOTH UserDefaults AND file for redundancy
            // UserDefaults is always readable even when device is locked
            // This ensures the widget can always display data

            // 1. Always save to UserDefaults first (most reliable for widgets)
            if let defaults = UserDefaults(suiteName: appGroupId) {
                defaults.set(data, forKey: snapshotKey)
                // Force synchronize for cross-process widget access
                defaults.synchronize()
            }

            // 2. Also save to file (faster access when available)
            if let url = snapshotURL() {
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            }
        } catch {
            print("[WidgetDataProvider] Failed to encode/save snapshot: \(error)")
        }
    }

    public static func loadSnapshot() -> SnapshotType? {
        // Try UserDefaults FIRST - it's always readable even when device is locked
        // This is the most reliable source for widgets
        if let defaults = UserDefaults(suiteName: appGroupId),
           let data = defaults.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(SnapshotType.self, from: data) {
            return snapshot
        }

        // Fallback to file (may fail when device is locked due to file protection)
        if let url = snapshotURL(),
           let data = try? Data(contentsOf: url),
           let snapshot = try? JSONDecoder().decode(SnapshotType.self, from: data) {
            // Migrate to UserDefaults for future reliability
            if let defaults = UserDefaults(suiteName: appGroupId) {
                defaults.set(data, forKey: snapshotKey)
            }
            return snapshot
        }

        print("[WidgetDataProvider] No snapshot available for key: \(snapshotKey)")
        return nil
    }
}

// MARK: - FastingWidgetDataProvider

/// Fasting widget data provider
public enum FastingWidgetDataProvider: WidgetDataProvider {
    public typealias SnapshotType = FastingWidgetSnapshot

    public static var snapshotKey: String {
        "fasting_widget_snapshot_v3"
    }
}

// MARK: - WorkoutWidgetDataProvider

/// Workout widget data provider
public enum WorkoutWidgetDataProvider: WidgetDataProvider {
    public typealias SnapshotType = WorkoutWidgetSnapshot

    public static var snapshotKey: String {
        "workout_widget_snapshot_v2"
    }
}
