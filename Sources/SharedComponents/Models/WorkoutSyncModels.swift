import Foundation

// MARK: - WorkoutSyncData
//
// Watch-side internal storage shape for the workout's round/set tree. The
// `WorkoutPlayerSyncState.config` has the same fields under
// `WorkoutPlayerSessionConfig`; we keep `WorkoutSyncData` as the watch's
// in-memory render shape because the existing Watch UI binds against it.
// Translation happens at the mesh boundary in `WatchWorkoutManager.applyRemoteWorkoutEvent`.

public struct WorkoutSyncData: Codable, Sendable {
    public init(workoutName: String, totalRounds: Int, rounds: [WorkoutRoundSync]) {
        self.workoutName = workoutName
        self.totalRounds = totalRounds
        self.rounds = rounds
    }

    public let workoutName: String
    public let totalRounds: Int
    public let rounds: [WorkoutRoundSync]
}

// MARK: - WorkoutRoundSync

public struct WorkoutRoundSync: Codable, Sendable, Equatable {
    public init(name: String, sets: [WorkoutSetSync]) {
        self.name = name
        self.sets = sets
    }

    public let name: String
    public let sets: [WorkoutSetSync]
}

// MARK: - WorkoutSetSync

public struct WorkoutSetSync: Codable, Sendable, Equatable {
    public init(name: String, type: String, metrics: String, duration: TimeInterval? = nil, reps: Int? = nil) {
        self.name = name
        self.type = type
        self.metrics = metrics
        self.duration = duration
        self.reps = reps
    }

    public let name: String
    public let type: String
    public let metrics: String
    public let duration: TimeInterval?
    public let reps: Int?
}

// MARK: - WorkoutMetricsData

/// HK-channel payload for Watch → iPhone metrics in the standalone Watch
/// session path (when the iPhone session isn't mirroring). For mirrored
/// sessions HealthKit delivers metrics directly via the multidevice API; for
/// the mesh-canonical path use `WorkoutPlayerSyncAdapter.submitMetricsSample`.
public struct WorkoutMetricsData: Codable, Sendable {
    public init(
        heartRate: Double? = nil,
        activeCalories: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.heartRate = heartRate
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.timestamp = timestamp
    }

    public let heartRate: Double?
    public let activeCalories: Double?
    public let averageHeartRate: Double?
    public let maxHeartRate: Double?
    public let timestamp: Date
}

// MARK: - Helper Extensions

extension WorkoutSyncData {
    /// Get the first step of the first round for initial UI population
    public var firstStep: WorkoutSetSync? {
        self.rounds.first?.sets.first
    }

    /// Get the first round name
    public var firstRoundName: String? {
        self.rounds.first?.name
    }
}
