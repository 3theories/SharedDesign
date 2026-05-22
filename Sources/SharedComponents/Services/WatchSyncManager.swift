import Foundation

/// Stub kept only because some legacy modules still reference the symbol.
/// All workout-player wire-level work is now done by the SessionMesh adapter
/// (`WorkoutPlayerSyncAdapter`); the App-target's own `WatchSyncManager`
/// (`iOS/Niora/Services/WatchSyncManager.swift`) handles non-workout
/// state syncing.
public class WatchSyncManager {
    private init() { }

    public static let shared = WatchSyncManager()
}
