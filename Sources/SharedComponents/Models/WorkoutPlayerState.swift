import Foundation
import Observation // iOS 17+ for @Observable macro

/// Workout player state using @Observable for automatic SwiftUI reactivity
/// This class provides property-level change detection, eliminating the need for manual publisher triggers
@Observable
public final class WorkoutPlayerState: Codable {
    // MARK: Lifecycle

    public init(
        isStarted: Bool = false,
        isPaused: Bool = true,
        isComplete: Bool = false,
        currentRoundIndex: Int = 0,
        currentSetIndex: Int = 0,
        currentStepIndex: Int = 0,
        currentRepeatCount: Int = 1,
        stepProgress: Double = 0,
        completedSteps: Int = 0,
        totalSteps: Int = 0,
        currentStepNumber: Int = 1,
        currentHeartRate: Double = 0,
        activeCalories: Double = 0,
        startTime: Date? = nil,
        lastPausedAt: Date? = nil,
        totalPausedTime: TimeInterval = 0,
        stepStartTime: Date? = nil,
        stepElapsedTime: TimeInterval = 0,
        currentRoundName: String? = nil,
        currentStepName: String? = nil,
        currentStepType: String? = nil,
        currentStepMetrics: String? = nil,
        nextStepName: String? = nil,
        scheduledWorkoutId: UUID? = nil,
        totalRepsCompleted: Int? = nil,
        totalWeightLifted: Double? = nil,
        exerciseMetrics: Data? = nil
    ) {
        self.isStarted = isStarted
        self.isPaused = isPaused
        self.isComplete = isComplete
        self.currentRoundIndex = currentRoundIndex
        self.currentSetIndex = currentSetIndex
        self.currentStepIndex = currentStepIndex
        self.currentRepeatCount = currentRepeatCount
        self.stepProgress = stepProgress
        self.completedSteps = completedSteps
        self.totalSteps = totalSteps
        self.currentStepNumber = currentStepNumber
        self.currentHeartRate = currentHeartRate
        self.activeCalories = activeCalories
        self.startTime = startTime
        self.lastPausedAt = lastPausedAt
        self.totalPausedTime = totalPausedTime
        self.stepStartTime = stepStartTime
        self.stepElapsedTime = stepElapsedTime
        self.currentRoundName = currentRoundName
        self.currentStepName = currentStepName
        self.currentStepType = currentStepType
        self.currentStepMetrics = currentStepMetrics
        self.nextStepName = nextStepName
        self.scheduledWorkoutId = scheduledWorkoutId
        self.totalRepsCompleted = totalRepsCompleted
        self.totalWeightLifted = totalWeightLifted
        self.exerciseMetrics = exerciseMetrics
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isStarted = try container.decode(Bool.self, forKey: .isStarted)
        self.isPaused = try container.decode(Bool.self, forKey: .isPaused)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.currentRoundIndex = try container.decode(Int.self, forKey: .currentRoundIndex)
        self.currentSetIndex = try container.decode(Int.self, forKey: .currentSetIndex)
        self.currentStepIndex = try container.decode(Int.self, forKey: .currentStepIndex)
        self.currentRepeatCount = try container.decode(Int.self, forKey: .currentRepeatCount)

        self.scheduledWorkoutId = try container.decodeIfPresent(UUID.self, forKey: .scheduledWorkoutId)

        self.serverTotalActiveTime = try container.decodeIfPresent(Int.self, forKey: .serverTotalActiveTime) ?? 0
        self.lastSyncTime = try container.decodeIfPresent(Date.self, forKey: .lastSyncTime)
        self.pauseAlreadyAccountedFor = try container
            .decodeIfPresent(Bool.self, forKey: .pauseAlreadyAccountedFor) ?? false

        self.stepProgress = try container.decode(Double.self, forKey: .stepProgress)
        self.completedSteps = try container.decode(Int.self, forKey: .completedSteps)
        self.totalSteps = try container.decode(Int.self, forKey: .totalSteps)
        self.currentStepNumber = try container.decode(Int.self, forKey: .currentStepNumber)
        self.hasJumpedToStep = try container.decode(Bool.self, forKey: .hasJumpedToStep)
        self.completedStepPositions = try container.decode(Set<Int>.self, forKey: .completedStepPositions)

        self.currentHeartRate = try container.decode(Double.self, forKey: .currentHeartRate)
        self.activeCalories = try container.decode(Double.self, forKey: .activeCalories)

        self.totalRepsCompleted = try container.decodeIfPresent(Int.self, forKey: .totalRepsCompleted)
        self.totalWeightLifted = try container.decodeIfPresent(Double.self, forKey: .totalWeightLifted)
        self.exerciseMetrics = try container.decodeIfPresent(Data.self, forKey: .exerciseMetrics)

        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.lastPausedAt = try container.decodeIfPresent(Date.self, forKey: .lastPausedAt)
        self.totalPausedTime = try container.decode(TimeInterval.self, forKey: .totalPausedTime)

        self.stepStartTime = try container.decodeIfPresent(Date.self, forKey: .stepStartTime)
        self.stepElapsedTime = try container.decode(TimeInterval.self, forKey: .stepElapsedTime)
        self.stepTotalPausedTime = try container.decode(TimeInterval.self, forKey: .stepTotalPausedTime)

        self.currentRoundName = try container.decodeIfPresent(String.self, forKey: .currentRoundName)
        self.currentStepName = try container.decodeIfPresent(String.self, forKey: .currentStepName)
        self.currentStepType = try container.decodeIfPresent(String.self, forKey: .currentStepType)
        self.currentStepMetrics = try container.decodeIfPresent(String.self, forKey: .currentStepMetrics)
        self.currentStepDuration = try container.decodeIfPresent(Int.self, forKey: .currentStepDuration)
        self.currentStepReps = try container.decodeIfPresent(Int.self, forKey: .currentStepReps)
        self.nextStepName = try container.decodeIfPresent(String.self, forKey: .nextStepName)

        self.heartRateEntries = try container.decode([HeartRateEntry].self, forKey: .heartRateEntries)
    }

    // MARK: Public

    public var isStarted: Bool
    public var isPaused: Bool
    public var isComplete: Bool
    public var currentRoundIndex: Int
    public var currentSetIndex: Int
    public var currentStepIndex: Int
    public var currentRepeatCount: Int

    /// Backend integration fields
    public var scheduledWorkoutId: UUID?
    // Note: Backend sync now handled by unified session API

    /// Server-authoritative timing fields
    /// Total active time from server in seconds - source of truth for elapsed time
    public var serverTotalActiveTime: Int = 0
    /// When we last synced with server
    public var lastSyncTime: Date?
    /// Flag to prevent double-counting pause time when configureForResume already set it
    public var pauseAlreadyAccountedFor: Bool = false

    public var stepProgress: Double
    public var completedSteps: Int
    public var totalSteps: Int
    public var currentStepNumber: Int // For display purposes when jumping to a step
    public var hasJumpedToStep: Bool = false // Track if we've jumped to avoid marking skipped steps
    public var completedStepPositions: Set<Int> = [] // Track specific positions of completed steps
    public var activeCalories: Double

    // Exercise metrics
    public var totalRepsCompleted: Int?
    public var totalWeightLifted: Double?
    public var exerciseMetrics: Data?

    // Overall workout timing
    public var startTime: Date?
    public var endTime: Date?

    public var lastPausedAt: Date?
    public var totalPausedTime: TimeInterval

    // Step timing
    public var stepStartTime: Date?
    public var stepElapsedTime: TimeInterval
    public var stepTotalPausedTime: TimeInterval = 0

    // Current state info for display
    public var currentRoundName: String?
    public var currentStepName: String?
    public var currentStepType: String?
    public var currentStepMetrics: String?
    public var currentStepDuration: Int? // Duration in seconds for time-based steps
    public var currentStepReps: Int? // Reps for rep-based steps
    public var nextStepName: String?

    public var heartRateEntries: [HeartRateEntry] = []

    public var totalElapsedTime: TimeInterval {
        // If server has authoritative timing data, use it
        if self.serverTotalActiveTime > 0, let syncTime = lastSyncTime {
            // Start with server's total active time
            var elapsed = TimeInterval(self.serverTotalActiveTime)

            // Add time since last sync (only if not paused)
            if !self.isPaused && !self.isComplete {
                let timeSinceSync = Date().timeIntervalSince(syncTime)
                elapsed += timeSinceSync
            }

            return max(0, elapsed)
        }

        // Fallback to local calculation
        guard let start = startTime else {
            return 0
        }
        let end = self.isComplete ? (self.endTime ?? Date()) : Date()
        var elapsed = end.timeIntervalSince(start)

        // Subtract total paused time
        elapsed -= self.totalPausedTime

        // If currently paused, also subtract time since last pause
        if self.isPaused, let pausedAt = lastPausedAt {
            elapsed -= end.timeIntervalSince(pausedAt)
        }

        return max(0, elapsed)
    }

    public var currentHeartRate: Double {
        didSet {
            if oldValue != self.currentHeartRate {
                self.heartRateEntries.append(HeartRateEntry(timestamp: Date(), heartRate: self.currentHeartRate))
            }
        }
    }

    /// Heart rate statistics
    public var averageHeartRate: Double {
        guard !self.heartRateEntries.isEmpty else {
            return 0
        }
        let sum = self.heartRateEntries.reduce(0) { $0 + $1.heartRate }
        return sum / Double(self.heartRateEntries.count)
    }

    public var maxHeartRate: Double {
        self.heartRateEntries.map(\.heartRate).max() ?? 0
    }

    public var minHeartRate: Double {
        self.heartRateEntries.map(\.heartRate).min() ?? 0
    }

    public func calculateProgress() -> Double {
        guard self.totalSteps > 0 else {
            return 0
        }
        return Double(self.completedSteps) / Double(self.totalSteps)
    }

    public func calculateStepElapsedTime(at date: Date = Date()) -> TimeInterval {
        guard let start = stepStartTime else {
            return 0
        }

        var elapsed = date.timeIntervalSince(start)

        // Subtract total paused time for this step
        elapsed -= self.stepTotalPausedTime

        // If currently paused, subtract time since pause
        if self.isPaused, let pausedAt = lastPausedAt {
            elapsed -= date.timeIntervalSince(pausedAt)
        }

        return max(0, elapsed)
    }

    public func startNewStep() {
        self.stepStartTime = Date()
        self.stepElapsedTime = 0
        self.stepProgress = 0
        self.stepTotalPausedTime = 0
        self.lastPausedAt = nil // Reset pause state for new step
        self.isPaused = false // Ensure step starts in non-paused state
    }

    public func pauseStep(at date: Date = Date()) {
        guard !self.isPaused else {
            return
        }
        self.isPaused = true
        self.lastPausedAt = date
    }

    public func resumeStep(at date: Date = Date()) {
        guard self.isPaused else {
            print("⏱️ resumeStep: Skipping - already resumed (isPaused=\(self.isPaused))")
            return
        }

        // Only add pause duration if we have a valid lastPausedAt
        // AND it wasn't already accounted for in configureForResume
        if let pausedAt = lastPausedAt, !self.pauseAlreadyAccountedFor {
            // Calculate the pause duration
            let pauseDuration = date.timeIntervalSince(pausedAt)

            print(
                "⏱️ resumeStep: pausedAt=\(pausedAt), now=\(date), " +
                    "pauseDuration=\(Int(pauseDuration))s, " +
                    "totalPausedTime BEFORE=\(Int(self.totalPausedTime))s"
            )

            // Add to total paused time
            self.stepTotalPausedTime += pauseDuration
            self.totalPausedTime += pauseDuration

            print("⏱️ resumeStep: totalPausedTime AFTER=\(Int(self.totalPausedTime))s")
        } else if self.pauseAlreadyAccountedFor {
            print("⏱️ resumeStep: Pause time already accounted for from server - skipping local calculation")
        } else {
            print("⏱️ resumeStep: No lastPausedAt set - skipping pause time calculation")
        }

        // Clear pause state
        self.isPaused = false
        self.lastPausedAt = nil
        self.pauseAlreadyAccountedFor = false // Reset flag for next pause
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.isStarted, forKey: .isStarted)
        try container.encode(self.isPaused, forKey: .isPaused)
        try container.encode(self.isComplete, forKey: .isComplete)
        try container.encode(self.currentRoundIndex, forKey: .currentRoundIndex)
        try container.encode(self.currentSetIndex, forKey: .currentSetIndex)
        try container.encode(self.currentStepIndex, forKey: .currentStepIndex)
        try container.encode(self.currentRepeatCount, forKey: .currentRepeatCount)

        try container.encodeIfPresent(self.scheduledWorkoutId, forKey: .scheduledWorkoutId)

        try container.encode(self.serverTotalActiveTime, forKey: .serverTotalActiveTime)
        try container.encodeIfPresent(self.lastSyncTime, forKey: .lastSyncTime)
        try container.encode(self.pauseAlreadyAccountedFor, forKey: .pauseAlreadyAccountedFor)

        try container.encode(self.stepProgress, forKey: .stepProgress)
        try container.encode(self.completedSteps, forKey: .completedSteps)
        try container.encode(self.totalSteps, forKey: .totalSteps)
        try container.encode(self.currentStepNumber, forKey: .currentStepNumber)
        try container.encode(self.hasJumpedToStep, forKey: .hasJumpedToStep)
        try container.encode(self.completedStepPositions, forKey: .completedStepPositions)

        try container.encode(self.currentHeartRate, forKey: .currentHeartRate)
        try container.encode(self.activeCalories, forKey: .activeCalories)

        try container.encodeIfPresent(self.totalRepsCompleted, forKey: .totalRepsCompleted)
        try container.encodeIfPresent(self.totalWeightLifted, forKey: .totalWeightLifted)
        try container.encodeIfPresent(self.exerciseMetrics, forKey: .exerciseMetrics)

        try container.encodeIfPresent(self.startTime, forKey: .startTime)
        try container.encodeIfPresent(self.endTime, forKey: .endTime)
        try container.encodeIfPresent(self.lastPausedAt, forKey: .lastPausedAt)
        try container.encode(self.totalPausedTime, forKey: .totalPausedTime)

        try container.encodeIfPresent(self.stepStartTime, forKey: .stepStartTime)
        try container.encode(self.stepElapsedTime, forKey: .stepElapsedTime)
        try container.encode(self.stepTotalPausedTime, forKey: .stepTotalPausedTime)

        try container.encodeIfPresent(self.currentRoundName, forKey: .currentRoundName)
        try container.encodeIfPresent(self.currentStepName, forKey: .currentStepName)
        try container.encodeIfPresent(self.currentStepType, forKey: .currentStepType)
        try container.encodeIfPresent(self.currentStepMetrics, forKey: .currentStepMetrics)
        try container.encodeIfPresent(self.currentStepDuration, forKey: .currentStepDuration)
        try container.encodeIfPresent(self.currentStepReps, forKey: .currentStepReps)
        try container.encodeIfPresent(self.nextStepName, forKey: .nextStepName)

        try container.encode(self.heartRateEntries, forKey: .heartRateEntries)
    }

    // MARK: Private

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        case isStarted, isPaused, isComplete
        case currentRoundIndex, currentSetIndex, currentStepIndex, currentRepeatCount
        case scheduledWorkoutId
        case serverTotalActiveTime, lastSyncTime, pauseAlreadyAccountedFor
        case stepProgress, completedSteps, totalSteps, currentStepNumber
        case hasJumpedToStep, completedStepPositions
        case currentHeartRate, activeCalories
        case totalRepsCompleted, totalWeightLifted, exerciseMetrics
        case startTime, endTime, lastPausedAt, totalPausedTime
        case stepStartTime, stepElapsedTime, stepTotalPausedTime
        case currentRoundName, currentStepName, currentStepType, currentStepMetrics, currentStepDuration,
             currentStepReps, nextStepName
        case heartRateEntries
    }
}
