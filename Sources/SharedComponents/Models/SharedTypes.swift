import Foundation

// MARK: - MessageType

public enum MessageType: String {
    case fastingUpdate = "fasting_update"
    case workoutUpdate = "workout_update"
    case nutritionUpdate = "nutrition_update"
    case healthUpdate = "health_update"
    case workoutProgressUpdate = "workout_progress_update"
    case workoutMetricsUpdate = "workout_metrics_update"
    case authUpdate = "auth_update"
    case waterLogUpdate = "water_log_update"
    case fastingToggle = "fasting_toggle"
    case workoutInsightsUpdate = "workout_insights_update"
    case fastingInsightsUpdate = "fasting_insights_update"
    case nutritionInsightsUpdate = "nutrition_insights_update"

    /// Health/Recovery sync
    case recoveryScoreUpdate = "recovery_score_update"

    /// `helloWithLastKnown` — sent by either device when waking/foregrounding
    /// mid-activity to describe its last-known state and trigger a peer reply.
    case activityHelloWithLastKnown = "activity_hello_with_last_known"
}

// MARK: - FastingStatusDTO

public struct FastingStatusDTO: Codable {
    // MARK: Lifecycle

    public init(
        isActive: Bool,
        startTime: Date?,
        targetEndTime: Date?,
        fastingHours: Int,
        state: FastingState = .waiting,
        preferredStartHour: Int = FastingDefaults.preferredStartHour,
        preferredStartMinute: Int = FastingDefaults.preferredStartMinute
    ) {
        self.isActive = isActive
        self.startTime = startTime
        self.targetEndTime = targetEndTime
        self.fastingHours = fastingHours
        self.state = state
        self.preferredStartHour = preferredStartHour
        self.preferredStartMinute = preferredStartMinute
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        self.targetEndTime = try container.decodeIfPresent(Date.self, forKey: .targetEndTime)
        self.fastingHours = try container.decode(Int.self, forKey: .fastingHours)
        self.state = (try? container.decode(FastingState.self, forKey: .state)) ?? .waiting
        self.preferredStartHour = (try? container.decode(Int.self, forKey: .preferredStartHour)) ?? FastingDefaults.preferredStartHour
        self.preferredStartMinute = (try? container.decode(Int.self, forKey: .preferredStartMinute)) ?? FastingDefaults.preferredStartMinute
    }

    // MARK: Public

    public let isActive: Bool
    public let startTime: Date?
    public let targetEndTime: Date?
    public let fastingHours: Int
    public let state: FastingState
    public let preferredStartHour: Int
    public let preferredStartMinute: Int

    /// Eating window end time aligned to the user's preferred fasting start time.
    /// Delegates to `FastingDefaults.eatingWindowEndTime` for the core calculation.
    public var eatingWindowEndTime: Date? {
        guard let endTime = targetEndTime,
              let startTime = startTime else {
            return nil
        }

        return FastingDefaults.eatingWindowEndTime(
            startTime: startTime,
            endTime: endTime,
            preferredStartHour: preferredStartHour,
            preferredStartMinute: preferredStartMinute,
            windowHours: fastingHours
        )
    }
}

// MARK: - WorkoutStatusDTO

public struct WorkoutStatusDTO: Codable {
    // MARK: Lifecycle

    public init(
        workoutName: String,
        scheduleDate: Date,
        estimatedDuration: Double,
        workoutType: String? = nil,
        exerciseCount: Int? = nil
    ) {
        self.workoutName = workoutName
        self.scheduleDate = scheduleDate
        self.estimatedDuration = estimatedDuration
        self.workoutType = workoutType
        self.exerciseCount = exerciseCount
    }

    // MARK: Public

    public let workoutName: String
    public let scheduleDate: Date
    public let estimatedDuration: Double
    public let workoutType: String?
    public let exerciseCount: Int?

    /// Returns the appropriate icon name (either SF Symbol or custom asset)
    /// for this workout's type. Pair with `workoutIconIsSystemIcon` to know
    /// which `Image(...)` initializer to use — preferring `AppIconView` so
    /// callers don't have to branch.
    /// First attempts to parse as a WorkoutType enum, then falls back to
    /// string matching.
    public var workoutIconName: String {
        self.resolvedWorkoutType.iconName
    }

    /// Whether `workoutIconName` is a system SF Symbol (`true`) or a custom
    /// asset bundled in the app (`false`). Past regression: callers used
    /// `Image(systemName: status.workoutIconName)` unconditionally — for
    /// types like `.strength` / `.cardio` / `.yoga` / `.flexibility` /
    /// `.custom` (whose `iconName` is a custom asset, not an SF Symbol)
    /// this rendered an empty circle on the watch's scheduled-workout
    /// card. Use `AppIconView(name:isSystemIcon:)` instead.
    public var workoutIconIsSystemIcon: Bool {
        self.resolvedWorkoutType.isSystemIcon
    }

    /// Internal: classify the `workoutType` string into a `WorkoutType`
    /// enum so both `workoutIconName` and `workoutIconIsSystemIcon`
    /// agree on the resolution rather than duplicating the matching.
    private var resolvedWorkoutType: WorkoutType {
        guard let type = workoutType else {
            return .mixed
        }
        if let workoutTypeEnum = WorkoutType(rawValue: type.lowercased()) {
            return workoutTypeEnum
        }
        let lowercased = type.lowercased()
        if lowercased.contains("hiit") { return .hiit }
        if lowercased.contains("cardio") || lowercased.contains("run") { return .cardio }
        if lowercased.contains("strength") || lowercased.contains("weight") { return .strength }
        if lowercased.contains("yoga") { return .yoga }
        if lowercased.contains("pilates") { return .pilates }
        if lowercased.contains("flex") || lowercased.contains("stretch") { return .flexibility }
        return .mixed
    }
}

// MARK: - NutritionStatusDTO

public struct NutritionStatusDTO: Codable {
    // MARK: Lifecycle

    public init(
        caloriesConsumed: Double,
        waterIntake: Double,
        caloriesGoal: Double? = nil,
        waterGoal: Double? = nil
    ) {
        self.caloriesConsumed = caloriesConsumed
        self.waterIntake = waterIntake
        self.caloriesGoal = caloriesGoal
        self.waterGoal = waterGoal
    }

    // MARK: Public

    public let caloriesConsumed: Double
    public let waterIntake: Double
    /// User's daily calorie target (kcal). Optional so older iPhone builds
    /// paired with a newer watch decode without crashing — the watch falls
    /// back to its own default when nil.
    public let caloriesGoal: Double?
    /// User's daily water target (ml). Same back-compat reasoning as
    /// `caloriesGoal`.
    public let waterGoal: Double?
}

// MARK: - HealthStatusDTO

public struct HealthStatusDTO: Codable {
    // MARK: Lifecycle

    public init(steps: Int, activeCalories: Double, sleepHours: Double) {
        self.steps = steps
        self.activeCalories = activeCalories
        self.sleepHours = sleepHours
    }

    // MARK: Public

    public let steps: Int
    public let activeCalories: Double
    public let sleepHours: Double
}

// MARK: - AuthenticationStatusDTO

public struct AuthenticationStatusDTO: Codable {
    // MARK: Lifecycle

    public init(isAuthenticated: Bool, userName: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.userName = userName
    }

    // MARK: Public

    public let isAuthenticated: Bool
    public let userName: String?
}

// MARK: - AuthenticationState

public enum AuthenticationState: Codable, Equatable {
    case unknown
    case authenticated(userName: String?)
    case notAuthenticated

    // MARK: Public

    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    public var userName: String? {
        if case let .authenticated(name) = self {
            return name
        }
        return nil
    }
}

// MARK: - WatchWaterLogCommand

/// Water log command from watch app
public struct WatchWaterLogCommand: Codable {
    // MARK: Lifecycle

    public init(id: UUID = UUID(), amount: Double, timestamp: Date = Date()) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
    }

    // MARK: Public

    public let id: UUID
    public let amount: Double // in ml
    public let timestamp: Date
}

// MARK: - FastingToggleCommand

/// Command to toggle fasting state from watch app
public struct FastingToggleCommand: Codable {
    // MARK: Lifecycle

    public init(timestamp: Date) {
        self.timestamp = timestamp
    }

    // MARK: Public

    public let timestamp: Date
}

// MARK: - WorkoutStepDTO

/// Workout step data for Digital Crown navigation on watch
public struct WorkoutStepDTO: Identifiable, Codable {
    // MARK: Lifecycle

    public init(
        id: UUID,
        name: String,
        type: String,
        metrics: String,
        duration: Int?,
        reps: Int?,
        roundName: String,
        stepNumber: Int,
        isCurrent: Bool
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.metrics = metrics
        self.duration = duration
        self.reps = reps
        self.roundName = roundName
        self.stepNumber = stepNumber
        self.isCurrent = isCurrent
    }

    // MARK: Public

    public let id: UUID
    public let name: String
    public let type: String // "time", "reps", "warmup", "cooldown", "recover"
    public let metrics: String
    public let duration: Int? // seconds if time-based
    public let reps: Int? // count if rep-based
    public let roundName: String
    public let stepNumber: Int
    public let isCurrent: Bool
}

// MARK: - WorkoutInsightsDTO

/// Weekly workout insights for watch app display
public struct WorkoutInsightsDTO: Codable {
    // MARK: Lifecycle

    public init(
        weekDates: [Date],
        completedWorkouts: [Int],
        totalCompleted: Int,
        totalPlanned: Int,
        longestStreak: Int? = nil,
        consistencyScore: Double? = nil
    ) {
        self.weekDates = weekDates
        self.completedWorkouts = completedWorkouts
        self.totalCompleted = totalCompleted
        self.totalPlanned = totalPlanned
        self.longestStreak = longestStreak
        self.consistencyScore = consistencyScore
    }

    // MARK: Public

    public let weekDates: [Date]
    public let completedWorkouts: [Int]
    public let totalCompleted: Int
    public let totalPlanned: Int
    /// Longest consecutive days with completed workouts this week
    public let longestStreak: Int?
    /// Percentage of planned workouts completed (0.0-1.0)
    public let consistencyScore: Double?
}

// MARK: - FastingInsightsDTO

/// Fasting insights showing streak and average hours
public struct FastingInsightsDTO: Codable {
    // MARK: Lifecycle

    public init(
        currentStreak: Int,
        averageHours: Double,
        dailyFasting: [DailyFastingData],
        longestStreak: Int? = nil,
        totalFastsCompleted: Int? = nil,
        bestDayHours: Double? = nil,
        hoursChangeVsLastWeek: Double? = nil
    ) {
        self.currentStreak = currentStreak
        self.averageHours = averageHours
        self.dailyFasting = dailyFasting
        self.longestStreak = longestStreak
        self.totalFastsCompleted = totalFastsCompleted
        self.bestDayHours = bestDayHours
        self.hoursChangeVsLastWeek = hoursChangeVsLastWeek
    }

    // MARK: Public

    public struct DailyFastingData: Codable {
        // MARK: Lifecycle

        public init(date: Date, hours: Double, isGoalMet: Bool) {
            self.date = date
            self.hours = hours
            self.isGoalMet = isGoalMet
        }

        // MARK: Public

        public let date: Date
        public let hours: Double
        public let isGoalMet: Bool
    }

    public let currentStreak: Int
    public let averageHours: Double
    public let dailyFasting: [DailyFastingData]
    /// Longest consecutive days meeting fasting goal in the period
    public let longestStreak: Int?
    /// Total number of fasts that met the goal
    public let totalFastsCompleted: Int?
    /// Best single day fasting hours in the period
    public let bestDayHours: Double?
    /// Change in average hours vs last week (positive = improvement)
    public let hoursChangeVsLastWeek: Double?
}

// MARK: - NutritionInsightsDTO

/// Nutrition insights for watch app
public struct NutritionInsightsDTO: Codable {
    // MARK: Lifecycle

    public init(
        avgCalories: Double,
        goalAdherence: Double,
        hydrationPercent: Double,
        todayMacros: MacroBreakdown?,
        daysOnGoal: Int? = nil,
        proteinAvg: Double? = nil,
        weeklyGoalMet: [Bool]? = nil
    ) {
        self.avgCalories = avgCalories
        self.goalAdherence = goalAdherence
        self.hydrationPercent = hydrationPercent
        self.todayMacros = todayMacros
        self.daysOnGoal = daysOnGoal
        self.proteinAvg = proteinAvg
        self.weeklyGoalMet = weeklyGoalMet
    }

    // MARK: Public

    public struct MacroBreakdown: Codable {
        // MARK: Lifecycle

        public init(
            protein: Double,
            carbs: Double,
            fat: Double,
            proteinPercent: Double,
            carbsPercent: Double,
            fatPercent: Double
        ) {
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.proteinPercent = proteinPercent
            self.carbsPercent = carbsPercent
            self.fatPercent = fatPercent
        }

        // MARK: Public

        public let protein: Double
        public let carbs: Double
        public let fat: Double
        public let proteinPercent: Double
        public let carbsPercent: Double
        public let fatPercent: Double
    }

    public let avgCalories: Double
    public let goalAdherence: Double
    public let hydrationPercent: Double
    public let todayMacros: MacroBreakdown?
    /// Number of days this week where calorie goal was met
    public let daysOnGoal: Int?
    /// Average daily protein intake in grams
    public let proteinAvg: Double?
    /// Array of 7 bools (Mon-Sun) indicating which days met the calorie goal
    public let weeklyGoalMet: [Bool]?
}

// MARK: - RecoveryScoreDTO

/// Recovery/readiness score for Watch and iPhone display
public struct RecoveryScoreDTO: Codable, Sendable {
    // MARK: Lifecycle

    public init(
        score: Double,
        sleepHours: Double?,
        sleepQuality: Double?,
        restingHeartRate: Double?,
        status: RecoveryStatus
    ) {
        self.score = score
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.restingHeartRate = restingHeartRate
        self.status = status
    }

    /// Creates a RecoveryScoreDTO from a raw score, automatically determining status
    public init(score: Double, sleepHours: Double?, sleepQuality: Double?, restingHeartRate: Double?) {
        self.score = score
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.restingHeartRate = restingHeartRate
        self.status =
            switch score {
            case 80...100: .excellent
            case 60..<80: .good
            case 40..<60: .moderate
            default: .low
            }
    }

    // MARK: Public

    public enum RecoveryStatus: String, Codable, Sendable {
        case excellent
        case good
        case moderate
        case low

        // MARK: Public

        public var displayName: String {
            self.rawValue.capitalized
        }
    }

    public let score: Double // 0-100
    public let sleepHours: Double?
    public let sleepQuality: Double?
    public let restingHeartRate: Double?
    public let status: RecoveryStatus
}

// MARK: - ActivityPlayerStateDTO

/// Activity player state for Watch sync (sports, freeform activities)
public struct ActivityPlayerStateDTO: Codable, Equatable {
    // MARK: Lifecycle

    public init(
        activityType: String,
        sportType: String?,
        activityName: String,
        isStarted: Bool,
        isPaused: Bool,
        isComplete: Bool,
        startTime: Date?,
        totalElapsedTime: TimeInterval,
        totalPausedTime: TimeInterval = 0,
        currentHeartRate: Double,
        activeCalories: Double,
        distanceCovered: Double? = nil,
        userScore: String? = nil,
        opponentScore: String? = nil,
        opponent: String? = nil,
        isMatchComplete: Bool? = nil,
        winner: String? = nil,
        lapCount: Int? = nil,
        bestLapTime: TimeInterval? = nil,
        currentLapStartTime: Date? = nil,
        setCount: Int? = nil,
        totalReps: Int? = nil
    ) {
        self.activityType = activityType
        self.sportType = sportType
        self.activityName = activityName
        self.isStarted = isStarted
        self.isPaused = isPaused
        self.isComplete = isComplete
        self.startTime = startTime
        self.totalElapsedTime = totalElapsedTime
        self.totalPausedTime = totalPausedTime
        self.currentHeartRate = currentHeartRate
        self.activeCalories = activeCalories
        self.distanceCovered = distanceCovered
        self.userScore = userScore
        self.opponentScore = opponentScore
        self.opponent = opponent
        self.isMatchComplete = isMatchComplete
        self.winner = winner
        self.lapCount = lapCount
        self.bestLapTime = bestLapTime
        self.currentLapStartTime = currentLapStartTime
        self.setCount = setCount
        self.totalReps = totalReps
    }

    // MARK: Public

    public let activityType: String // "sport", "freeform", "workout"
    public let sportType: String?
    public let activityName: String
    public let isStarted: Bool
    public let isPaused: Bool
    public let isComplete: Bool
    public let startTime: Date?
    public let totalElapsedTime: TimeInterval
    public let totalPausedTime: TimeInterval
    public let currentHeartRate: Double
    public let activeCalories: Double
    public let distanceCovered: Double?

    // Sport-specific fields
    public let userScore: String?
    public let opponentScore: String?
    public let opponent: String?
    public let isMatchComplete: Bool?
    public let winner: String?

    // Freeform-specific fields (laps, sets)
    public let lapCount: Int?
    public let bestLapTime: TimeInterval?
    public let currentLapStartTime: Date?
    public let setCount: Int?
    public let totalReps: Int?
}
