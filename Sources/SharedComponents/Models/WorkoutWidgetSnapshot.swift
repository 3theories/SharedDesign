import Foundation

// MARK: - WorkoutWidgetState

public enum WorkoutWidgetState: Int, Codable {
    case noWorkout = 0
    case restDay = 1
    case scheduled = 2
    case active = 3
    case paused = 4
    case completed = 5
}

// MARK: - WorkoutWidgetSnapshot

public struct WorkoutWidgetSnapshot: Codable {
    // MARK: Lifecycle

    public init(
        id: String?,
        stateRawValue: Int,
        workoutName: String?,
        workoutType: String?,
        scheduledTime: TimeInterval?,
        startTimeEpoch: TimeInterval?,
        endTimeEpoch: TimeInterval?,
        pausedTimeEpoch: TimeInterval?,
        currentExerciseIndex: Int?,
        totalExercises: Int?,
        currentExerciseName: String?,
        currentSets: Int?,
        totalSets: Int?,
        duration: Int?,
        caloriesBurned: Double?,
        updatedAtEpoch: TimeInterval
    ) {
        self.id = id
        self.stateRawValue = stateRawValue
        self.workoutName = workoutName
        self.workoutType = workoutType
        self.scheduledTime = scheduledTime
        self.startTimeEpoch = startTimeEpoch
        self.endTimeEpoch = endTimeEpoch
        self.pausedTimeEpoch = pausedTimeEpoch
        self.currentExerciseIndex = currentExerciseIndex
        self.totalExercises = totalExercises
        self.currentExerciseName = currentExerciseName
        self.currentSets = currentSets
        self.totalSets = totalSets
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.updatedAtEpoch = updatedAtEpoch
    }

    // MARK: Public

    public let id: String?
    public let stateRawValue: Int
    public let workoutName: String?
    public let workoutType: String? // strength, cardio, flexibility, etc.
    public let scheduledTime: TimeInterval?
    public let startTimeEpoch: TimeInterval?
    public let endTimeEpoch: TimeInterval?
    public let pausedTimeEpoch: TimeInterval?
    public let currentExerciseIndex: Int?
    public let totalExercises: Int?
    public let currentExerciseName: String?
    public let currentSets: Int?
    public let totalSets: Int?
    public let duration: Int? // in seconds
    public let caloriesBurned: Double?
    public let updatedAtEpoch: TimeInterval
}
